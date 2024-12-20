// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// OpenZeppelin Contracts
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// Import Uniswap V2 Pair Interface from official repository
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title COIN100 (C100)
 * @notice A rebasing token representing the top 100 crypto market cap index.
 * 
 * Features:
 * - 100% initial supply allocated to treasury.
 * - Transaction fees split between treasury and liquidity pool.
 * - Single liquidity pool support (C100/USDC).
 * - Robust rebasing mechanism aligned with market capitalization.
 * - Secure access control and pausable functionalities.
 */
contract COIN100 is Ownable, ReentrancyGuard, Pausable {
    // ---------------------------------------
    // Token metadata
    // ---------------------------------------
    string public constant name = "COIN100";
    string public constant symbol = "C100";
    uint8 public constant decimals = 18;

    // ---------------------------------------
    // Rebase state variables
    // ---------------------------------------
    uint256 private _totalSupply;         
    uint256 public lastMarketCap;         
    uint256 constant MAX_GONS = type(uint256).max / 1e18;
    uint256 private _gonsPerFragment;     

    mapping(address => uint256) private _gonsBalances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Governance
    address public govContract;

    // Treasury and fees
    address public treasury;
    bool public transfersWithFee;             
    uint256 public transferFeeBasisPoints;    
    
    // Fee splitting
    uint256 public treasuryFeeBasisPoints; // Portion of fee to treasury
    uint256 public lpFeeBasisPoints;       // Portion of fee to LPs

    // LP Rewards
    address public liquidityPool; // Only one LP supported (C100/USDC)

    // Public Sale Contract
    address public publicSaleContract;

    // Liquidity Pools for pricing
    address public c100USDCPool;  

    // Rebase frequency placeholder
    uint256 public rebaseFrequency;           

    // Fixed price during presale
    uint256 public constant FIXED_PRICE_USDC = 1e15; // 0.001 USDC per C100 (scaled by 1e18)

    // Presale end time
    uint256 public presaleEndTime;

    // Events
    event Rebase(uint256 oldMarketCap, uint256 newMarketCap, uint256 ratio, uint256 timestamp);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event GovernorContractSet(address indexed oldGovernor, address indexed newGovernor);
    event TreasuryAddressUpdated(address indexed oldTreasury, address indexed newTreasury);
    event FeeParametersUpdated(uint256 treasuryFeeBasisPoints, uint256 lpFeeBasisPoints);
    event LiquidityPoolSet(address indexed oldPool, address indexed newPool);
    event PublicSaleContractSet(address indexed oldSaleContract, address indexed newSaleContract);
    event RebaseFrequencyUpdated(uint256 newFrequency);
    event TokensBurned(uint256 amount);

    /**
     * @notice Constructor to initialize the contract.
     * @param initialMarketCap Initial market capitalization (human-readable, scaled by 1e18 internally).
     * @param _treasury Address of the treasury which will own the contract.
     */
    constructor(
        uint256 initialMarketCap, 
        address _treasury
    ) Ownable(_treasury) Pausable() ReentrancyGuard() {
        require(_treasury != address(0), "Treasury address cannot be zero");
        require(initialMarketCap > 0, "Initial market cap must be > 0");

        // Assign treasury
        treasury = _treasury;

        // Transfer ownership to treasury
        transferOwnership(treasury);

        // Scale initialMarketCap by 1e18 to match ERC20 18 decimals standard
        uint256 scaledMcap = initialMarketCap * 1e18;
        _totalSupply = scaledMcap;
        lastMarketCap = scaledMcap;

        _gonsPerFragment = MAX_GONS / _totalSupply;

        uint256 totalGons = _totalSupply * _gonsPerFragment;
        _gonsBalances[treasury] = totalGons;

        emit Transfer(address(0), treasury, _totalSupply);

        // Default parameters
        rebaseFrequency = 1 days;
        transfersWithFee = true;                
        transferFeeBasisPoints = 200; // Total fee: 2%
        treasuryFeeBasisPoints = 100;   // 1% to treasury
        lpFeeBasisPoints = 100;         // 1% to LPs
    }

    modifier onlyAdmin() {
        require(msg.sender == owner() || (govContract != address(0) && msg.sender == govContract), "Not admin");
        _;
    }

    // ERC20 standard functions

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _gonsBalances[account] / _gonsPerFragment;
    }

    function allowance(address owner_, address spender) public view returns (uint256) {
        return _allowances[owner_][spender];
    }

    function transfer(address to, uint256 amount) public whenNotPaused returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public whenNotPaused returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public whenNotPaused returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= amount, "Exceeds allowance");
        _transfer(from, to, amount);
        _approve(from, msg.sender, currentAllowance - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external whenNotPaused returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external whenNotPaused returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "Below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    // Internal transfer and approve
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "From zero");
        require(to != address(0), "To zero");
        require(balanceOf(from) >= amount, "Balance too low");

        uint256 gonsAmount = amount * _gonsPerFragment;

        _gonsBalances[from] -= gonsAmount;

        if (transfersWithFee && transferFeeBasisPoints > 0) {
            uint256 feeGons = (gonsAmount * transferFeeBasisPoints) / 10000;
            uint256 treasuryFeeGons = (feeGons * treasuryFeeBasisPoints) / transferFeeBasisPoints;
            uint256 lpFeeGons = feeGons - treasuryFeeGons;

            uint256 gonsAfterFee = gonsAmount - feeGons;

            // Allocate treasury fee
            _gonsBalances[treasury] += treasuryFeeGons;
            emit Transfer(from, treasury, treasuryFeeGons / _gonsPerFragment);

            // Allocate LP fee
            if (lpFeeGons > 0 && liquidityPool != address(0)) {
                _gonsBalances[liquidityPool] += lpFeeGons;
                emit Transfer(from, liquidityPool, lpFeeGons / _gonsPerFragment);
            } else {
                // If no LP, send all to treasury
                _gonsBalances[treasury] += lpFeeGons;
                emit Transfer(from, treasury, lpFeeGons / _gonsPerFragment);
            }

            // Transfer remaining tokens to recipient
            _gonsBalances[to] += gonsAfterFee;

            uint256 recipientAmount = gonsAfterFee / _gonsPerFragment;
            emit Transfer(from, to, recipientAmount);
        } else {
            _gonsBalances[to] += gonsAmount;
            emit Transfer(from, to, amount);
        }
    }

    function _approve(address owner_, address spender, uint256 amount) internal {
        require(owner_ != address(0), "Owner zero");
        require(spender != address(0), "Spender zero");
        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    // Rebase logic
    /**
     * @notice Rebase the token supply based on the new market cap.
     * @param newMarketCap The updated market capitalization in USDC (human-readable).
     */
    function rebase(uint256 newMarketCap) external onlyAdmin nonReentrant whenNotPaused {
        require(newMarketCap > 0, "Market cap must be > 0");
        uint256 oldMarketCap = lastMarketCap;
        uint256 oldSupply = _totalSupply;

        // Scale newMarketCap by 1e18
        uint256 scaledNewMarketCap = newMarketCap * 1e18;

        // Get current price
        uint256 currentPrice = _getCurrentPrice();
        require(currentPrice > 0, "Invalid price");

        // Calculate new supply based on newMarketCap and current price
        uint256 newSupply = (scaledNewMarketCap * 1e18) / currentPrice;
        require(newSupply > 0, "New supply must be > 0");

        uint256 ratioScaled = (newSupply * 1e18) / oldSupply;

        // Update gons per fragment
        _gonsPerFragment = MAX_GONS / newSupply;

        // Update total supply and market cap
        _totalSupply = newSupply;
        lastMarketCap = scaledNewMarketCap;

        emit Rebase(oldMarketCap, scaledNewMarketCap, ratioScaled, block.timestamp);
    }

    /**
     * @notice Retrieves the current price of C100 from the liquidity pool or uses fixed price during presale.
     * @return price The price of 1 C100 in USDC, scaled by 1e18.
     */
    function _getCurrentPrice() internal view returns (uint256 price) {
        if (block.timestamp <= presaleEndTime) {
            // Presale period: use fixed price
            price = FIXED_PRICE_USDC;
        } else if (liquidityPool != address(0)) {
            // Post-presale: use liquidity pool price
            IUniswapV2Pair pair = IUniswapV2Pair(liquidityPool);
            (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
            address token0 = pair.token0();
            uint256 c100Reserve;
            uint256 usdcReserve;
            if (token0 == address(this)) {
                c100Reserve = uint256(reserve0);
                usdcReserve = uint256(reserve1);
            } else {
                c100Reserve = uint256(reserve1);
                usdcReserve = uint256(reserve0);
            }
            if (c100Reserve == 0) {
                return 0;
            }
            // Price = USDC / C100
            price = (usdcReserve * 1e18) / c100Reserve;
        } else {
            // No LP and post-presale: price undefined
            price = 0;
        }
    }

    // Admin functions

    /**
     * @notice Set the Governor contract address.
     * @param _govContract Address of the new Governor contract.
     */
    function setGovernorContract(address _govContract) external onlyOwner {
        require(_govContract != address(0), "Governor zero address");
        address oldGov = govContract;
        govContract = _govContract;
        emit GovernorContractSet(oldGov, _govContract);
    }

    /**
     * @notice Set the Public Sale contract address and set presale end time based on public sale's end time.
     * @param _publicSaleContract Address of the new Public Sale contract.
     * @param _presaleEndTime UNIX timestamp marking the end of the presale period.
     */
    function setPublicSaleContract(address _publicSaleContract, uint256 _presaleEndTime) external onlyOwner {
        require(_publicSaleContract != address(0), "Public sale zero address");
        require(_presaleEndTime > block.timestamp, "Presale end time must be in the future");
        address oldSale = publicSaleContract;
        publicSaleContract = _publicSaleContract;
        presaleEndTime = _presaleEndTime;
        emit PublicSaleContractSet(oldSale, _publicSaleContract);
        emit RebaseFrequencyUpdated(_presaleEndTime);
    }

    /**
     * @notice Set the liquidity pool address (C100/USDC).
     * @param _liquidityPool Address of the liquidity pool.
     */
    function setLiquidityPool(address _liquidityPool) external onlyAdmin {
        require(_liquidityPool != address(0), "Liquidity pool zero address");
        address oldPool = liquidityPool;
        liquidityPool = _liquidityPool;
        emit LiquidityPoolSet(oldPool, _liquidityPool);
    }

    /**
     * @notice Set the rebase frequency.
     * @param newFrequency New rebase frequency in seconds.
     */
    function setRebaseFrequency(uint256 newFrequency) external onlyAdmin {
        rebaseFrequency = newFrequency;
        emit RebaseFrequencyUpdated(newFrequency);
    }

    /**
     * @notice Set fee parameters.
     * @param newTreasuryFeeBasisPoints New fee in basis points to treasury.
     * @param newLpFeeBasisPoints New fee in basis points to LPs.
     */
    function setFeeParameters(uint256 newTreasuryFeeBasisPoints, uint256 newLpFeeBasisPoints) external onlyAdmin {
        require(newTreasuryFeeBasisPoints + newLpFeeBasisPoints <= transferFeeBasisPoints, "Total fee exceeded");
        treasuryFeeBasisPoints = newTreasuryFeeBasisPoints;
        lpFeeBasisPoints = newLpFeeBasisPoints;
        emit FeeParametersUpdated(newTreasuryFeeBasisPoints, newLpFeeBasisPoints);
    }

    /**
     * @notice Update the treasury address.
     * @param newTreasury Address of the new treasury.
     */
    function updateTreasuryAddress(address newTreasury) external onlyAdmin {
        require(newTreasury != address(0), "Zero address");
        address old = treasury;
        treasury = newTreasury;
        emit TreasuryAddressUpdated(old, newTreasury);
    }

    /**
     * @notice Burn tokens from the treasury.
     * @param amount Amount of tokens to burn.
     */
    function burnFromTreasury(uint256 amount) external onlyAdmin nonReentrant {
        require(balanceOf(treasury) >= amount, "Not enough tokens in treasury");
        uint256 gonsAmount = amount * _gonsPerFragment;
        _gonsBalances[treasury] -= gonsAmount;
        _totalSupply -= amount;
        if (_totalSupply > 0) {
            _gonsPerFragment = MAX_GONS / _totalSupply;
        }
        emit Transfer(treasury, address(0), amount);
        emit TokensBurned(amount);
    }

    /**
     * @notice Pause the contract.
     */
    function pauseContract() external onlyAdmin {
        _pause();
    }

    /**
     * @notice Unpause the contract.
     */
    function unpauseContract() external onlyAdmin {
        _unpause();
    }

    /**
     * @notice Rescue tokens accidentally sent to the contract.
     * @param token Address of the token to rescue.
     * @param amount Amount of tokens to rescue.
     */
    function rescueTokens(address token, uint256 amount) external onlyAdmin {
        require(token != address(this), "Cannot rescue C100 tokens");
        require(token != treasury, "Cannot rescue treasury tokens");
        require(token != liquidityPool, "Cannot rescue liquidity pool tokens");
        require(token != address(0), "Zero address");
        IERC20(token).transfer(treasury, amount);
        emit TokensBurned(amount); // Reusing event for simplicity
    }
}
