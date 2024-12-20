// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// OpenZeppelin Contracts
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// Import Uniswap V2 Pair Interface from official repository
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

interface IC100PublicSale {
    function polRate() external view returns (uint256);
    function updatePOLRate(uint256 newRate) external;
}

/**
 * @title COIN100 (C100)
 * @notice A rebasing token representing the top 100 crypto market cap index.
 * 
 * Changes in this version:
 * - Pass treasury address on deployment and assign ownership to it.
 * - Use imported Uniswap V2 Pair interface.
 * - Dynamically handle multiple liquidity pools (e.g., C100/USDC, C100/WMATIC).
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

    uint256 public ownerAllocation;       
    uint256 public remainingAllocation;   

    // Governance
    address public govContract;

    // Treasury and fees
    address public treasury;
    bool public transfersWithFee;             
    uint256 public transferFeeBasisPoints;    

    // LP Rewards
    mapping(address => bool) public liquidityPools;
    address[] public liquidityPoolList;
    uint256 public lpRewardPercentage;        
    uint256 public maxLpRewardPercentage = 10; 

    // Public Sale Contract
    IC100PublicSale public publicSaleContract;

    // Liquidity Pools for pricing
    address public c100USDCPool;  
    address public c100POLPool;   

    // polInUSDCRate: USDC per POL (scaled by 1e18)
    uint256 public polInUSDCRate;

    // Last calculated polRate from pools (C100 per POL * 1e18)
    uint256 public lastCalculatedPolRate;

    // Rebase frequency placeholder
    uint256 public rebaseFrequency;           

    // Events
    event Rebase(uint256 oldMarketCap, uint256 newMarketCap, uint256 ratio, uint256 timestamp);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event GovernorContractSet(address indexed oldGovernor, address indexed newGovernor);
    event TreasuryAddressUpdated(address indexed oldTreasury, address indexed newTreasury);
    event FeeParametersUpdated(bool transfersWithFee, uint256 transferFeeBasisPoints);
    event LiquidityPoolAdded(address indexed pool);
    event LiquidityPoolRemoved(address indexed pool);
    event LpRewardPercentageUpdated(uint256 newPercentage);
    event MaxLpRewardPercentageUpdated(uint256 newMaxPercentage);
    event PublicSaleContractSet(address indexed oldSaleContract, address indexed newSaleContract);
    event POLRateUpdated(uint256 oldRate, uint256 newRate);
    event C100USDCPoolSet(address oldPool, address newPool);
    event C100POLPoolSet(address oldPool, address newPool);
    event PolInUSDCRateUpdated(uint256 oldRate, uint256 newRate);

    /**
     * @notice Constructor to initialize the contract.
     * @param initialMarketCap Initial market capitalization (human-readable, scaled by 1e18 internally).
     * @param initialPolRate Initial POL rate (human-readable, scaled by 1e18 internally).
     * @param _treasury Address of the treasury which will own the contract.
     */
    constructor(
        uint256 initialMarketCap, 
        uint256 initialPolRate,
        address _treasury
    ) Ownable(_treasury) Pausable() ReentrancyGuard() {
        require(_treasury != address(0), "Treasury address cannot be zero");
        require(initialMarketCap > 0, "Initial mcap must be > 0");
        require(initialPolRate > 0, "Initial polRate must be > 0");

        // Assign treasury
        treasury = _treasury;

        // Scale initialMarketCap by 1e18 to match ERC20 18 decimals standard
        uint256 scaledMcap = initialMarketCap * 1e18;
        _totalSupply = scaledMcap;
        lastMarketCap = scaledMcap;

        ownerAllocation = (_totalSupply * 3) / 100;           
        remainingAllocation = _totalSupply - ownerAllocation; 

        _gonsPerFragment = MAX_GONS / _totalSupply;

        uint256 totalGons = _totalSupply * _gonsPerFragment;
        _gonsBalances[treasury] = totalGons;

        emit Transfer(address(0), treasury, _totalSupply);

        // Default parameters
        rebaseFrequency = 1 days;
        transfersWithFee = true;                
        transferFeeBasisPoints = 100;           
        lpRewardPercentage = 5; 

        // Scale initialPolRate by 1e18
        lastCalculatedPolRate = initialPolRate * 1e18;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner() || (govContract != address(0) && msg.sender == govContract), "Not admin");
        _;
    }

    // ERC20 standard
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
            uint256 gonsAfterFee = gonsAmount - feeGons;

            _gonsBalances[treasury] += feeGons;
            _gonsBalances[to] += gonsAfterFee;

            uint256 feeAmount = feeGons / _gonsPerFragment;
            uint256 recipientAmount = gonsAfterFee / _gonsPerFragment;

            emit Transfer(from, treasury, feeAmount);
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
    function rebase(uint256 newMarketCap) external onlyAdmin nonReentrant whenNotPaused {
        require(newMarketCap > 0, "Mcap > 0");
        uint256 oldMarketCap = lastMarketCap;
        uint256 oldSupply = _totalSupply;

        uint256 oldPolRate = lastCalculatedPolRate;
        uint256 newPolRate = _getPolRateFromPools();
        lastCalculatedPolRate = newPolRate;

        // Sync with Public Sale if set
        if (address(publicSaleContract) != address(0)) {
            publicSaleContract.updatePOLRate(newPolRate);
        }
        emit POLRateUpdated(oldPolRate, newPolRate);

        // Scale newMarketCap by 1e18
        uint256 scaledNewMarketCap = newMarketCap * 1e18;

        uint256 ratioScaled = 1e18; // Default ratio is 1 if oldMarketCap = 0
        if (oldMarketCap > 0) {
            // ratioScaled = (scaledNewMarketCap / oldMarketCap) * 1e18
            ratioScaled = (scaledNewMarketCap * 1e18) / oldMarketCap;
        }

        uint256 newSupply = (oldSupply * ratioScaled) / 1e18;
        if (newSupply == 0) {
            // fallback to no change if calculation yields zero
            newSupply = oldSupply;
        }

        uint256 supplyDelta;
        bool isIncrease;
        if (newSupply > oldSupply) {
            supplyDelta = newSupply - oldSupply;
            isIncrease = true;
        } else {
            supplyDelta = oldSupply - newSupply;
            isIncrease = false;
        }

        _gonsPerFragment = MAX_GONS / newSupply;
        _totalSupply = newSupply;
        lastMarketCap = scaledNewMarketCap;

        emit Rebase(oldMarketCap, scaledNewMarketCap, ratioScaled, block.timestamp);

        if (isIncrease && lpRewardPercentage > 0 && liquidityPoolList.length > 0 && supplyDelta > 0) {
            _allocateRewardsToLPs(supplyDelta);
        }
    }

    function _allocateRewardsToLPs(uint256 supplyDelta) internal {
        uint256 rewardAmount = (supplyDelta * lpRewardPercentage) / 100;
        if (rewardAmount == 0) {
            return;
        }

        uint256 totalLpSupply = 0;
        for (uint256 i = 0; i < liquidityPoolList.length; i++) {
            totalLpSupply += balanceOf(liquidityPoolList[i]);
        }

        if (totalLpSupply == 0) {
            // If no LP supply, skip
            return;
        }

        for (uint256 i = 0; i < liquidityPoolList.length; i++) {
            address pool = liquidityPoolList[i];
            uint256 poolBalance = balanceOf(pool);
            if (poolBalance > 0) {
                uint256 poolReward = (rewardAmount * poolBalance) / totalLpSupply;
                _gonsBalances[pool] += poolReward * _gonsPerFragment;
                emit Transfer(address(this), pool, poolReward);
            }
        }

        _totalSupply += rewardAmount;
    }

    // Price Calculation
    function _getPolRateFromPools() internal view returns (uint256) {
        // Try primary: C100/POL pool
        if (c100POLPool != address(0)) {
            IUniswapV2Pair pair = IUniswapV2Pair(c100POLPool);
            (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
            address t0 = pair.token0();
            uint256 c100Reserve;
            uint256 polReserve;
            if (t0 == address(this)) {
                c100Reserve = uint256(reserve0);
                polReserve = uint256(reserve1);
            } else {
                c100Reserve = uint256(reserve1);
                polReserve = uint256(reserve0);
            }

            if (polReserve > 0) {
                uint256 rate = (c100Reserve * 1e18) / polReserve;
                if (rate > 0) {
                    return rate;
                }
            }
        }

        // Fallback: use C100/USDC pool and polInUSDCRate
        if (c100USDCPool == address(0) || polInUSDCRate == 0) {
            return lastCalculatedPolRate;
        }

        IUniswapV2Pair usdcPair = IUniswapV2Pair(c100USDCPool);
        (uint112 r0, uint112 r1,) = usdcPair.getReserves();
        address token0 = usdcPair.token0();
        uint256 c100R;
        uint256 usdcR;
        if (token0 == address(this)) {
            c100R = uint256(r0);
            usdcR = uint256(r1);
        } else {
            c100R = uint256(r1);
            usdcR = uint256(r0);
        }

        if (c100R == 0) {
            return lastCalculatedPolRate;
        }

        uint256 c100PriceInUSDC = (usdcR * 1e18) / c100R;
        if (c100PriceInUSDC == 0) {
            return lastCalculatedPolRate;
        }

        uint256 fallbackRate = (polInUSDCRate * 1e18) / c100PriceInUSDC;
        if (fallbackRate == 0) {
            return lastCalculatedPolRate;
        }
        return fallbackRate;
    }

    // Admin functions

    /**
     * @notice Set the Governor contract address.
     * @param _govContract Address of the new Governor contract.
     */
    function setGovernorContract(address _govContract) external onlyOwner {
        address oldGov = govContract;
        govContract = _govContract;
        emit GovernorContractSet(oldGov, _govContract);
    }

    /**
     * @notice Set the Public Sale contract address.
     * @param _publicSaleContract Address of the new Public Sale contract.
     */
    function setPublicSaleContract(address _publicSaleContract) external onlyOwner {
        require(_publicSaleContract != address(0), "Public sale zero");
        address oldSale = address(publicSaleContract);
        publicSaleContract = IC100PublicSale(_publicSaleContract);
        emit PublicSaleContractSet(oldSale, _publicSaleContract);
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
     * @notice Set the frequency of rebasing.
     * @param newFrequency New rebase frequency in seconds.
     */
    function setRebaseFrequency(uint256 newFrequency) external onlyAdmin {
        rebaseFrequency = newFrequency;
    }

    /**
     * @notice Set transfer fee parameters.
     * @param enabled Whether transfers with fee are enabled.
     * @param newFeeBasisPoints New fee in basis points (max 10%).
     */
    function setTransferFeeParams(bool enabled, uint256 newFeeBasisPoints) external onlyAdmin {
        require(newFeeBasisPoints <= 1000, "Fee too high"); // Max 10%
        transfersWithFee = enabled;
        transferFeeBasisPoints = newFeeBasisPoints;
        emit FeeParametersUpdated(enabled, newFeeBasisPoints);
    }

    /**
     * @notice Update the treasury address.
     * @param newTreasury Address of the new treasury.
     */
    function updateTreasuryAddress(address newTreasury) external onlyAdmin {
        require(newTreasury != address(0), "Zero");
        address old = treasury;
        treasury = newTreasury;
        emit TreasuryAddressUpdated(old, newTreasury);
    }

    /**
     * @notice Burn tokens from the treasury.
     * @param amount Amount of tokens to burn.
     */
    function burnFromTreasury(uint256 amount) external onlyAdmin nonReentrant {
        require(balanceOf(treasury) >= amount, "Not enough tokens");
        uint256 gonsAmount = amount * _gonsPerFragment;
        _gonsBalances[treasury] -= gonsAmount;
        _totalSupply -= amount;
        if (_totalSupply > 0) {
            _gonsPerFragment = MAX_GONS / _totalSupply;
        }
        emit Transfer(treasury, address(0), amount);
    }

    /**
     * @notice Add a new liquidity pool.
     * @param pool Address of the liquidity pool.
     */
    function addLiquidityPool(address pool) external onlyAdmin {
        require(pool != address(0), "Zero");
        require(!liquidityPools[pool], "Already registered");
        liquidityPools[pool] = true;
        liquidityPoolList.push(pool);
        emit LiquidityPoolAdded(pool);
    }

    /**
     * @notice Remove an existing liquidity pool.
     * @param pool Address of the liquidity pool to remove.
     */
    function removeLiquidityPool(address pool) external onlyAdmin {
        require(liquidityPools[pool], "Not registered");
        liquidityPools[pool] = false;

        for (uint256 i = 0; i < liquidityPoolList.length; i++) {
            if (liquidityPoolList[i] == pool) {
                liquidityPoolList[i] = liquidityPoolList[liquidityPoolList.length - 1];
                liquidityPoolList.pop();
                break;
            }
        }

        emit LiquidityPoolRemoved(pool);
    }

    /**
     * @notice Set the LP reward percentage.
     * @param _lpRewardPercentage New LP reward percentage (max `maxLpRewardPercentage`).
     */
    function setLpRewardPercentage(uint256 _lpRewardPercentage) external onlyAdmin {
        require(_lpRewardPercentage <= maxLpRewardPercentage, "Exceeds max limit");
        lpRewardPercentage = _lpRewardPercentage;
        emit LpRewardPercentageUpdated(_lpRewardPercentage);
    }

    /**
     * @notice Set the maximum LP reward percentage.
     * @param _maxLpRewardPercentage New maximum LP reward percentage (max 50%).
     */
    function setMaxLpRewardPercentage(uint256 _maxLpRewardPercentage) external onlyAdmin {
        require(_maxLpRewardPercentage <= 50, "Too high");
        maxLpRewardPercentage = _maxLpRewardPercentage;
        emit MaxLpRewardPercentageUpdated(_maxLpRewardPercentage);
    }

    /**
     * @notice Set the C100/USDC liquidity pool address.
     * @param pool Address of the new C100/USDC pool.
     */
    function setC100USDCPool(address pool) external onlyAdmin {
        address old = c100USDCPool;
        c100USDCPool = pool;
        emit C100USDCPoolSet(old, pool);
    }

    /**
     * @notice Set the C100/POL liquidity pool address.
     * @param pool Address of the new C100/POL pool.
     */
    function setC100POLPool(address pool) external onlyAdmin {
        address old = c100POLPool;
        c100POLPool = pool;
        emit C100POLPoolSet(old, pool);
    }

    /**
     * @notice Set the POL in USDC rate.
     * @param newRate New POL in USDC rate (scaled by 1e18).
     */
    function setPolInUSDCRate(uint256 newRate) external onlyAdmin {
        require(newRate > 0, "Rate must be >0");
        uint256 old = polInUSDCRate;
        polInUSDCRate = newRate;
        emit PolInUSDCRateUpdated(old, newRate);
    }

    // Fallback and receive functions to prevent accidental ETH transfers
    receive() external payable {
        revert("No ETH");
    }

    fallback() external payable {
        revert("No ETH");
    }
}
