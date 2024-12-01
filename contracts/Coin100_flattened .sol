
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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;


/**
 * @dev Interface for the optional metadata functions from the ERC-20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

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

// File: @openzeppelin/contracts/interfaces/draft-IERC6093.sol


// OpenZeppelin Contracts (last updated v5.1.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC-20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC-721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in ERC-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC-1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;





/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC-20
 * applications.
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Skips emitting an {Approval} event indicating an allowance update. This is not
     * required by the ERC. See {xref-ERC20-_approve-address-address-uint256-bool-}[_approve].
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     *
     * ```solidity
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// File: @openzeppelin/contracts/utils/Pausable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;


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
    bool private _paused;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

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
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
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

// File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol


// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.20;



/**
 * @dev ERC-20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 *
 * IMPORTANT: This contract does not include public pause and unpause functions. In
 * addition to inheriting this contract, you must define both functions, invoking the
 * {Pausable-_pause} and {Pausable-_unpause} internal functions, with appropriate
 * access control, e.g. using {AccessControl} or {Ownable}. Not doing so will
 * make the contract pause mechanism of the contract unreachable, and thus unusable.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_update}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _update(address from, address to, uint256 value) internal virtual override whenNotPaused {
        super._update(from, to, value);
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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// File: contracts/Coin100.sol


pragma solidity ^0.8.20;

// Import OpenZeppelin Contracts




// Import Uniswap V2 Interfaces




// Import Chainlink Aggregator Interface


/**
 * @title COIN100 (C100) Token
 * @dev A decentralized cryptocurrency index fund tracking the top 100 cryptocurrencies by market capitalization.
 */
contract COIN100 is ERC20Pausable, Ownable, ReentrancyGuard {
    // =======================
    // ======= EVENTS ========
    // =======================
    event PriceAdjusted(uint256 newMarketCap, uint256 timestamp);
    event TokensBurned(uint256 amount);
    event TokensMinted(uint256 amount);
    event FeesUpdated(uint256 developerFee, uint256 burnFee, uint256 rewardFee);
    event FeePercentUpdated(uint256 newFeePercent);
    event WalletsUpdated(address developerWallet);
    event RebaseIntervalUpdated(uint256 newInterval);
    event UpkeepPerformed(address indexed performer, uint256 timestamp);
    event RewardsDistributed(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 newRewardRate, uint256 currentPrice);
    event RewardFeeUpdated(uint256 newRewardFee);
    event RewardsReplenished(uint256 amount, uint256 timestamp);
    event UniswapV2RouterUpdated(address newUniswapV2Router);
    event MaticPriceFeedUpdated(address newPriceFeed);
    event C100UsdPriceFeedUpdated(address newPriceFeed);
    event GovernorSet(address governor);

    // =======================
    // ======= STATE =========
    // =======================

    // Constants for decimals
    uint256 public constant PRICE_DECIMALS = 6; // USD has 6 decimals
    uint256 public constant TOKEN_DECIMALS = 18; // C100 has 18 decimals

    // Transaction fee percentages (in basis points)
    uint256 public feePercent = 3; // 3% total fee
    uint256 public developerFee = 40; // 40% of the feePercent (1.2%)
    uint256 public burnFee = 40; // 40% of the feePercent (1.2%)
    uint256 public rewardFee = 20; // 20% of the feePercent (0.6%)
    uint256 public constant FEE_DIVISOR = 100;

    // Reward Tracking Variables
    uint256 public rewardPerTokenStored;
    uint256 public lastUpdateTime;
    uint256 public rewardRate = 1000 * 1e18; // Initialized to 1000 C100 tokens per rebase
    uint256 public totalRewards;
    uint256 public constant MAX_REWARD_RATE = 2000 * 1e18; // Maximum tokens per rebase
    uint256 public constant MIN_REWARD_RATE = 500 * 1e18;  // Minimum tokens per rebase

    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 1e18; // 1 billion tokens with 18 decimals
    uint256 public lastMarketCap;
    uint256 public constant MAX_REBASE_PERCENT = 5; // Maximum 5% change per rebase
    uint256 public constant MAX_MINT_AMOUNT = 50_000_000 * 1e18; // Increased to 50 million tokens per mint
    uint256 public constant MAX_BURN_AMOUNT = 50_000_000 * 1e18; // Increased to 50 million tokens per burn

    uint256 public totalMarketCap; // Current total market cap in USD

    address public developerWallet;

    address public WMATIC;

    // Uniswap
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    // Chainlink Price Feeds
    AggregatorV3Interface public maticUsdPriceFeed;
    AggregatorV3Interface public c100UsdPriceFeed; // New Price Feed for C100/USD

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    // Upkeep Variables
    uint256 public lastRebaseTime;
    uint256 public rebaseInterval = 7 days; // Minimum 7 days between upkeeps
    uint256 public upkeepReward = 10 * 1e18; // Reward for performing upkeep (10 C100 tokens)

    // Governance Variables
    address public governor;

    // =======================
    // ====== MODIFIERS =======
    // =======================

    /**
     * @dev Modifier to restrict functions to admin only.
     * Admin can be the owner (before governor is set) or the governor (after governor is set).
     */
    modifier onlyAdmin() {
        if (governor == address(0)) {
            require(owner() == msg.sender, "Caller is not the owner");
        } else {
            require(governor == msg.sender, "Caller is not the governor");
        }
        _;
    }

    // =======================
    // ====== CONSTRUCTOR =====
    // =======================

    /**
     * @dev Constructor that initializes the token, mints initial allocations, and sets up price feeds.
     * @param _wmatic Address of the WMATIC token.
     * @param _uniswapV2RouterAddress Address of the Uniswap V2 router.
     * @param _developerWallet Address of the developer wallet.
     * @param _maticUsdPriceFeed Address of the Chainlink MATIC/USD price feed.
     */
    constructor(
        address _wmatic,
        address _uniswapV2RouterAddress, 
        address _developerWallet,
        address _maticUsdPriceFeed
    )
        ERC20("COIN100", "C100")
        Ownable(msg.sender)
    {
        require(_wmatic != address(0), "Invalid WMATIC address");
        require(_developerWallet != address(0), "Invalid developer wallet");
        require(_uniswapV2RouterAddress != address(0), "Invalid Uniswap router address");
        require(_maticUsdPriceFeed != address(0), "Invalid MATIC/USD price feed address");

        developerWallet = _developerWallet;
        maticUsdPriceFeed = AggregatorV3Interface(_maticUsdPriceFeed);

        // Mint allocations
        _mint(owner(), (TOTAL_SUPPLY * 90) / 100); // 90% Public Sale + Treasury
        _mint(developerWallet, (TOTAL_SUPPLY * 5) / 100); // 5% Developer
        _mint(address(this), (TOTAL_SUPPLY * 5) / 100); // 5% Rewards Pool

        // Initialize totalRewards with the initial rewards pool
        totalRewards += (TOTAL_SUPPLY * 5) / 100;

        // Initialize rebasing and reward tracking timestamps
        lastRebaseTime = block.timestamp;
        lastUpdateTime = block.timestamp;

        // Initialize Uniswap V2 Router
        uniswapV2Router = IUniswapV2Router02(_uniswapV2RouterAddress);

        // Set WMATIC address
        WMATIC = _wmatic;

        // Create a Uniswap pair for this token with WMATIC
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), WMATIC);

        require(uniswapV2Pair != address(0), "Failed to create Uniswap pair");

        // Approve the router to spend tokens as needed
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
    }

    // =======================
    // ====== GOVERNANCE ======
    // =======================

    /**
     * @dev Allows the owner to set the governor address. Can only be set once.
     * @param _governor Address of the new governor.
     */
    function setGovernor(address _governor) external onlyOwner {
        require(_governor != address(0), "Governor cannot be zero address");
        require(governor == address(0), "Governor already set");
        governor = _governor;
        emit GovernorSet(_governor);
    }

    // =======================
    // ====== OVERRIDES ======
    // =======================

    /**
    * @dev Overrides the ERC20 transfer function to include fee logic and reward allocation.
    * @param recipient Address receiving the tokens.
    * @param amount Amount of tokens being transferred.
    * @return bool indicating success.
    */
    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        address sender = _msgSender();
        updateReward(sender);
        updateReward(recipient);

        if (sender == owner() || recipient == owner()) {
            // Owner transfers bypass fees
            return super.transfer(recipient, amount);
        }

        // Calculate total fee
        uint256 feeAmount = (amount * feePercent) / 100; // 3% total fee

        // Allocate fees based on adjusted percentages
        uint256 devFeeAmount = (feeAmount * developerFee) / FEE_DIVISOR; // 1.2%
        uint256 burnFeeAmount = (feeAmount * burnFee) / FEE_DIVISOR;     // 1.2%
        uint256 rewardFeeAmount = (feeAmount * rewardFee) / FEE_DIVISOR; // 0.6%

        // Transfer Developer Fee
        if (devFeeAmount > 0) {
            super.transfer(developerWallet, devFeeAmount);
        }

        // Burn Fee
        if (burnFeeAmount > 0) {
            _burn(sender, burnFeeAmount);
        }

        // Reward Fee
        if (rewardFeeAmount > 0) {
            super.transfer(address(this), rewardFeeAmount);
            totalRewards += rewardFeeAmount;
            emit RewardsDistributed(address(this), rewardFeeAmount); // Optional: Emit event for internal tracking
        }

        // Transfer the remaining amount to the recipient
        uint256 transferAmount = amount - feeAmount;
        return super.transfer(recipient, transferAmount);
    }

    /**
    * @dev Overrides the ERC20 transferFrom function to include fee logic and reward allocation.
    * @param sender Address sending the tokens.
    * @param recipient Address receiving the tokens.
    * @param amount Amount of tokens being transferred.
    * @return bool indicating success.
    */
    function transferFrom(address sender, address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        updateReward(sender);
        updateReward(recipient);

        if (sender == owner() || recipient == owner()) {
            // Owner transfers bypass fees
            return super.transferFrom(sender, recipient, amount);
        }

        // Calculate total fee
        uint256 feeAmount = (amount * feePercent) / 100; // 3% total fee

        // Allocate fees based on adjusted percentages
        uint256 devFeeAmount = (feeAmount * developerFee) / FEE_DIVISOR; // 1.2%
        uint256 burnFeeAmount = (feeAmount * burnFee) / FEE_DIVISOR;     // 1.2%
        uint256 rewardFeeAmount = (feeAmount * rewardFee) / FEE_DIVISOR; // 0.6%

        // Transfer Developer Fee
        if (devFeeAmount > 0) {
            super.transferFrom(sender, developerWallet, devFeeAmount);
        }

        // Burn Fee
        if (burnFeeAmount > 0) {
            _burn(sender, burnFeeAmount);
        }

        // Reward Fee
        if (rewardFeeAmount > 0) {
            super.transferFrom(sender, address(this), rewardFeeAmount);
            totalRewards += rewardFeeAmount;
            emit RewardsDistributed(address(this), rewardFeeAmount); // Optional: Emit event for internal tracking
        }

        // Transfer the remaining amount to the recipient
        uint256 transferAmount = amount - feeAmount;
        return super.transferFrom(sender, recipient, transferAmount);
    }

    // =======================
    // ====== ADMIN FUNCTIONS ==
    // =======================

    /**
     * @dev Allows the admin to set the total transaction fee percentage.
     * @param _feePercent The new fee percentage (e.g., 3 for 3%).
     */
    function setFeePercent(uint256 _feePercent) external onlyAdmin {
        require(_feePercent <= 100, "Fee percent cannot exceed 100%");
        feePercent = _feePercent;
        emit FeePercentUpdated(_feePercent);
    }

    /**
     * @dev Allows the admin to update transaction fees.
     * @param _developerFee New developer fee in basis points (percentage of feePercent).
     * @param _burnFee New burn fee in basis points (percentage of feePercent).
     * @param _rewardFee New reward fee in basis points (percentage of feePercent).
     */
    function updateFees(uint256 _developerFee, uint256 _burnFee, uint256 _rewardFee) external onlyAdmin {
        require(_developerFee + _burnFee + _rewardFee <= FEE_DIVISOR, "Total fee allocation cannot exceed 100%");
        developerFee = _developerFee;
        burnFee = _burnFee;
        rewardFee = _rewardFee;
        emit FeesUpdated(_developerFee, _burnFee, _rewardFee);
    }

    /**
     * @dev Allows the admin to update wallet addresses for fee collection.
     * @param _developerWallet New developer wallet address.
     */
    function updateWallets(address _developerWallet) external onlyAdmin {
        require(_developerWallet != address(0), "Invalid developer wallet address");
        developerWallet = _developerWallet;
        emit WalletsUpdated(_developerWallet);
    }

    /**
     * @dev Allows the admin to update the Uniswap V2 Router address.
     * @param _newRouter Address of the new Uniswap V2 Router.
     */
    function setUniswapV2Router(address _newRouter) external onlyAdmin {
        require(_newRouter != address(0), "Invalid Uniswap V2 Router address");
        uniswapV2Router = IUniswapV2Router02(_newRouter);
        emit UniswapV2RouterUpdated(_newRouter);
        
        // Approve the new router to spend tokens as needed
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
    }

    /**
     * @dev Allows the admin to update the rebase interval.
     *      Ensures that the new interval is within acceptable bounds to prevent abuse.
     * @param _newInterval The new interval in seconds. Must be at least 7 days and no more than 365 days.
     */
    function updateRebaseInterval(uint256 _newInterval) external onlyAdmin {
        require(_newInterval >= 7 days, "Interval too short");
        require(_newInterval <= 365 days, "Interval too long");
        rebaseInterval = _newInterval;
        emit RebaseIntervalUpdated(_newInterval);
    }

    /**
     * @dev Allows the admin to set the upkeep reward amount.
     * @param _newReward The new reward amount in C100 tokens.
     */
    function setUpkeepReward(uint256 _newReward) external onlyAdmin {
        upkeepReward = _newReward;
        emit RewardFeeUpdated(_newReward);
    }

    /**
     * @dev Allows the admin to update the MATIC/USD price feed address.
     * @param _newPriceFeed Address of the new Chainlink MATIC/USD price feed.
     */
    function updateMaticUsdPriceFeed(address _newPriceFeed) external onlyAdmin {
        require(_newPriceFeed != address(0), "Invalid price feed address");
        maticUsdPriceFeed = AggregatorV3Interface(_newPriceFeed);
        emit MaticPriceFeedUpdated(_newPriceFeed);
    }

    /**
     * @dev Allows the admin to set or update the C100/USD price feed address.
     *      Once set, the contract will use this direct price feed for price determination.
     * @param _newC100UsdPriceFeed Address of the new Chainlink C100/USD price feed.
     */
    function setC100UsdPriceFeed(address _newC100UsdPriceFeed) external onlyAdmin {
        require(_newC100UsdPriceFeed != address(0), "Invalid C100/USD price feed address");
        c100UsdPriceFeed = AggregatorV3Interface(_newC100UsdPriceFeed);
        emit C100UsdPriceFeedUpdated(_newC100UsdPriceFeed);
    }

    // =======================
    // ====== FUNCTIONS =======
    // =======================

    /**
     * @dev Retrieves the latest price of C100 in USD.
     *      - If the C100/USD price feed (`c100UsdPriceFeed`) is set, use it directly.
     *      - Else, if the C100/MATIC pair exists, derive the price using the reserves from this pair and the MATIC/USD price feed.
     *      - Otherwise, derive the price directly from the MATIC/USD price feed.
     * @return price The latest C100 price in USD with 6 decimals (USDC has 6 decimals).
     */
    function getLatestPrice() public view returns (uint256 price) {
        if (address(c100UsdPriceFeed) != address(0)) {
            // Use direct C100/USD price feed
            price = getPriceFromC100UsdFeed();
        } else {
            // Check if the C100/MATIC pair exists
            address pairMATIC = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), WMATIC);
            if (pairMATIC != address(0)) {
                // Derive price via C100/MATIC pair
                price = getDerivedPriceFromMatic(pairMATIC);
            } else {
                // Derive price directly from MATIC/USD price feed
                price = getDerivedPriceFromMaticUsd();
            }
        }
    }

    /**
     * @dev Internal function to fetch the C100/USD price directly from the Chainlink price feed.
     * @return price The price of C100 in USD with 6 decimals.
     */
    function getPriceFromC100UsdFeed() internal view returns (uint256 price) {
        (
            ,
            int256 priceInt,
            ,
            ,

        ) = c100UsdPriceFeed.latestRoundData();
        require(priceInt > 0, "Invalid C100/USD price from oracle");
        uint8 decimals = c100UsdPriceFeed.decimals();
        require(decimals <= PRICE_DECIMALS, "Price feed decimals exceed expected");
        price = uint256(priceInt) * (10 ** (PRICE_DECIMALS - decimals)); // Adjust to 6 decimals
    }

    /**
     * @dev Internal function to derive the C100/USD price using C100/MATIC and MATIC/USD prices.
     * @param pairMATIC Address of the C100/MATIC Uniswap pair.
     * @return priceViaMATIC The derived price of C100 in USD with 6 decimals.
     */
    function getDerivedPriceFromMatic(address pairMATIC) internal view returns (uint256 priceViaMATIC) {
        IUniswapV2Pair pair = IUniswapV2Pair(pairMATIC);
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        address token0 = pair.token0();
        uint256 reserveC100;
        uint256 reserveMATIC;
        if (token0 == address(this)) {
            reserveC100 = uint256(reserve0);
            reserveMATIC = uint256(reserve1);
        } else {
            reserveC100 = uint256(reserve1);
            reserveMATIC = uint256(reserve0);
        }

        require(reserveC100 > 0 && reserveMATIC > 0, "Uniswap reserves not available for MATIC pair");

        // Get MATIC/USD price from Chainlink
        (, int256 maticPriceInt, , , ) = maticUsdPriceFeed.latestRoundData();
        require(maticPriceInt > 0, "Invalid MATIC/USD price from oracle");
        uint8 maticDecimals = maticUsdPriceFeed.decimals();
        require(maticDecimals <= PRICE_DECIMALS, "Price feed decimals exceed expected");
        uint256 maticPriceUSD = uint256(maticPriceInt) * (10 ** (PRICE_DECIMALS - maticDecimals)); // Adjust to 6 decimals

        // Calculate price in USD: (reserveMATIC / reserveC100) * maticPriceUSD
        // To maintain precision, multiply before division
        priceViaMATIC = (reserveMATIC * maticPriceUSD) / reserveC100;
    }

    /**
     * @dev Internal function to derive the C100/USD price directly from the MATIC/USD price feed.
     *      Assumes C100 is equivalent to MATIC in valuation when C100/MATIC pair doesn't exist.
     * @return priceViaMATIC The derived price of C100 in USD with 6 decimals.
     */
    function getDerivedPriceFromMaticUsd() internal view returns (uint256 priceViaMATIC) {
        // Get MATIC/USD price from Chainlink
        (, int256 maticPriceInt, , , ) = maticUsdPriceFeed.latestRoundData();
        require(maticPriceInt > 0, "Invalid MATIC/USD price from oracle");
        uint8 maticDecimals = maticUsdPriceFeed.decimals();
        require(maticDecimals <= PRICE_DECIMALS, "Price feed decimals exceed expected");
        priceViaMATIC = uint256(maticPriceInt) * (10 ** (PRICE_DECIMALS - maticDecimals)); // Adjust to 6 decimals

        // In absence of C100/MATIC pair, assume C100 price equals MATIC/USD price
        priceViaMATIC = priceViaMATIC;
    }

    /**
     * @dev Adjusts the token supply based on the latest market cap data with rebase limits.
     * @param fetchedMarketCap The latest total market cap in USD (6 decimals, matching USDC).
     */
    function adjustSupply(uint256 fetchedMarketCap) internal nonReentrant {
        uint256 currentPrice = getLatestPrice(); // Price with 6 decimals
        uint256 currentC100MarketCap = (totalSupply() * currentPrice) / (10 ** TOKEN_DECIMALS); // Scaling to 6 decimals

        // Compute Price Adjustment Factor (PAF)
        uint256 paf = (fetchedMarketCap * 1e18) / currentC100MarketCap;

        if (paf > 1e18 + (MAX_REBASE_PERCENT * 1e16)) { // Allow up to MAX_REBASE_PERCENT% increase
            uint256 rebaseFactor = (MAX_REBASE_PERCENT * 1e16); // 5% in 1e18 scale
            uint256 mintAmount = (totalSupply() * rebaseFactor) / 1e18;
            require(mintAmount <= MAX_MINT_AMOUNT, "Mint amount exceeds maximum");
            _mint(address(this), mintAmount);
            emit TokensMinted(mintAmount);
        } else if (paf < 1e18 - (MAX_REBASE_PERCENT * 1e16)) { // Allow up to MAX_REBASE_PERCENT% decrease
            uint256 rebaseFactor = (MAX_REBASE_PERCENT * 1e16);
            uint256 burnAmount = (totalSupply() * rebaseFactor) / 1e18;
            require(burnAmount <= MAX_BURN_AMOUNT, "Burn amount exceeds maximum");
            _burn(address(this), burnAmount);
            emit TokensBurned(burnAmount);
        }

        lastMarketCap = fetchedMarketCap;
        emit PriceAdjusted(fetchedMarketCap, block.timestamp);
    }

    /**
    * @dev Distributes rewards by updating the rewardPerTokenStored and allocating tokens to the rewards pool.
    */
    function distributeRewards() internal {
        updateReward(address(0)); // Update global rewards

        adjustRewardRate();

        uint256 distributionAmount = rewardRate;

        uint256 contractBalance = balanceOf(address(this));
        uint256 availableForDistribution = contractBalance > totalRewards ? contractBalance - totalRewards : 0;

        if (availableForDistribution < distributionAmount) {
            distributionAmount = availableForDistribution;
        }

        if (distributionAmount > 0) {
            totalRewards -= distributionAmount; // Deduct from totalRewards
            lastUpdateTime = block.timestamp;
            emit RewardsReplenished(distributionAmount, block.timestamp);
            
            // Transfer rewards to a specific rewards pool or directly to users
            // Example: _transfer(address(this), rewardsPool, distributionAmount);
        }
    }

    // =======================
    // ====== REWARDS ========
    // =======================

    /**
    * @dev Allows liquidity providers to claim their accumulated rewards.
    * Users must hold LP tokens from the Uniswap pair to be eligible.
    */
    function claimRewards() external nonReentrant {
        updateReward(msg.sender);

        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards available");

        rewards[msg.sender] = 0;
        totalRewards -= reward;

        _transfer(address(this), msg.sender, reward);

        emit RewardsDistributed(msg.sender, reward);
    }

    /**
    * @dev Updates the reward variables to be up-to-date.
    */
    function updateReward(address account) internal {
        rewardPerTokenStored = rewardPerToken();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
    }

    /**
    * @dev Calculates the current reward per token.
    * @return The updated reward per token.
    */
    function rewardPerToken() public view returns (uint256) {
        uint256 totalSupplyLP = IUniswapV2Pair(uniswapV2Pair).totalSupply();
        if (totalSupplyLP == 0) {
            return rewardPerTokenStored;
        }
        // Ensure no overflow and proper scaling
        return
            rewardPerTokenStored +
            ((rewardRate * 1e18) / totalSupplyLP);
    }

    /**
    * @dev Calculates the earned rewards for a user.
    * @param account The address of the user.
    * @return The amount of rewards earned by the user.
    */
    function earned(address account) public view returns (uint256) {
        uint256 balance = IUniswapV2Pair(uniswapV2Pair).balanceOf(account);
        if (balance == 0) {
            return rewards[account];
        }
        return ((balance * (rewardPerTokenStored - userRewardPerTokenPaid[account])) / 1e18) + rewards[account];
    }

    /**
    * @dev Adjusts the reward rate based on the current token price.
    * Lower reward rate when the token price increases and vice versa.
    */
    function adjustRewardRate() internal {
        uint256 currentPrice = getLatestPrice(); // Price with 6 decimals
        uint256 newRewardRate;
        
        if (currentPrice < 1 * 1e6) { // Below $1
            newRewardRate = 2000 * 1e18; // Highest rewards per rebase
        } else if (currentPrice >= 1 * 1e6 && currentPrice < 5 * 1e6) { // $1 - $5
            newRewardRate = 1500 * 1e18;
        } else if (currentPrice >= 5 * 1e6 && currentPrice < 10 * 1e6) { // $5 - $10
            newRewardRate = 1000 * 1e18;
        } else { // $10 and above
            newRewardRate = 500 * 1e18; // Lowest rewards per rebase
        }
        
        // Apply bounds without additional scaling
        if (newRewardRate > MAX_REWARD_RATE) {
            newRewardRate = MAX_REWARD_RATE;
        } else if (newRewardRate < MIN_REWARD_RATE) {
            newRewardRate = MIN_REWARD_RATE;
        }
        
        if (newRewardRate != rewardRate) {
            rewardRate = newRewardRate;
            emit RewardRateUpdated(newRewardRate, currentPrice);
        }
    }

    // =======================
    // ====== UPKEEP =========
    // =======================

    /**
     * @dev Allows anyone to perform upkeep tasks manually.
     * Requires that at least `rebaseInterval` has passed since the last upkeep.
     * Rewards the caller with `upkeepReward` C100 tokens.
     * @param _fetchedMarketCap The latest total market cap in USD (6 decimals, matching USDC).
     */
    function performUpkeep(uint256 _fetchedMarketCap) external nonReentrant {
        require(block.timestamp >= lastRebaseTime + rebaseInterval, "Upkeep interval not reached");
        require(_fetchedMarketCap > 0, "Invalid market cap");

        // Update the total market cap
        totalMarketCap = _fetchedMarketCap;

        // Adjust the supply based on the new market cap
        adjustSupply(_fetchedMarketCap);

        // Update the last rebase time
        lastRebaseTime = block.timestamp;

        // Reward the caller
        if (upkeepReward > 0 && balanceOf(address(this)) >= upkeepReward) {
            _transfer(address(this), msg.sender, upkeepReward);
            emit RewardsDistributed(msg.sender, upkeepReward);
        }

        emit UpkeepPerformed(msg.sender, block.timestamp);
    }
}
