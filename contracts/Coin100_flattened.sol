
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: contracts/Coin100.sol


pragma solidity ^0.8.28;




/**
 * @title IC100PublicSale
 * @notice Interface to interact with the C100PublicSale contract.
 */
interface IC100PublicSale {
    function polRate() external view returns (uint256);
    function updatePOLRate(uint256 newRate) external;
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

/**
 * @title COIN100 (C100)
 * @notice A rebasing token representing the top 100 crypto market cap index.
 *         On each rebase, all balances scale proportionally to reflect changes
 *         in the top 100 market cap, ensuring each holder maintains their fraction.
 * 
 * New Features:
 * - Fee-Based Treasury Growth
 * - LP Rewards Allocation
 * - Governance Transition
 * - Dynamic polRate Update in Public Sale
 *
 * Daily/periodic manual rebases:
 * - Admin calls `rebase(newMarketCap)` to adjust supply based on top 100 market cap.
 *
 * Governance Transition:
 * - Initially, owner is admin.
 * - A govContract can be set, sharing admin rights.
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
    address public c100USDCPool;  // For fallback price in USDC
    address public c100POLPool;   // Primary source for polRate (C100 per POL)

    // polInUSDCRate: USDC per POL (scaled by 1e18) for fallback calculations
    uint256 public polInUSDCRate;

    // Last calculated polRate from pools
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

    constructor(uint256 initialMarketCap, uint256 initialPolRate) Ownable(msg.sender) Pausable() ReentrancyGuard() {
        require(initialMarketCap > 0, "Initial mcap must be > 0");
        require(initialPolRate > 0, "Initial polRate must be > 0");

        _totalSupply = initialMarketCap;
        lastMarketCap = initialMarketCap;

        ownerAllocation = (_totalSupply * 3) / 100;           
        remainingAllocation = _totalSupply - ownerAllocation; 

        _gonsPerFragment = MAX_GONS / _totalSupply;

        uint256 totalGons = _totalSupply * _gonsPerFragment;
        _gonsBalances[owner()] = totalGons;

        emit Transfer(address(0), owner(), _totalSupply);

        // Default parameters
        rebaseFrequency = 1 days;
        transfersWithFee = true;                
        transferFeeBasisPoints = 100;           
        treasury = owner();
        lpRewardPercentage = 5; 
        lastCalculatedPolRate = initialPolRate; // Start with an initial polRate
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

        // Update polRate from pools before calculating supply
        uint256 oldPolRate = lastCalculatedPolRate;
        uint256 newPolRate = _getPolRateFromPools();
        lastCalculatedPolRate = newPolRate;

        // Sync with Public Sale if set
        if (address(publicSaleContract) != address(0)) {
            publicSaleContract.updatePOLRate(newPolRate);
        }
        emit POLRateUpdated(oldPolRate, newPolRate);

        uint256 ratioScaled = (newMarketCap * 1e18) / oldMarketCap;
        uint256 newSupply = (oldSupply * ratioScaled) / 1e18;
        require(newSupply > 0, "New supply must be > 0");

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
        lastMarketCap = newMarketCap;

        emit Rebase(oldMarketCap, newMarketCap, ratioScaled, block.timestamp);

        if (isIncrease && lpRewardPercentage > 0 && liquidityPoolList.length > 0) {
            uint256 rewardAmount = (supplyDelta * lpRewardPercentage) / 100;
            _allocateRewardsToLPs(rewardAmount);
        }
    }

    function _allocateRewardsToLPs(uint256 rewardAmount) internal {
        uint256 totalLpSupply = 0;
        for (uint256 i = 0; i < liquidityPoolList.length; i++) {
            totalLpSupply += balanceOf(liquidityPoolList[i]);
        }
        require(totalLpSupply > 0, "No LP supply");

        for (uint256 i = 0; i < liquidityPoolList.length; i++) {
            address pool = liquidityPoolList[i];
            uint256 poolBalance = balanceOf(pool);
            uint256 poolReward = (rewardAmount * poolBalance) / totalLpSupply;
            _gonsBalances[pool] += poolReward * _gonsPerFragment;
            emit Transfer(address(this), pool, poolReward);
        }

        _totalSupply += rewardAmount;
    }

    // Price Calculation
    function _getPolRateFromPools() internal view returns (uint256) {
        // Primary attempt: C100/POL pool
        if (c100POLPool != address(0)) {
            (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(c100POLPool).getReserves();
            address t0 = IUniswapV2Pair(c100POLPool).token0();
            (uint256 c100Reserve, uint256 polReserve) = t0 == address(this) 
                ? (uint256(reserve0), uint256(reserve1)) 
                : (uint256(reserve1), uint256(reserve0));
            
            if (polReserve > 0) {
                // C100 per POL = c100Reserve/polReserve * 1e18 scaling
                return (c100Reserve * 1e18) / polReserve;
            }
        }

        // Fallback: use C100/USDC pool and polInUSDCRate
        require(c100USDCPool != address(0), "No POL pool, no USDC pool");
        require(polInUSDCRate > 0, "polInUSDCRate not set");

        (uint112 r0, uint112 r1,) = IUniswapV2Pair(c100USDCPool).getReserves();
        address token0 = IUniswapV2Pair(c100USDCPool).token0();
        (uint256 c100R, uint256 usdcR) = token0 == address(this) 
            ? (uint256(r0), uint256(r1)) 
            : (uint256(r1), uint256(r0));
        require(c100R > 0, "No C100 in USDC pool");

        // c100PriceInUSDC = USDC per C100 * 1e18
        uint256 c100PriceInUSDC = (usdcR * 1e18) / c100R;

        // polInUSDCRate = USDC per POL * 1e18
        // C100 per POL = polInUSDCRate / c100PriceInUSDC
        require(c100PriceInUSDC > 0, "Invalid USDC ratio");
        return polInUSDCRate * 1e18 / c100PriceInUSDC;
    }

    // Admin functions
    function setGovernorContract(address _govContract) external onlyOwner {
        address oldGov = govContract;
        govContract = _govContract;
        emit GovernorContractSet(oldGov, _govContract);
    }

    function setPublicSaleContract(address _publicSaleContract) external onlyOwner {
        require(_publicSaleContract != address(0), "Public sale zero");
        address oldSale = address(publicSaleContract);
        publicSaleContract = IC100PublicSale(_publicSaleContract);
        emit PublicSaleContractSet(oldSale, _publicSaleContract);
    }

    function pauseContract() external onlyAdmin {
        _pause();
    }

    function unpauseContract() external onlyAdmin {
        _unpause();
    }

    function setRebaseFrequency(uint256 newFrequency) external onlyAdmin {
        rebaseFrequency = newFrequency;
    }

    function setTransferFeeParams(bool enabled, uint256 newFeeBasisPoints) external onlyAdmin {
        require(newFeeBasisPoints <= 1000, "Fee too high");
        transfersWithFee = enabled;
        transferFeeBasisPoints = newFeeBasisPoints;
        emit FeeParametersUpdated(enabled, newFeeBasisPoints);
    }

    function updateTreasuryAddress(address newTreasury) external onlyAdmin {
        require(newTreasury != address(0), "Zero");
        address old = treasury;
        treasury = newTreasury;
        emit TreasuryAddressUpdated(old, newTreasury);
    }

    function burnFromTreasury(uint256 amount) external onlyAdmin nonReentrant {
        require(balanceOf(treasury) >= amount, "Not enough tokens");
        uint256 gonsAmount = amount * _gonsPerFragment;
        _gonsBalances[treasury] -= gonsAmount;
        _totalSupply -= amount;
        _gonsPerFragment = MAX_GONS / _totalSupply;
        emit Transfer(treasury, address(0), amount);
    }

    function addLiquidityPool(address pool) external onlyAdmin {
        require(pool != address(0), "Zero");
        require(!liquidityPools[pool], "Already registered");
        liquidityPools[pool] = true;
        liquidityPoolList.push(pool);
        emit LiquidityPoolAdded(pool);
    }

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

    function setLpRewardPercentage(uint256 _lpRewardPercentage) external onlyAdmin {
        require(_lpRewardPercentage <= maxLpRewardPercentage, "Exceeds max limit");
        lpRewardPercentage = _lpRewardPercentage;
        emit LpRewardPercentageUpdated(_lpRewardPercentage);
    }

    function setMaxLpRewardPercentage(uint256 _maxLpRewardPercentage) external onlyAdmin {
        require(_maxLpRewardPercentage <= 50, "Too high");
        maxLpRewardPercentage = _maxLpRewardPercentage;
        emit MaxLpRewardPercentageUpdated(_maxLpRewardPercentage);
    }

    function setC100USDCPool(address pool) external onlyAdmin {
        address old = c100USDCPool;
        c100USDCPool = pool;
        emit C100USDCPoolSet(old, pool);
    }

    function setC100POLPool(address pool) external onlyAdmin {
        address old = c100POLPool;
        c100POLPool = pool;
        emit C100POLPoolSet(old, pool);
    }

    function setPolInUSDCRate(uint256 newRate) external onlyAdmin {
        require(newRate > 0, "Rate must be >0");
        uint256 old = polInUSDCRate;
        polInUSDCRate = newRate;
        emit PolInUSDCRateUpdated(old, newRate);
    }

    receive() external payable {
        revert("No ETH");
    }

    fallback() external payable {
        revert("No ETH");
    }
}
