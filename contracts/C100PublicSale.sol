// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// OpenZeppelin Contracts
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title C100PublicSale
 * @notice A public sale contract for C100 tokens supporting multiple payment tokens at specific rates.
 *
 * Features:
 * - Owned by the treasury.
 * - Presale duration defined by start and end timestamps.
 * - Allows buying C100 with multiple approved ERC20 tokens at specified rates.
 * - Admins can add or remove allowed payment tokens and set their rates.
 * - Finalizes by burning unsold C100 tokens.
 */
contract C100PublicSale is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // ---------------------------------------
    // State Variables
    // ---------------------------------------

    /// @notice The C100 token being sold.
    IERC20 public c100Token;

    /// @notice The treasury address where funds are collected.
    address public treasury;

    /// @notice Struct representing an allowed payment token.
    struct AllowedToken {
        IERC20 token;        // ERC20 token used for payment
        uint256 rate;        // Price per C100, scaled by 1e18 (e.g., 1e15 represents 0.001 token per C100)
        string symbol;       // Symbol of the payment token
        string name;         // Name of the payment token
        uint8 decimals;      // Decimals of the payment token
    }

    /// @notice Array of allowed payment tokens.
    AllowedToken[] public allowedTokens;

    /// @notice Mapping to check if a token is allowed for payment.
    mapping(address => bool) public isAllowedToken;

    /// @notice Start time of the ICO (Unix timestamp).
    uint256 public startTime;

    /// @notice End time of the ICO (Unix timestamp).
    uint256 public endTime;

    /// @notice Flag indicating whether the ICO has been finalized.
    bool public finalized;

    // ---------------------------------------
    // Events
    // ---------------------------------------

    /// @notice Emitted when a token purchase occurs.
    event TokenPurchased(
        address indexed buyer,
        address indexed paymentToken,
        uint256 paymentAmount,
        uint256 c100Amount
    );

    /// @notice Emitted when a new payment token is added.
    event AllowedTokenAdded(
        address indexed token,
        uint256 rate,
        string symbol,
        string name,
        uint8 decimals
    );

    /// @notice Emitted when a payment token is removed.
    event AllowedTokenRemoved(address indexed token);

    /// @notice Emitted when ICO parameters are updated.
    event ICOParametersUpdated(uint256 newStart, uint256 newEnd);

    /// @notice Emitted when the treasury address is updated.
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);

    /// @notice Emitted when the ICO is finalized.
    event Finalized(uint256 unsoldTokensBurned);

    /// @notice Emitted when tokens are rescued from the contract.
    event TokensRescued(address indexed token, uint256 amount);

    /// @notice Emitted when the C100 token address is updated.
    event C100TokenUpdated(address oldC100, address newC100);

    /// @notice Emitted when the sale is initialized.
    event SaleInitialized(
        address c100Token,
        address initialPaymentToken,
        uint256 rate,
        string symbol,
        string name,
        uint8 decimals,
        address treasury,
        uint256 startTime,
        uint256 endTime
    );

    // ---------------------------------------
    // Modifiers
    // ---------------------------------------

    /**
     * @notice Modifier to check if the ICO is currently active.
     */
    modifier icoActive() {
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "ICO not active"
        );
        require(!finalized, "ICO finalized");
        _;
    }

    /**
     * @notice Modifier to check if the ICO has not started yet.
     */
    modifier icoNotStarted() {
        require(block.timestamp < startTime, "ICO started");
        _;
    }

    /**
     * @notice Modifier to check if the ICO has ended.
     */
    modifier icoEnded() {
        require(block.timestamp > endTime, "ICO not ended");
        _;
    }

    // ---------------------------------------
    // Constructor
    // ---------------------------------------

    /**
     * @notice Constructor to initialize the public sale contract.
     * @param _c100Token Address of the C100 token contract.
     * @param _initialToken Address of the initial payment token.
     * @param _initialRate Price per C100 in the initial token, scaled by 1e18.
     * @param _initialSymbol Symbol of the initial token.
     * @param _initialName Name of the initial token.
     * @param _initialDecimals Decimals of the initial token.
     * @param _treasury Address of the treasury.
     * @param _startTime UNIX timestamp for ICO start.
     * @param _endTime UNIX timestamp for ICO end (e.g., 12 months later).
     */
    constructor(
        address _c100Token,
        address _initialToken,
        uint256 _initialRate,
        string memory _initialSymbol,
        string memory _initialName,
        uint8 _initialDecimals,
        address _treasury,
        uint256 _startTime,
        uint256 _endTime
    )
        Ownable(_treasury)
        ReentrancyGuard()
        Pausable()
    {
        require(_c100Token != address(0), "C100 token zero address");
        require(_initialToken != address(0), "Initial token zero address");
        require(_treasury != address(0), "Treasury zero address");
        require(_startTime < _endTime, "Invalid time range");
        require(_initialRate > 0, "Initial rate must be > 0");

        c100Token = IERC20(_c100Token);
        treasury = _treasury;
        startTime = _startTime;
        endTime = _endTime;

        // Add the initial allowed payment token
        AllowedToken memory newToken = AllowedToken({
            token: IERC20(_initialToken),
            rate: _initialRate,
            symbol: _initialSymbol,
            name: _initialName,
            decimals: _initialDecimals
        });

        allowedTokens.push(newToken);
        isAllowedToken[_initialToken] = true;

        emit AllowedTokenAdded(_initialToken, _initialRate, _initialSymbol, _initialName, _initialDecimals);
        emit SaleInitialized(
            _c100Token,
            _initialToken,
            _initialRate,
            _initialSymbol,
            _initialName,
            _initialDecimals,
            _treasury,
            _startTime,
            _endTime
        );
    }

    // ---------------------------------------
    // Public Functions
    // ---------------------------------------

    /**
     * @notice Allows users to purchase C100 tokens with any allowed token at a specific rate.
     * @param paymentToken Address of the token to pay with.
     * @param paymentAmount Amount of the payment token to spend (with its decimals).
     */
    function buyWithToken(address paymentToken, uint256 paymentAmount)
        external
        nonReentrant
        whenNotPaused
        icoActive
    {
        require(isAllowedToken[paymentToken], "Token not allowed");
        require(paymentAmount > 0, "Payment amount must be > 0");

        AllowedToken memory tokenData = getAllowedToken(paymentToken);
        require(address(tokenData.token) != address(0), "Invalid token data");

        // Calculate C100 amount: (paymentAmount * 1e18) / rate
        uint256 c100Amount = (paymentAmount * 1e18) / tokenData.rate;

        require(
            c100Token.balanceOf(address(this)) >= c100Amount,
            "Not enough C100 tokens"
        );

        // Transfer payment tokens from buyer to treasury
        tokenData.token.safeTransferFrom(msg.sender, treasury, paymentAmount);

        // Transfer C100 tokens to buyer
        c100Token.safeTransfer(msg.sender, c100Amount);

        emit TokenPurchased(msg.sender, paymentToken, paymentAmount, c100Amount);
    }

    /**
     * @notice Retrieves the allowed token data.
     * @param token Address of the token.
     * @return AllowedToken struct containing token data.
     */
    function getAllowedToken(address token)
        public
        view
        returns (AllowedToken memory)
    {
        require(isAllowedToken[token], "Token not allowed");
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            if (address(allowedTokens[i].token) == token) {
                return allowedTokens[i];
            }
        }
        revert("Token not found");
    }

    /**
     * @notice Allows the admin to add a new allowed token for purchasing C100.
     * @param _token Address of the new payment token.
     * @param _rate Price per C100 in the new token, scaled by 1e18.
     * @param _symbol Symbol of the new token.
     * @param _name Name of the new token.
     * @param _decimals Decimals of the new token.
     */
    function addAllowedToken(
        address _token,
        uint256 _rate,
        string memory _symbol,
        string memory _name,
        uint8 _decimals
    ) external onlyOwner {
        require(_token != address(0), "Token zero address");
        require(!isAllowedToken[_token], "Token already allowed");
        require(_rate > 0, "Rate must be > 0");

        AllowedToken memory newToken = AllowedToken({
            token: IERC20(_token),
            rate: _rate,
            symbol: _symbol,
            name: _name,
            decimals: _decimals
        });

        allowedTokens.push(newToken);
        isAllowedToken[_token] = true;

        emit AllowedTokenAdded(_token, _rate, _symbol, _name, _decimals);
    }

    /**
     * @notice Allows the admin to remove an allowed token from purchasing C100.
     * @param _token Address of the token to remove.
     */
    function removeAllowedToken(address _token) external onlyOwner {
        require(isAllowedToken[_token], "Token not allowed");

        // Find the token in the array
        uint256 indexToRemove = allowedTokens.length;
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            if (address(allowedTokens[i].token) == _token) {
                indexToRemove = i;
                break;
            }
        }
        require(indexToRemove < allowedTokens.length, "Token not found in array");

        // Swap with last element and pop
        AllowedToken memory lastToken = allowedTokens[allowedTokens.length - 1];
        allowedTokens[indexToRemove] = lastToken;
        allowedTokens.pop();

        // Update mapping
        isAllowedToken[_token] = false;

        emit AllowedTokenRemoved(_token);
    }

    /**
     * @notice Returns all allowed tokens.
     * @return Array of AllowedToken structs.
     */
    function getAllowedTokens() external view returns (AllowedToken[] memory) {
        return allowedTokens;
    }

    // ---------------------------------------
    // Admin Functions
    // ---------------------------------------

    /**
     * @notice Finalizes the ICO by burning any unsold C100 tokens.
     */
    function finalize() external onlyOwner icoEnded nonReentrant {
        require(!finalized, "Already finalized");
        finalized = true;

        uint256 unsold = c100Token.balanceOf(address(this));
        if (unsold > 0) {
            c100Token.safeTransfer(
                address(0x000000000000000000000000000000000000dEaD),
                unsold
            );
        }

        emit Finalized(unsold);
    }

    /**
     * @notice Update ICO parameters before it starts.
     * @param newStart UNIX timestamp for new ICO start.
     * @param newEnd UNIX timestamp for new ICO end.
     */
    function updateICOParameters(uint256 newStart, uint256 newEnd)
        external
        onlyOwner
        icoNotStarted
    {
        require(newStart < newEnd, "Invalid time range");
        startTime = newStart;
        endTime = newEnd;
        emit ICOParametersUpdated(newStart, newEnd);
    }

    /**
     * @notice Update the treasury address.
     * @param newTreasury New treasury address.
     */
    function updateTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "Zero address");
        address old = treasury;
        treasury = newTreasury;
        emit TreasuryUpdated(old, newTreasury);
    }

    /**
     * @notice Update the C100 token address.
     * @param newC100 Address of the new C100 token.
     */
    function updateC100Token(address newC100) external onlyOwner {
        require(newC100 != address(0), "Zero address");
        address oldC100 = address(c100Token);
        c100Token = IERC20(newC100);
        emit C100TokenUpdated(oldC100, newC100);
    }

    /**
     * @notice Rescues tokens accidentally sent to the contract, excluding C100 and allowed payment tokens.
     * @param token Address of the token to rescue.
     * @param amount Amount of tokens to rescue.
     */
    function rescueTokens(address token, uint256 amount)
        external
        onlyOwner
    {
        require(token != address(c100Token), "Cannot rescue C100 tokens");

        // Disallow rescuing any allowed payment tokens
        require(!isAllowedToken[token], "Cannot rescue allowed payment tokens");

        require(token != address(0), "Zero address");

        IERC20(token).safeTransfer(treasury, amount);
        emit TokensRescued(token, amount);
    }

    /**
     * @notice Burn C100 tokens from the treasury.
     * @param amount Amount of C100 tokens to burn.
     *
     * Requirements:
     * - The treasury must have approved this contract to spend at least `amount` C100 tokens.
     */
    function burnFromTreasury(uint256 amount)
        external
        onlyOwner
        nonReentrant
    {
        require(
            c100Token.balanceOf(treasury) >= amount,
            "Not enough tokens in treasury"
        );
        // The treasury must approve this contract to spend the tokens.
        c100Token.safeTransferFrom(
            treasury,
            address(0x000000000000000000000000000000000000dEaD),
            amount
        );
    }

    /**
     * @notice Pause the contract, disabling purchases and other functionalities.
     *
     * Requirements:
     * - The contract must not be paused.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract, enabling purchases and other functionalities.
     *
     * Requirements:
     * - The contract must be paused.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }
}
