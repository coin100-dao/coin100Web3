// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// OpenZeppelin Contracts
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title COIN100 (C100)
 * @notice A rebasing token representing the top 100 crypto market cap index.
 *         The token adjusts its supply based on the market capitalization to maintain its peg.
 */
contract COIN100 is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

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
    uint256 public lastMarketCap; // Stored as scaled by 1e18 for precision

    uint256 public constant MAX_GONS = type(uint256).max / 1e18; // Maximum gons to prevent overflow
    uint256 private _gonsPerFragment; // Determines the relationship between gons and tokens

    mapping(address => uint256) private _gonsBalances; // Maps addresses to their gon balances
    mapping(address => mapping(address => uint256)) private _allowances; // ERC20 allowances

    // Governance
    address public govContract; // Address of the governance contract

    // Treasury and fees
    address public treasury; // Address that collects fees
    bool public transfersWithFee; // Flag to enable/disable transfer fees
    uint256 public transferFeeBasisPoints; // Total transfer fee in basis points (e.g., 200 = 2%)

    // Fee splitting
    uint256 public treasuryFeeBasisPoints; // Portion of fee going to treasury
    uint256 public lpFeeBasisPoints; // Portion of fee going to liquidity pools

    // Multiple liquidity pools
    EnumerableSet.AddressSet private liquidityPools; // Set of approved liquidity pool addresses

    // Rebase frequency
    uint256 public rebaseFrequency; // Minimum time between rebases (in seconds)
    uint256 public lastRebaseTimestamp; // Timestamp of the last rebase

    // Events
    event Rebase(
        uint256 oldMarketCap, 
        uint256 newMarketCap, 
        uint256 ratioNum, 
        uint256 ratioDen, 
        uint256 timestamp
    );
    event RebaseInSteps(
        uint256 steps, 
        uint256 finalMarketCap, 
        uint256 finalSupply, 
        uint256 timestamp
    );

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event GovernorContractSet(address indexed oldGovernor, address indexed newGovernor);
    event TreasuryAddressUpdated(address indexed oldTreasury, address indexed newTreasury);
    event FeeParametersUpdated(uint256 treasuryFeeBasisPoints, uint256 lpFeeBasisPoints);
    event LiquidityPoolAdded(address indexed pool);
    event LiquidityPoolRemoved(address indexed pool);
    event PublicSaleContractSet(address indexed oldSaleContract, address indexed newSaleContract);
    event RebaseFrequencyUpdated(uint256 newFrequency);
    event TokensBurned(uint256 amount);
    event TokensRescued(address indexed token, uint256 amount);
    event ContractInitialized(uint256 initialMarketCap, address treasury);

    /**
     * @notice Constructor to initialize the contract.
     * @param initialMarketCap Initial market capitalization (human-readable, not scaled by 1e18).
     * @param _treasury Address of the treasury which will own the contract.
     */
    constructor(
        uint256 initialMarketCap,
        address _treasury
    )
        Ownable(msg.sender)  // The "Ownable" constructor is called with deployer as initial owner
        ReentrancyGuard()
        Pausable()
    {
        require(_treasury != address(0), "Treasury address cannot be zero");
        require(initialMarketCap > 0, "Initial market cap must be > 0");

        // Transfer ownership to the treasury immediately
        transferOwnership(_treasury);

        treasury = _treasury;

        // Scale and set up initial supply
        // Example: If initialMarketCap = 1000, scaledMcap = 1000 * 1e18 = 1e21
        uint256 scaledMcap = initialMarketCap * 1e18;
        _totalSupply = scaledMcap;
        lastMarketCap = scaledMcap;

        // Initialize gons per fragment
        _gonsPerFragment = MAX_GONS / _totalSupply;

        // Allocate all tokens to the treasury
        // totalGons = _totalSupply * _gonsPerFragment = (1e21 * (MAX_GONS / 1e21)) = MAX_GONS
        uint256 totalGons = _totalSupply * _gonsPerFragment;
        _gonsBalances[treasury] = totalGons;

        emit Transfer(address(0), treasury, _totalSupply);
        emit ContractInitialized(initialMarketCap, treasury);

        // Default parameters
        rebaseFrequency = 1 days;
        lastRebaseTimestamp = block.timestamp;
        transfersWithFee = true;
        transferFeeBasisPoints = 200; // 2%
        treasuryFeeBasisPoints = 100; // 1% to treasury
        lpFeeBasisPoints = 100;       // 1% to LPs
    }

    /**
     * @dev Modifier to restrict functions to admin roles (owner or governor).
     */
    modifier onlyAdmin() {
        require(
            msg.sender == owner() || 
            (govContract != address(0) && msg.sender == govContract),
            "Not admin"
        );
        _;
    }

    //--------------------------------------------------------------------------
    // ERC20 standard functions
    //--------------------------------------------------------------------------

    /**
     * @notice Returns the total supply of the token.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Returns the token balance of a given account.
     * @param account The address to query.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _gonsBalances[account] / _gonsPerFragment;
    }

    /**
     * @notice Returns the allowance from owner to spender.
     * @param owner_ The token owner.
     * @param spender The spender.
     */
    function allowance(address owner_, address spender) public view returns (uint256) {
        return _allowances[owner_][spender];
    }

    /**
     * @notice Transfers tokens from the caller to a recipient.
     * @param to Recipient address.
     * @param value Amount of tokens to transfer.
     */
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @notice Approves a spender to spend a certain amount of tokens.
     * @param spender Spender address.
     * @param value Amount to approve.
     */
    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @notice Transfers tokens from one address to another using allowance mechanism.
     * @param from Sender address.
     * @param to Recipient address.
     * @param value Amount of tokens to transfer.
     */
    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= value, "Exceeds allowance");
        _transfer(from, to, value);
        _approve(from, msg.sender, currentAllowance - value);
        return true;
    }

    /**
     * @notice Increases the allowance granted to a spender.
     * @param spender Spender address.
     * @param addedValue Amount to increase.
     */
    function increaseAllowance(address spender, uint256 addedValue) external whenNotPaused returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    /**
     * @notice Decreases the allowance granted to a spender.
     * @param spender Spender address.
     * @param subtractedValue Amount to decrease.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external whenNotPaused returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "Below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    //--------------------------------------------------------------------------
    // Internal transfer and approve
    //--------------------------------------------------------------------------

    /**
     * @notice Internal function to handle token transfers with fee logic.
     * @param from Sender address.
     * @param to Recipient address.
     * @param value Amount of tokens to transfer.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(from != address(0), "From zero");
        require(to != address(0), "To zero");
        require(balanceOf(from) >= value, "Balance too low");

        // Calculate the gon amount to transfer
        uint256 gonsAmount = value * _gonsPerFragment;
        _gonsBalances[from] -= gonsAmount;

        if (transfersWithFee && transferFeeBasisPoints > 0) {
            // Calculate total fee in gons
            uint256 feeGons = (gonsAmount * transferFeeBasisPoints) / 10000;

            // Split the fee into treasury and liquidity pool portions
            uint256 treasuryFeeGons = (feeGons * treasuryFeeBasisPoints) / transferFeeBasisPoints;
            uint256 lpFeeGons = feeGons - treasuryFeeGons;

            // Remaining gons after fee deduction
            uint256 gonsAfterFee = gonsAmount - feeGons;

            // Allocate treasury fee
            _gonsBalances[treasury] += treasuryFeeGons;
            emit Transfer(from, treasury, treasuryFeeGons / _gonsPerFragment);

            // Allocate liquidity pool fee
            uint256 numberOfPools = liquidityPools.length();
            if (lpFeeGons > 0 && numberOfPools > 0) {
                // Split the LP fee evenly among all approved liquidity pools
                uint256 feePerPool = lpFeeGons / numberOfPools;
                for (uint256 i = 0; i < numberOfPools; i++) {
                    address pool = liquidityPools.at(i);
                    _gonsBalances[pool] += feePerPool;
                    emit Transfer(from, pool, feePerPool / _gonsPerFragment);
                }

                // Handle any leftover gons due to integer division
                uint256 leftover = lpFeeGons - (feePerPool * numberOfPools);
                if (leftover > 0) {
                    _gonsBalances[treasury] += leftover;
                    emit Transfer(from, treasury, leftover / _gonsPerFragment);
                }
            } else {
                // If no liquidity pools are set, send all LP fees to the treasury
                _gonsBalances[treasury] += lpFeeGons;
                emit Transfer(from, treasury, lpFeeGons / _gonsPerFragment);
            }

            // Transfer the remaining gons to the recipient
            _gonsBalances[to] += gonsAfterFee;
            emit Transfer(from, to, gonsAfterFee / _gonsPerFragment);
        } else {
            // No fee scenario: transfer full amount
            _gonsBalances[to] += gonsAmount;
            emit Transfer(from, to, value);
        }
    }

    /**
     * @notice Internal function to handle approvals.
     * @param owner_ Owner address.
     * @param spender Spender address.
     * @param value Amount to approve.
     */
    function _approve(address owner_, address spender, uint256 value) internal {
        require(owner_ != address(0), "Owner zero");
        require(spender != address(0), "Spender zero");
        _allowances[owner_][spender] = value;
        emit Approval(owner_, spender, value);
    }

    //--------------------------------------------------------------------------
    // Rebase logic: Hybrid approach
    //--------------------------------------------------------------------------

    /**
     * @notice Rebase the token supply based on the new market cap (in "human-readable" units).
     *         This function uses a pure fractional approach to adjust the supply.
     * @param newMarketCap The updated market cap (not scaled by 1e18).
     *                     For example, if the new market cap is 3,381,284,211,318 USD, pass 3381284211318.
     */
    function rebase(uint256 newMarketCap) external onlyAdmin nonReentrant whenNotPaused {
        require(newMarketCap > 0, "Market cap must be > 0");
        require(block.timestamp >= lastRebaseTimestamp + rebaseFrequency, "Rebase frequency not met");

        // Scale the new market cap by 1e18 to match the stored scaled market cap
        uint256 newMarketCapScaled = newMarketCap * 1e18;
        uint256 oldMarketCapScaled = lastMarketCap;

        // Calculate the ratio with high precision
        // ratio = newMarketCapScaled / oldMarketCapScaled
        // To maintain precision, multiply by 1e18 before division
        uint256 ratio = (newMarketCapScaled * 1e18) / oldMarketCapScaled;

        // Calculate the new supply based on the ratio
        // newSupply = (oldSupply * ratio) / 1e18
        uint256 newSupply = (_totalSupply * ratio) / 1e18;

        require(newSupply > 0, "New supply must be > 0");

        // Update total supply
        _totalSupply = newSupply;

        // Update gons per fragment to maintain the relationship between gons and tokens
        _gonsPerFragment = MAX_GONS / _totalSupply;

        // Update the last market cap and timestamp
        lastMarketCap = newMarketCapScaled;
        lastRebaseTimestamp = block.timestamp;

        emit Rebase(
            oldMarketCapScaled,  // Previous market cap
            newMarketCapScaled,  // New market cap
            ratio,               // Ratio numerator (scaled by 1e18)
            1e18,                // Ratio denominator (fixed at 1e18 for precision)
            block.timestamp      // Timestamp of the rebase
        );
    }


    //---------------------------------------------------------------------------
    // Admin functions
    //---------------------------------------------------------------------------

    /**
     * @notice Sets the governor contract address.
     * @param _govContract New governor contract address.
     */
    function setGovernorContract(address _govContract) external onlyOwner {
        require(_govContract != address(0), "Governor zero address");
        address oldGov = govContract;
        govContract = _govContract;
        emit GovernorContractSet(oldGov, _govContract);
    }

    /**
     * @notice (No longer used for rebase logic, but kept for reference in case of public sale)
     * @param _publicSaleContract New public sale contract address.
     */
    function setPublicSaleContract(address _publicSaleContract) external onlyOwner {
        require(_publicSaleContract != address(0), "Public sale zero address");
        address oldSale = address(0);
        emit PublicSaleContractSet(oldSale, _publicSaleContract);
    }

    /**
     * @notice Adds a liquidity pool address to the approved list.
     * @param _pool Address of the liquidity pool (e.g., C100/USDC pair).
     */
    function addLiquidityPool(address _pool) external onlyAdmin {
        require(_pool != address(0), "Pool zero address");
        require(!liquidityPools.contains(_pool), "Pool already added");
        liquidityPools.add(_pool);
        emit LiquidityPoolAdded(_pool);
    }

    /**
     * @notice Removes a liquidity pool address from the approved list.
     * @param _pool Address of the liquidity pool to remove.
     */
    function removeLiquidityPool(address _pool) external onlyAdmin {
        require(liquidityPools.contains(_pool), "Pool not found");
        liquidityPools.remove(_pool);
        emit LiquidityPoolRemoved(_pool);
    }

    /**
     * @notice Returns the count of approved liquidity pools.
     */
    function getLiquidityPoolsCount() external view returns (uint256) {
        return liquidityPools.length();
    }

    /**
     * @notice Returns the liquidity pool address at a specific index.
     * @param index Index in the liquidityPools set.
     */
    function getLiquidityPoolAt(uint256 index) external view returns (address) {
        require(index < liquidityPools.length(), "Index out of bounds");
        return liquidityPools.at(index);
    }

    /**
     * @notice Sets the rebase frequency.
     * @param newFrequency New rebase frequency in seconds.
     */
    function setRebaseFrequency(uint256 newFrequency) external onlyAdmin {
        require(newFrequency > 0, "Frequency must be > 0");
        rebaseFrequency = newFrequency;
        emit RebaseFrequencyUpdated(newFrequency);
    }

    /**
     * @notice Sets the fee parameters for transfers.
     * @param newTreasuryFeeBasisPoints New treasury fee in basis points.
     * @param newLpFeeBasisPoints New liquidity pool fee in basis points.
     */
    function setFeeParameters(uint256 newTreasuryFeeBasisPoints, uint256 newLpFeeBasisPoints) external onlyAdmin {
        require(newTreasuryFeeBasisPoints + newLpFeeBasisPoints <= transferFeeBasisPoints, "Total fee exceeded");
        treasuryFeeBasisPoints = newTreasuryFeeBasisPoints;
        lpFeeBasisPoints = newLpFeeBasisPoints;
        emit FeeParametersUpdated(newTreasuryFeeBasisPoints, newLpFeeBasisPoints);
    }

    /**
     * @notice Updates the treasury address.
     * @param newTreasury New treasury address.
     */
    function updateTreasuryAddress(address newTreasury) external onlyAdmin {
        require(newTreasury != address(0), "Zero address");
        address old = treasury;
        treasury = newTreasury;
        emit TreasuryAddressUpdated(old, newTreasury);
    }

    /**
     * @notice Burns a specified amount of tokens from the treasury.
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
     * @notice Pauses the contract, disabling transfers and rebase.
     */
    function pauseContract() external onlyAdmin {
        _pause();
    }

    /**
     * @notice Unpauses the contract, enabling transfers and rebase.
     */
    function unpauseContract() external onlyAdmin {
        _unpause();
    }

    /**
     * @notice Rescues tokens accidentally sent to the contract, excluding C100 and treasury tokens.
     * @param token Address of the token to rescue.
     * @param amount Amount of tokens to rescue.
     */
    function rescueTokens(address token, uint256 amount) external onlyAdmin {
        require(token != address(this), "Cannot rescue C100 tokens");
        require(token != treasury, "Cannot rescue treasury tokens");

        // Disallow rescuing any approved liquidity pool tokens
        uint256 poolsCount = liquidityPools.length();
        for (uint256 i = 0; i < poolsCount; i++) {
            require(token != liquidityPools.at(i), "Cannot rescue approved pool tokens");
        }
        require(token != address(0), "Zero address");

        IERC20(token).safeTransfer(treasury, amount);
        emit TokensRescued(token, amount);
    }
}
