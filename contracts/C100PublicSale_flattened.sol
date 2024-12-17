
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: contracts/C100PublicSale.sol


pragma solidity ^0.8.28;





/**
 * @title C100PublicSale
 * @notice A public sale contract for C100 tokens. The polRate is updated by the C100 contract periodically.
 */
contract C100PublicSale is Ownable, ReentrancyGuard, Pausable {
    IERC20 public c100Token;
    address public govContract;
    address public treasury;

    uint256 public startTime;
    uint256 public endTime;
    bool public finalized;

    // Current polRate (C100 per POL) scaled by 1e18
    uint256 public polRate;

    mapping(address => uint256) public erc20Rates; 

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    event GovernorContractSet(address indexed oldGovernor, address indexed newGovernor);
    event TokenPurchased(address indexed buyer, address indexed paymentToken, uint256 paymentAmount, uint256 c100Amount);
    event RatesUpdated(uint256 newPolRate);
    event Erc20RateUpdated(address indexed token, uint256 newRate);
    event ICOParametersUpdated(uint256 newStart, uint256 newEnd);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event Finalized(uint256 unsoldTokensBurned);
    event TokensRescued(address indexed token, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == owner() || (govContract != address(0) && msg.sender == govContract), "Not admin");
        _;
    }

    modifier icoActive() {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "ICO not active");
        require(!finalized, "ICO finalized");
        _;
    }

    modifier icoNotStarted() {
        require(block.timestamp < startTime, "ICO started");
        _;
    }

    modifier icoEnded() {
        require(block.timestamp > endTime, "ICO not ended");
        _;
    }

    constructor(
        address c100TokenAddress,
        address initialTreasury,
        uint256 initialStartTime,
        uint256 initialEndTime,
        uint256 initialPolRate
    )
        Ownable(msg.sender)
        Pausable()
        ReentrancyGuard()
    {
        require(c100TokenAddress != address(0), "C100 zero");
        require(initialTreasury != address(0), "Treasury zero");
        require(initialStartTime < initialEndTime, "Invalid time range");
        require(initialPolRate > 0, "polRate must be >0");

        c100Token = IERC20(c100TokenAddress);
        treasury = initialTreasury;
        startTime = initialStartTime;
        endTime = initialEndTime;
        polRate = initialPolRate; // initial polRate
    }

    receive() external payable {
        // Allows receiving POL for buyWithPOL()
    }

    fallback() external payable {
        revert("No ETH");
    }

    function polRateView() external view returns (uint256) {
        return polRate;
    }

    function buyWithPOL() external payable nonReentrant whenNotPaused icoActive {
        require(msg.value > 0, "No POL sent");
        // polRate = C100 per POL * 1e18
        // If msg.value is in POL (no scaling), C100 = (msg.value * polRate) / 1e18
        uint256 c100Amount = (msg.value * polRate) / 1e18;
        _deliverTokens(msg.sender, c100Amount);
        _forwardFunds(msg.value);
        emit TokenPurchased(msg.sender, address(0), msg.value, c100Amount);
    }

    function buyWithToken(address token, uint256 tokenAmount) external nonReentrant whenNotPaused icoActive {
        require(token != address(0), "Token zero");
        uint256 rate = erc20Rates[token];
        require(rate > 0, "Token not accepted");
        require(tokenAmount > 0, "No tokens sent");

        // rate = C100 per token * 1e18
        uint256 c100Amount = (tokenAmount * rate) / 1e18;
        require(IERC20(token).transferFrom(msg.sender, treasury, tokenAmount), "Transfer failed");
        _deliverTokens(msg.sender, c100Amount);
        emit TokenPurchased(msg.sender, token, tokenAmount, c100Amount);
    }

    function finalize() external onlyAdmin icoEnded nonReentrant {
        require(!finalized, "Already finalized");
        finalized = true;

        uint256 unsold = c100Token.balanceOf(address(this));
        if (unsold > 0) {
            require(c100Token.transfer(BURN_ADDRESS, unsold), "Burn transfer failed");
        }
        emit Finalized(unsold);
    }

    function setGovernorContract(address _govContract) external onlyOwner {
        address oldGov = govContract;
        govContract = _govContract;
        emit GovernorContractSet(oldGov, _govContract);
    }

    function pauseContract() external onlyAdmin {
        _pause();
    }

    function unpauseContract() external onlyAdmin {
        _unpause();
    }

    // Update polRate by C100 contract at rebase
    function updatePOLRate(uint256 newRate) external onlyAdmin {
        require(newRate > 0, "Rate must be >0");
        polRate = newRate;
        emit RatesUpdated(newRate);
    }

    function updateErc20Rate(address token, uint256 newRate) external onlyAdmin icoNotStarted {
        require(token != address(0), "Token zero");
        require(newRate > 0, "Rate >0");
        erc20Rates[token] = newRate;
        emit Erc20RateUpdated(token, newRate);
    }

    function updateICOParameters(uint256 newStart, uint256 newEnd) external onlyAdmin icoNotStarted {
        require(newStart < newEnd, "Invalid range");
        startTime = newStart;
        endTime = newEnd;
        emit ICOParametersUpdated(newStart, newEnd);
    }

    function updateTreasury(address newTreasury) external onlyAdmin {
        require(newTreasury != address(0), "Zero");
        address old = treasury;
        treasury = newTreasury;
        emit TreasuryUpdated(old, newTreasury);
    }

    function rescueTokens(address token) external onlyAdmin {
        require(token != address(0), "Zero");
        if (token == address(c100Token) && !finalized) {
            revert("Cannot rescue C100 before finalize");
        }
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            require(IERC20(token).transfer(treasury, balance), "Rescue fail");
            emit TokensRescued(token, balance);
        }
    }

    function burnFromTreasury(uint256 amount) external onlyAdmin nonReentrant {
        require(c100Token.balanceOf(treasury) >= amount, "Not enough");
        require(c100Token.transfer(BURN_ADDRESS, amount), "Burn failed");
        // We do not emit Transfer here since not an ERC20 contract.
        // If needed, create a custom event.
    }

    function _deliverTokens(address recipient, uint256 amount) internal {
        require(c100Token.balanceOf(address(this)) >= amount, "Not enough C100");
        require(c100Token.transfer(recipient, amount), "C100 transfer failed");
    }

    function _forwardFunds(uint256 amount) internal {
        (bool success, ) = treasury.call{value: amount}("");
        require(success, "Forwarding POL failed");
    }
}
