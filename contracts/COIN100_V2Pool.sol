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
    uint256 public lastMarketCap;         
    uint256 public constant MAX_GONS = type(uint256).max / 1e18;
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
    uint256 public treasuryFeeBasisPoints; 
    uint256 public lpFeeBasisPoints;       

    // Multiple liquidity pools
    EnumerableSet.AddressSet private liquidityPools;

    // Rebase frequency
    uint256 public rebaseFrequency;
    uint256 public lastRebaseTimestamp;

    // Events
    event Rebase(uint256 oldMarketCap, uint256 newMarketCap, uint256 ratioNum, uint256 ratioDen, uint256 timestamp);
    event RebaseInSteps(uint256 steps, uint256 finalMarketCap, uint256 finalSupply, uint256 timestamp);

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
        uint256 scaledMcap = initialMarketCap * 1e18;
        _totalSupply = scaledMcap;
        lastMarketCap = scaledMcap;

        _gonsPerFragment = MAX_GONS / _totalSupply;
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
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _gonsBalances[account] / _gonsPerFragment;
    }

    function allowance(address owner_, address spender) public view returns (uint256) {
        return _allowances[owner_][spender];
    }

    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= value, "Exceeds allowance");
        _transfer(from, to, value);
        _approve(from, msg.sender, currentAllowance - value);
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

    //--------------------------------------------------------------------------
    // Internal transfer and approve
    //--------------------------------------------------------------------------
    function _transfer(address from, address to, uint256 value) internal {
        require(from != address(0), "From zero");
        require(to != address(0), "To zero");
        require(balanceOf(from) >= value, "Balance too low");

        uint256 gonsAmount = value * _gonsPerFragment;
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
            uint256 numberOfPools = liquidityPools.length();
            if (lpFeeGons > 0 && numberOfPools > 0) {
                // Split evenly among LPs
                uint256 feePerPool = lpFeeGons / numberOfPools;
                for (uint256 i = 0; i < numberOfPools; i++) {
                    address pool = liquidityPools.at(i);
                    _gonsBalances[pool] += feePerPool;
                    emit Transfer(from, pool, feePerPool / _gonsPerFragment);
                }
                // Any leftover fraction goes to treasury
                uint256 leftover = lpFeeGons - (feePerPool * numberOfPools);
                if (leftover > 0) {
                    _gonsBalances[treasury] += leftover;
                    emit Transfer(from, treasury, leftover / _gonsPerFragment);
                }
            } else {
                // If no pools, everything goes to treasury
                _gonsBalances[treasury] += lpFeeGons;
                emit Transfer(from, treasury, lpFeeGons / _gonsPerFragment);
            }

            // Send remainder to recipient
            _gonsBalances[to] += gonsAfterFee;
            emit Transfer(from, to, gonsAfterFee / _gonsPerFragment);
        } else {
            // No fee scenario
            _gonsBalances[to] += gonsAmount;
            emit Transfer(from, to, value);
        }
    }

    function _approve(address owner_, address spender, uint256 value) internal {
        require(owner_ != address(0), "Owner zero");
        require(spender != address(0), "Spender zero");
        _allowances[owner_][spender] = value;
        emit Approval(owner_, spender, value);
    }

    //--------------------------------------------------------------------------
    // Rebase logic #1: Fraction-based approach to avoid tiny rounding
    //--------------------------------------------------------------------------
    /**
     * @notice Rebase using fraction math. Instead of multiple multiplications by 1e18,
     *         we treat the ratio as (newMarketCapScaled / oldMarketCapScaled).
     * @param newMarketCap The updated market cap (unscaled, i.e., in "human-readable" units).
     *                     E.g., if you want to set the new market cap to 1,000, pass 1000 (not 1000e18).
     */
    function rebaseFractional(uint256 newMarketCap) external onlyAdmin nonReentrant whenNotPaused {
        require(newMarketCap > 0, "Market cap must be > 0");
        require(block.timestamp >= lastRebaseTimestamp + rebaseFrequency, "Rebase frequency not met");

        // oldMarketCap is stored as a scaled (multiplied by 1e18) value
        uint256 oldMarketCapScaled = lastMarketCap; 
        uint256 oldSupply = _totalSupply;

        // scale newMarketCap once by 1e18 to match stored oldMarketCap
        uint256 newMarketCapScaled = newMarketCap * 1e18; 

        // fraction = new / old
        // we'll keep it as ratioNum / ratioDen
        uint256 ratioNum = newMarketCapScaled;
        uint256 ratioDen = oldMarketCapScaled;

        // newSupply = (oldSupply * ratioNum) / ratioDen
        uint256 newSupply = (oldSupply * ratioNum) / ratioDen;
        require(newSupply > 0, "New supply must be > 0");

        // update _totalSupply, _gonsPerFragment
        _totalSupply = newSupply;
        _gonsPerFragment = MAX_GONS / _totalSupply;

        // update lastMarketCap to the new scaled value
        lastMarketCap = newMarketCapScaled;
        lastRebaseTimestamp = block.timestamp;

        emit Rebase(oldMarketCapScaled, newMarketCapScaled, ratioNum, ratioDen, block.timestamp);
    }

    //--------------------------------------------------------------------------
    // Rebase logic #2: Stepwise approach for large negative changes
    //--------------------------------------------------------------------------
    /**
     * @notice For very large negative rebases, we can do multiple smaller steps
     *         to avoid rounding to zero. The final ratio = newMarketCap / oldMarketCap
     *         is split across `steps` iterations.
     * @param newMarketCap The target new market cap (human-readable, not scaled).
     * @param steps How many smaller rebases to do in one transaction.
     */
    function rebaseInSteps(uint256 newMarketCap, uint256 steps) external onlyAdmin nonReentrant whenNotPaused {
        require(newMarketCap > 0, "Market cap must be > 0");
        require(steps > 0, "Steps must be > 0");
        require(block.timestamp >= lastRebaseTimestamp + rebaseFrequency, "Rebase frequency not met");

        // For example, if old = 3e30, new = 2.5e30, ratio ~ 0.833333...
        // Doing that in a single step could be fine, but if new is super small,
        // we risk an integer underflow to zero. Let's break it up.

        uint256 oldMarketCapScaled = lastMarketCap;
        uint256 oldSupply = _totalSupply;

        // scale newMarketCap by 1e18
        uint256 newMarketCapScaled = newMarketCap * 1e18;

        // Calculate overall ratio = new / old
        // We'll split this ratio across multiple steps
        // ratioNum / ratioDen = (newMarketCapScaled / oldMarketCapScaled)
        // So ratioNum = newMarketCapScaled, ratioDen = oldMarketCapScaled
        // We'll effectively do "fractional" rebases multiple times:
        // e.g., each step does the 'step ratio' = ( ratioNum / ratioDen )^(1/steps )

        // For integer math simplicity, we can't do real exponent roots easily. 
        // A simpler approach: do repeated fraction-based rebases in a loop,
        // each time updating "oldMarketCapScaled" toward "newMarketCapScaled."
        // This is approximate because each iteration modifies the new intermediate state.

        // If new cap < old cap, we do a negative rebase. If bigger, it's a positive one.
        // We'll approach the final supply in `steps` increments.

        // Step ratio:
        // Instead of computing an nth root in pure integer math (which is tricky),
        // we linearly interpolate the intermediate market cap over steps. 
        // This is simpler but not a perfect exponential ratio. It's a piecewise approximation.

        // Example:
        // We'll do multiple partial "fractional" rebases going from old -> new.

        // For each step, we compute an intermediate target market cap:
        // stepMcap = oldMcap + ( (newMcap - oldMcap) * i / steps )
        // Then rebase fractionally to that stepMcap.
        // This won't match a perfect geometric progression, but it's a safe approach 
        // that won't cause newSupply to drop to zero suddenly.

        uint256 diff = 0;
        bool isNegative = false;
        if (newMarketCapScaled < oldMarketCapScaled) {
            diff = oldMarketCapScaled - newMarketCapScaled; 
            isNegative = true;
        } else {
            diff = newMarketCapScaled - oldMarketCapScaled;
        }

        for (uint256 i = 1; i <= steps; i++) {
            // partial target: old + ((new - old) * i / steps)
            uint256 partialTarget = isNegative
                ? (oldMarketCapScaled - (diff * i / steps))
                : (oldMarketCapScaled + (diff * i / steps));

            // now do a fractional rebase from oldMarketCapScaled -> partialTarget
            uint256 ratioNum = partialTarget;       // numerator
            uint256 ratioDen = lastMarketCap;       // denominator (the "old" MC from previous step)
            uint256 intermediateSupply = (_totalSupply * ratioNum) / ratioDen;

            // edge case: if the fraction is super small, this might become 0 
            // (should be extremely unlikely unless partialTarget is extremely small).
            require(intermediateSupply > 0, "Partial rebase would yield 0 supply");
            
            // apply
            _totalSupply = intermediateSupply;
            _gonsPerFragment = MAX_GONS / _totalSupply;
            lastMarketCap = partialTarget; 
        }

        lastRebaseTimestamp = block.timestamp;

        emit RebaseInSteps(steps, lastMarketCap, _totalSupply, block.timestamp);
    }

    //--------------------------------------------------------------------------
    // Admin functions
    //--------------------------------------------------------------------------
    function setGovernorContract(address _govContract) external onlyOwner {
        require(_govContract != address(0), "Governor zero address");
        address oldGov = govContract;
        govContract = _govContract;
        emit GovernorContractSet(oldGov, _govContract);
    }

    /**
     * @notice (No longer used for rebase logic, but kept for reference in case of public sale)
     */
    function setPublicSaleContract(address _publicSaleContract) external onlyOwner {
        require(_publicSaleContract != address(0), "Public sale zero address");
        address oldSale = address(0);
        emit PublicSaleContractSet(oldSale, _publicSaleContract);
    }

    /**
     * @notice Add a liquidity pool address to the approved list.
     * @param _pool Address of the liquidity pool (C100/USDC pair).
     */
    function addLiquidityPool(address _pool) external onlyAdmin {
        require(_pool != address(0), "Pool zero address");
        require(!liquidityPools.contains(_pool), "Pool already added");
        liquidityPools.add(_pool);
        emit LiquidityPoolAdded(_pool);
    }

    /**
     * @notice Remove a liquidity pool address from the approved list.
     * @param _pool Address of the liquidity pool to remove.
     */
    function removeLiquidityPool(address _pool) external onlyAdmin {
        require(liquidityPools.contains(_pool), "Pool not found");
        liquidityPools.remove(_pool);
        emit LiquidityPoolRemoved(_pool);
    }

    function getLiquidityPoolsCount() external view returns (uint256) {
        return liquidityPools.length();
    }

    function getLiquidityPoolAt(uint256 index) external view returns (address) {
        require(index < liquidityPools.length(), "Index out of bounds");
        return liquidityPools.at(index);
    }

    /**
     * @notice Set the rebase frequency in seconds.
     */
    function setRebaseFrequency(uint256 newFrequency) external onlyAdmin {
        require(newFrequency > 0, "Frequency must be > 0");
        rebaseFrequency = newFrequency;
        emit RebaseFrequencyUpdated(newFrequency);
    }

    /**
     * @notice Set fee parameters.
     */
    function setFeeParameters(uint256 newTreasuryFeeBasisPoints, uint256 newLpFeeBasisPoints) external onlyAdmin {
        require(newTreasuryFeeBasisPoints + newLpFeeBasisPoints <= transferFeeBasisPoints, "Total fee exceeded");
        treasuryFeeBasisPoints = newTreasuryFeeBasisPoints;
        lpFeeBasisPoints = newLpFeeBasisPoints;
        emit FeeParametersUpdated(newTreasuryFeeBasisPoints, newLpFeeBasisPoints);
    }

    /**
     * @notice Update the treasury address.
     */
    function updateTreasuryAddress(address newTreasury) external onlyAdmin {
        require(newTreasury != address(0), "Zero address");
        address old = treasury;
        treasury = newTreasury;
        emit TreasuryAddressUpdated(old, newTreasury);
    }

    /**
     * @notice Burn tokens from the treasury.
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
