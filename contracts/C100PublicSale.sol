// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title C100PublicSale
 * @notice This contract handles the public ICO for COIN100 (C100) tokens.
 *         It sells C100 tokens for POL and optionally other ERC20 tokens (like USDC).
 * 
 * Key Features:
 * - The owner deploys this after deploying C100 token contract.
 * - Owner transfers 97% of C100 supply to this contract for sale.
 * - Investors buy C100 with POL or approved ERC20 tokens at a fixed rate.
 * - ICO runs for a set duration (start and end time).
 * - At the end of ICO, admin calls finalize() to burn unsold tokens.
 * - Future governance: After setting govContract, both owner and govContract share admin rights.
 * - Admin functions allow updating sale parameters, accepted tokens, rates, and pausing the sale.
 *
 * Additional functionality:
 * - Admin can rescue any accidental ERC20 tokens sent here (except for C100 before finalize) by transferring them to the treasury.
 *
 * Assumptions:
 * - The C100 token contract does not have a direct burn function by sending to address(0). 
 *   We will send unsold tokens to a known burn address (e.g., 0x...dEaD) at finalize.
 * - Ensure that the C100 token contract is already deployed and approved for these operations.
 * - Rates are set in terms of "C100 per 1 unit of payment token".
 */
contract C100PublicSale is Ownable, ReentrancyGuard, Pausable {
    // ---------------------------------------
    // Core parameters
    // ---------------------------------------
    IERC20 public c100Token;               // The C100 token being sold
    address public govContract;            // Governor contract, once set
    address public treasury;               // Address where raised funds are held (e.g., the owner's address)
    
    uint256 public startTime;              // ICO start time (unix timestamp)
    uint256 public endTime;                // ICO end time (unix timestamp)
    bool public finalized;                 // Whether the ICO has been finalized
    
    // Rates and Accepted Tokens
    uint256 public polRate;              // How many C100 per 1 POL
    mapping(address => uint256) public erc20Rates; // token -> C100 per 1 token of that ERC20

    // Constants
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // ---------------------------------------
    // Events
    // ---------------------------------------
    event GovernorContractSet(address indexed oldGovernor, address indexed newGovernor);
    event TokenPurchased(address indexed buyer, address indexed paymentToken, uint256 paymentAmount, uint256 c100Amount);
    event RatesUpdated(uint256 newPolRate);
    event Erc20RateUpdated(address indexed token, uint256 newRate);
    event ICOParametersUpdated(uint256 newStart, uint256 newEnd);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event Finalized(uint256 unsoldTokensBurned);
    event TokensRescued(address indexed token, uint256 amount);

    // ---------------------------------------
    // Modifiers
    // ---------------------------------------
    modifier onlyAdmin() {
        require(
            msg.sender == owner() || 
            (govContract != address(0) && msg.sender == govContract),
            "Not admin"
        );
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

    // ---------------------------------------
    // Constructor
    // ---------------------------------------
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
        require(c100TokenAddress != address(0), "C100 token zero");
        require(initialTreasury != address(0), "Treasury zero");
        require(initialStartTime < initialEndTime, "Invalid time range");
        require(initialPolRate > 0, "Rate must be > 0");

        c100Token = IERC20(c100TokenAddress);
        treasury = initialTreasury;
        startTime = initialStartTime;
        endTime = initialEndTime;
        polRate = initialPolRate;
    }

    // ---------------------------------------
    // Purchasing Functions
    // ---------------------------------------
    /**
     * @notice Buy C100 with POL.
     */
    function buyWithPOL() external payable nonReentrant whenNotPaused icoActive {
        require(msg.value > 0, "No POL sent");
        uint256 c100Amount = msg.value * polRate;
        _deliverTokens(msg.sender, c100Amount);
        _forwardFunds(msg.value); // POL directly goes to treasury
        emit TokenPurchased(msg.sender, address(0), msg.value, c100Amount);
    }

    /**
     * @notice Buy C100 with an approved ERC20 token.
     * @param token The ERC20 token address used to pay.
     * @param tokenAmount The amount of that ERC20 sent.
     */
    function buyWithToken(address token, uint256 tokenAmount) external nonReentrant whenNotPaused icoActive {
        require(token != address(0), "Token zero");
        uint256 rate = erc20Rates[token];
        require(rate > 0, "Token not accepted");
        require(tokenAmount > 0, "No tokens sent");

        uint256 c100Amount = tokenAmount * rate;
        require(IERC20(token).transferFrom(msg.sender, treasury, tokenAmount), "Transfer failed");
        _deliverTokens(msg.sender, c100Amount);
        emit TokenPurchased(msg.sender, token, tokenAmount, c100Amount);
    }

    // ---------------------------------------
    // Finalization
    // ---------------------------------------
    /**
     * @notice Finalize the ICO after it ends. Burns unsold C100 tokens.
     */
    function finalize() external onlyAdmin icoEnded nonReentrant {
        require(!finalized, "Already finalized");
        finalized = true;

        uint256 unsold = c100Token.balanceOf(address(this));
        if (unsold > 0) {
            // Burn unsold tokens by sending to BURN_ADDRESS
            require(c100Token.transfer(BURN_ADDRESS, unsold), "Burn transfer failed");
        }
        emit Finalized(unsold);
    }

    // ---------------------------------------
    // Admin Functions
    // ---------------------------------------
    /**
     * @notice Set the governor contract address. Once set, both owner and govContract share admin rights.
     * @param _govContract The governor contract address.
     */
    function setGovernorContract(address _govContract) external onlyOwner {
        address oldGov = govContract;
        govContract = _govContract;
        emit GovernorContractSet(oldGov, _govContract);
    }

    /**
     * @notice Pause the contract in case of emergency.
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
     * @notice Update the POL rate.
     * @param newRate The new C100 per POL rate.
     */
    function updatePOLRate(uint256 newRate) external onlyAdmin icoNotStarted {
        require(newRate > 0, "Rate must be > 0");
        polRate = newRate;
        emit RatesUpdated(newRate);
    }

    /**
     * @notice Update or add an ERC20 token rate.
     * @param token The ERC20 token address.
     * @param newRate The new C100 per token rate.
     */
    function updateErc20Rate(address token, uint256 newRate) external onlyAdmin icoNotStarted {
        require(token != address(0), "Token zero");
        require(newRate > 0, "Rate must be > 0");
        erc20Rates[token] = newRate;
        emit Erc20RateUpdated(token, newRate);
    }

    /**
     * @notice Update ICO parameters (start and end time) before it starts.
     * @param newStart The new start time.
     * @param newEnd The new end time.
     */
    function updateICOParameters(uint256 newStart, uint256 newEnd) external onlyAdmin icoNotStarted {
        require(newStart < newEnd, "Invalid time range");
        startTime = newStart;
        endTime = newEnd;
        emit ICOParametersUpdated(newStart, newEnd);
    }

    /**
     * @notice Update the treasury address.
     * @param newTreasury The new treasury address.
     */
    function updateTreasury(address newTreasury) external onlyAdmin {
        require(newTreasury != address(0), "Treasury zero");
        address old = treasury;
        treasury = newTreasury;
        emit TreasuryUpdated(old, newTreasury);
    }

    /**
     * @notice Rescue any accidental ERC20 tokens sent to this contract (except C100 before finalize).
     * @param token The ERC20 token address to rescue.
     */
    function rescueTokens(address token) external onlyAdmin {
        require(token != address(0), "Token zero");
        // If token is C100 and ICO not finalized, do not allow rescue (can't withdraw sale tokens)
        if (token == address(c100Token) && !finalized) {
            revert("Cannot rescue C100 before finalize");
        }

        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            require(IERC20(token).transfer(treasury, balance), "Rescue transfer failed");
            emit TokensRescued(token, balance);
        }
    }

    /**
     * @notice Admin can burn tokens from treasury, reducing supply. This is the "occasional reduction in supply".
     * @param amount The amount of tokens to burn from treasury.
     */
    function burnFromTreasury(uint256 amount) external onlyAdmin nonReentrant {
        require(c100Token.balanceOf(treasury) >= amount, "Not enough tokens in treasury");
        require(c100Token.transfer(BURN_ADDRESS, amount), "Burn transfer failed");
        emit Transfer(treasury, BURN_ADDRESS, amount);
    }

    // ---------------------------------------
    // Internal Helpers
    // ---------------------------------------
    /**
     * @notice Deliver C100 tokens to the buyer.
     * @param recipient The address receiving the C100 tokens.
     * @param amount The amount of C100 tokens to deliver.
     */
    function _deliverTokens(address recipient, uint256 amount) internal {
        require(c100Token.balanceOf(address(this)) >= amount, "Not enough C100");
        require(c100Token.transfer(recipient, amount), "C100 transfer failed");
    }

    /**
     * @notice Forward POL funds to the treasury.
     * @param amount The amount of POL to forward.
     */
    function _forwardFunds(uint256 amount) internal {
        (bool success, ) = treasury.call{value: amount}("");
        require(success, "Forwarding POL failed");
    }

    // ---------------------------------------
    // Fallback Functions
    // ---------------------------------------
    receive() external payable {
        // Allows receiving POL for buyWithPOL()
        // Any direct sends not via buyWithPOL() are accepted but won't get tokens.
        // It's recommended to always call buyWithPOL().
    }

    fallback() external payable {
        revert("No ETH");
    }

    // ---------------------------------------
    // ERC20 Transfer Event
    // ---------------------------------------
    // To emit Transfer events when burning tokens via burnFromTreasury
    event Transfer(address indexed from, address indexed to, uint256 amount);
}
