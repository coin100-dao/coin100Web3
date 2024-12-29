// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// ========== Imports ========== //
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
 * - 12-month vesting: purchased C100 tokens are locked and claimable after `vestingDuration`.
 * - Per-user cap on the total C100 that can be purchased.
 * - Delay between consecutive purchases to mitigate bot attacks.
 * - Presale duration defined by start/end timestamps.
 * - Allows buying C100 with multiple approved ERC20 tokens at specified rates.
 * - Finalizes by burning only the truly unsold C100 tokens.
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
        uint256 rate;        // Price per 1 C100, scaled by 1e18 (e.g., 1e15 = 0.001 token per C100)
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
    // Vesting & Purchase Control
    // ---------------------------------------

    /// @notice The vesting duration (seconds) for each purchase. (e.g. 12 months = 365 days)
    uint256 public vestingDuration = 365 days;

    /// @notice The minimum delay (seconds) between consecutive purchases by the same user.
    uint256 public purchaseDelay = 300; // 5 minutes

    /// @notice The maximum C100 each user can purchase (1e18 = 1 token if decimals=18).
    uint256 public maxUserCap = 1_000_000 ether;

    /// @notice Tracks the total amount of C100 each user has purchased (enforcing `maxUserCap`).
    mapping(address => uint256) public userPurchases;

    /// @notice Tracks the last purchase timestamp for each user (enforcing `purchaseDelay`).
    mapping(address => uint256) public lastPurchaseTime;

    /// @notice Tracks the total amount of tokens currently locked for vesting across **all** users.
    uint256 public totalLockedTokens;

    /// @notice Struct storing vesting info for each purchase.
    struct VestingSchedule {
        uint256 amount;       // how many C100 tokens locked for this purchase
        uint256 releaseTime;  // when tokens can be claimed
    }

    /// @notice Mapping: user => array of vesting schedules
    mapping(address => VestingSchedule[]) public vestings;

    // ---------------------------------------
    // Events
    // ---------------------------------------

    /// @notice Emitted when a token purchase occurs (tokens are locked, not immediately transferred).
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

    /// @notice Emitted when the ICO is finalized (unsold tokens burned).
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

    /// @notice Emitted when user claims vested tokens.
    event TokensClaimed(address indexed user, uint256 amount);

    /// @notice Emitted when vestingDuration, purchaseDelay, or maxUserCap are updated.
    event VestingConfigUpdated(
        uint256 newVestingDuration,
        uint256 newPurchaseDelay,
        uint256 newMaxUserCap
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
     * @param _endTime UNIX timestamp for ICO end.
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
        Ownable(_treasury) // Set the owner as the treasury
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
     *         The purchased tokens are locked and claimable after `vestingDuration`.
     * @param paymentToken Address of the token to pay with.
     * @param paymentAmount Amount of the payment token to spend.
     */
    function buyWithToken(address paymentToken, uint256 paymentAmount)
        external
        nonReentrant
        whenNotPaused
        icoActive
    {
        require(isAllowedToken[paymentToken], "Token not allowed");
        require(paymentAmount > 0, "Payment amount must be > 0");

        // Enforce delay between purchases
        require(
            block.timestamp >= lastPurchaseTime[msg.sender] + purchaseDelay,
            "Purchase too soon"
        );

        AllowedToken memory tokenData = getAllowedToken(paymentToken);

        // Calculate how many C100 tokens (1e18 decimals) the user receives
        // c100Amount = (paymentAmount * 1e18) / rate
        uint256 c100Amount = (paymentAmount * 1e18) / tokenData.rate;
        require(
            c100Token.balanceOf(address(this)) >= (totalLockedTokens + c100Amount),
            "Not enough C100 tokens in contract"
        );

        // Enforce per-user cap
        require(
            userPurchases[msg.sender] + c100Amount <= maxUserCap,
            "Exceeds max user cap"
        );

        // Update user purchase info
        lastPurchaseTime[msg.sender] = block.timestamp;
        userPurchases[msg.sender] += c100Amount;

        // Transfer payment from buyer to treasury
        tokenData.token.safeTransferFrom(msg.sender, treasury, paymentAmount);

        // Lock tokens in a vesting schedule
        vestings[msg.sender].push(
            VestingSchedule({
                amount: c100Amount,
                releaseTime: block.timestamp + vestingDuration
            })
        );

        // Increment total locked
        totalLockedTokens += c100Amount;

        emit TokenPurchased(msg.sender, paymentToken, paymentAmount, c100Amount);
    }

    /**
     * @notice Claim all vested C100 tokens for the caller that have passed their release time.
     */
    function claimTokens() external nonReentrant whenNotPaused {
        uint256 totalClaimable = 0;
        VestingSchedule[] storage schedules = vestings[msg.sender];

        for (uint256 i = 0; i < schedules.length; i++) {
            if (
                schedules[i].amount > 0 &&
                block.timestamp >= schedules[i].releaseTime
            ) {
                totalClaimable += schedules[i].amount;
                schedules[i].amount = 0; // Mark as claimed
            }
        }

        require(totalClaimable > 0, "No tokens to claim");

        // Decrement global locked count
        totalLockedTokens -= totalClaimable;

        // Transfer unlocked tokens
        c100Token.safeTransfer(msg.sender, totalClaimable);

        emit TokensClaimed(msg.sender, totalClaimable);
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
     *         "Unsold" = tokens currently in the contract minus totalLockedTokens.
     */
    function finalize() external onlyOwner icoEnded nonReentrant {
        require(!finalized, "Already finalized");
        finalized = true;

        uint256 contractBalance = c100Token.balanceOf(address(this));
        require(contractBalance > totalLockedTokens, "Nothing to burn");

        uint256 unsold = contractBalance - totalLockedTokens;
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
     * @notice Add a new allowed token for purchasing C100.
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
     * @notice Remove an allowed token from purchasing C100.
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
     * @notice Rescues tokens accidentally sent to the contract, excluding C100 and allowed payment tokens.
     * @param token Address of the token to rescue.
     * @param amount Amount of tokens to rescue.
     */
    function rescueTokens(address token, uint256 amount)
        external
        onlyOwner
    {
        require(token != address(c100Token), "Cannot rescue C100 tokens");
        require(!isAllowedToken[token], "Cannot rescue allowed payment tokens");
        require(token != address(0), "Zero address");

        IERC20(token).safeTransfer(treasury, amount);
        emit TokensRescued(token, amount);
    }

    /**
     * @notice Burn C100 tokens from the treasury (optional utility).
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
        c100Token.safeTransferFrom(
            treasury,
            address(0x000000000000000000000000000000000000dEaD),
            amount
        );
    }

    /**
     * @notice Pause the contract, disabling new purchases and claims.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract, enabling purchases and claims.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    // ---------------------------------------
    // Vesting/Delay/Cap Configuration
    // ---------------------------------------

    /**
     * @notice Update the vesting duration, purchase delay, and max user cap.  
     * @param _vestingDuration New vesting duration in seconds.
     * @param _purchaseDelay New delay between purchases in seconds.
     * @param _maxUserCap New maximum total C100 a user can purchase (base units).
     */
    function updateVestingConfig(
        uint256 _vestingDuration,
        uint256 _purchaseDelay,
        uint256 _maxUserCap
    ) external onlyOwner {
        require(_vestingDuration > 0, "Vesting must be > 0");
        require(_purchaseDelay <= 7 days, "Delay too large?");
        require(_maxUserCap > 0, "Max cap must be > 0");

        vestingDuration = _vestingDuration;
        purchaseDelay = _purchaseDelay;
        maxUserCap = _maxUserCap;

        emit VestingConfigUpdated(_vestingDuration, _purchaseDelay, _maxUserCap);
    }
}
