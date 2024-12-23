// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// OpenZeppelin Contracts
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title C100PublicSale
 * @notice A public sale contract for C100 tokens with a fixed rate.
 *
 * Features:
 * - Owned by the treasury.
 * - Presale duration of 12 months.
 * - Fixed rate: 1 C100 = 0.001 USDC (scaled by 1e18).
 * - Allows buying C100 with USDC only.
 * - Finalizes by burning unsold tokens.
 */
contract C100PublicSale is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    IERC20 public c100Token;
    IERC20 public usdcToken;
    address public treasury;

    uint256 public startTime;
    uint256 public endTime;
    bool public finalized;

    // 0.001 USDC per C100 (scaled by 1e18).
    uint256 public constant C100_PRICE_USDC = 1e15;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // Events
    event TokenPurchased(address indexed buyer, uint256 usdcAmount, uint256 c100Amount);
    event ICOParametersUpdated(uint256 newStart, uint256 newEnd);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event Finalized(uint256 unsoldTokensBurned);
    event TokensRescued(address indexed token, uint256 amount);
    event C100TokenUpdated(address oldC100, address newC100);
    event USDCUpdated(address oldUSDC, address newUSDC);
    event SaleInitialized(address c100Token, address usdcToken, address treasury, uint256 startTime, uint256 endTime);

    modifier onlyAdmin() {
        require(msg.sender == owner() || msg.sender == treasury, "Not admin");
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

    /**
     * @notice Constructor to initialize the public sale contract.
     * @param _c100Token Address of the C100 token contract.
     * @param _usdcToken Address of the USDC token contract.
     * @param _treasury Address of the treasury.
     * @param _startTime UNIX timestamp for ICO start.
     * @param _endTime UNIX timestamp for ICO end (12 months later).
     */
    constructor(
        address _c100Token,
        address _usdcToken,
        address _treasury,
        uint256 _startTime,
        uint256 _endTime
    )
        Ownable(_treasury)
        ReentrancyGuard()
        Pausable()
    {
        require(_c100Token != address(0), "C100 token zero address");
        require(_usdcToken != address(0), "USDC token zero address");
        require(_treasury != address(0), "Treasury zero address");
        require(_startTime < _endTime, "Invalid time range");

        c100Token = IERC20(_c100Token);
        usdcToken = IERC20(_usdcToken);
        treasury = _treasury;
        startTime = _startTime;
        endTime = _endTime;

        emit SaleInitialized(_c100Token, _usdcToken, _treasury, _startTime, _endTime);
    }

    /**
     * @notice Allows users to purchase C100 tokens with USDC at a fixed rate.
     * @param usdcAmount Amount of USDC to spend (with 6 decimals).
     */
    function buyWithUSDC(uint256 usdcAmount) external nonReentrant whenNotPaused icoActive {
        require(usdcAmount > 0, "USDC amount must be > 0");
        
        // USDC typically has 6 decimals. Scale it by 1e12 to align with C100's 18 decimals.
        uint256 scaledUsdcAmount = usdcAmount * 1e12;

        // c100Amount = (usdcSpent * 1e18) / price
        // price = 1e15 (which is 0.001 USDC in 1e18 scale)
        uint256 c100Amount = (scaledUsdcAmount * 1e18) / C100_PRICE_USDC;
        require(c100Token.balanceOf(address(this)) >= c100Amount, "Not enough C100 tokens");

        // Transfer USDC from buyer to treasury
        usdcToken.safeTransferFrom(msg.sender, treasury, usdcAmount);

        // Transfer C100 from this contract to buyer
        c100Token.safeTransfer(msg.sender, c100Amount);

        emit TokenPurchased(msg.sender, usdcAmount, c100Amount);
    }

    /**
     * @notice Finalizes the ICO by burning any unsold tokens.
     */
    function finalize() external onlyAdmin icoEnded nonReentrant {
        require(!finalized, "Already finalized");
        finalized = true;

        uint256 unsold = c100Token.balanceOf(address(this));
        if (unsold > 0) {
            c100Token.safeTransfer(BURN_ADDRESS, unsold);
        }

        emit Finalized(unsold);
    }

    /**
     * @notice Update ICO parameters before it starts.
     * @param newStart UNIX timestamp for new ICO start.
     * @param newEnd UNIX timestamp for new ICO end.
     */
    function updateICOParameters(uint256 newStart, uint256 newEnd) external onlyAdmin icoNotStarted {
        require(newStart < newEnd, "Invalid time range");
        startTime = newStart;
        endTime = newEnd;
        emit ICOParametersUpdated(newStart, newEnd);
    }

    /**
     * @notice Update the treasury address.
     */
    function updateTreasury(address newTreasury) external onlyAdmin {
        require(newTreasury != address(0), "Zero address");
        address old = treasury;
        treasury = newTreasury;
        emit TreasuryUpdated(old, newTreasury);
    }

    /**
     * @notice Update the C100 token address.
     */
    function updateC100Token(address newC100) external onlyAdmin {
        require(newC100 != address(0), "Zero address");
        address oldC100 = address(c100Token);
        c100Token = IERC20(newC100);
        emit C100TokenUpdated(oldC100, newC100);
    }

    /**
     * @notice Update the USDC token address.
     */
    function updateUSDC(address newUSDC) external onlyAdmin {
        require(newUSDC != address(0), "Zero address");
        address oldUSDC = address(usdcToken);
        usdcToken = IERC20(newUSDC);
        emit USDCUpdated(oldUSDC, newUSDC);
    }

    /**
     * @notice Rescue tokens accidentally sent to the contract.
     */
    function rescueTokens(address token, uint256 amount) external onlyAdmin {
        require(token != address(0), "Zero address");
        require(token != address(c100Token), "Cannot rescue C100 tokens");
        require(token != address(usdcToken), "Cannot rescue USDC during ICO");
        IERC20(token).safeTransfer(treasury, amount);
        emit TokensRescued(token, amount);
    }

    /**
     * @notice Burn C100 tokens from the treasury.
     * @param amount Amount of tokens to burn.
     */
    function burnFromTreasury(uint256 amount) external onlyAdmin nonReentrant {
        require(c100Token.balanceOf(treasury) >= amount, "Not enough tokens in treasury");
        // The treasury must approve this contract to spend the tokens.
        c100Token.safeTransferFrom(treasury, BURN_ADDRESS, amount);
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
}
