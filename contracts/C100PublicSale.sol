// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title C100PublicSale
 * @notice A public sale contract for C100 tokens.
 *
 * Changes requested:
 * - Ability to set C100 token address and treasury after deployment.
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
    event C100TokenUpdated(address oldToken, address newToken);

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
        polRate = initialPolRate; // assumed scaled by 1e18 externally; if not, adjust as needed
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
        // c100Amount = (msg.value * polRate) / 1e18
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

        // c100Amount = (tokenAmount * rate) / 1e18
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

    // New: Ability to set C100 Token after deployment
    function setC100TokenAddress(address newToken) external onlyAdmin {
        require(newToken != address(0), "Zero");
        address old = address(c100Token);
        c100Token = IERC20(newToken);
        emit C100TokenUpdated(old, newToken);
    }

    function rescueTokens(address token) external onlyAdmin {
        require(token != address(0), "Zero");
        if (token == address(c100Token) && !finalized) {
            // Prevent rescuing C100 before finalize to ensure fair sale
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
