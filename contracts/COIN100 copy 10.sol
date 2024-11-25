// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import Statements
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract COIN100 is ERC20, Ownable, ReentrancyGuard, AutomationCompatibleInterface, ChainlinkClient {
    using Chainlink for Chainlink.Request;

    // State Variables
    uint256 public constant INITIAL_PRICE = 1e16; // 0.01 ETH (assuming using ETH, adjust decimals accordingly)
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 10**18; // 1 billion tokens with 18 decimals
    uint256 public lastMarketCap;
    uint256 public feePercent = 3; // 3% fee on transactions
    uint256 public constant SCALING_FACTOR = 380000;

    address public developerWallet;
    address public liquidityWallet;

    // Chainlink Variables
    bytes32 private jobId;
    uint256 private fee;

    // Events
    event PriceAdjusted(uint256 newMarketCap, uint256 timestamp);
    event TokensBurned(uint256 amount);
    event TokensMinted(uint256 amount);

    constructor(address _developerWallet, address _liquidityWallet) ERC20("COIN100", "C100") {
        require(_developerWallet != address(0), "Invalid developer wallet");
        require(_liquidityWallet != address(0), "Invalid liquidity wallet");

        developerWallet = _developerWallet;
        liquidityWallet = _liquidityWallet;

        _mint(msg.sender, TOTAL_SUPPLY * 70 / 100); // Public Sale
        _mint(developerWallet, TOTAL_SUPPLY * 5 / 100);
        _mint(liquidityWallet, TOTAL_SUPPLY * 5 / 100);
        _mint(address(this), TOTAL_SUPPLY * 10 / 100); // Reserve
        _burn(address(this), TOTAL_SUPPLY * 10 / 100); // Initial Burn

        // Initialize Chainlink
        setPublicChainlinkToken();
        jobId = "JOB_ID"; // Replace with actual Job ID
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network and job)
    }

    // Override Transfer to include fees
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        uint256 feeAmount = (amount * feePercent) / 100;
        uint256 transferAmount = amount - feeAmount;

        super._transfer(sender, developerWallet, feeAmount / 3); // 1% to Developer
        super._transfer(sender, liquidityWallet, feeAmount / 3); // 1% to Liquidity
        super._transfer(sender, address(0), feeAmount / 3); // 1% Burn

        super._transfer(sender, recipient, transferAmount);
    }

    // Chainlink Automation: checkUpkeep
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = true; // For simplicity, always perform upkeep hourly
        performData = "";
    }

    // Chainlink Automation: performUpkeep
    function performUpkeep(bytes calldata /* performData */) external override {
        _requestMarketCapData();
    }

    // Request Market Cap Data from Chainlink
    function _requestMarketCapData() internal {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfillMarketCap.selector);
        // Set the URL to fetch
        request.add("get", "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&page=1");
        // Set the path to extract total market cap
        request.add("path", "sum.market_cap"); // This is illustrative; actual parsing may require custom handling
        sendChainlinkRequest(request, fee);
    }

    // Fulfill Market Cap Data
    function fulfillMarketCap(bytes32 _requestId, uint256 _marketCap) public recordChainlinkFulfillment(_requestId) {
        require(_marketCap > 0, "Invalid market cap data");
        _adjustPrice(_marketCap);
        emit PriceAdjusted(_marketCap, block.timestamp);
    }

    // Adjust Price Based on Market Cap
    function _adjustPrice(uint256 _newMarketCap) internal nonReentrant {
        uint256 targetC100MarketCap = _newMarketCap / SCALING_FACTOR;
        uint256 currentC100MarketCap = totalSupply() * INITIAL_PRICE / 1e18; // Adjust based on decimals

        uint256 paf = (targetC100MarketCap * 1e18) / currentC100MarketCap; // Precision handling

        if (paf > 1e18) {
            // Market Cap Increased - Mint tokens to increase supply
            uint256 mintAmount = (totalSupply() * (paf - 1e18)) / 1e18;
            _mint(address(this), mintAmount);
            emit TokensMinted(mintAmount);
        } else if (paf < 1e18) {
            // Market Cap Decreased - Burn tokens to decrease supply
            uint256 burnAmount = (totalSupply() * (1e18 - paf)) / 1e18;
            _burn(address(this), burnAmount);
            emit TokensBurned(burnAmount);
        }

        // Update lastMarketCap
        lastMarketCap = _newMarketCap;
    }

    // Admin Functions
    function setDeveloperWallet(address _newDevWallet) external onlyOwner {
        require(_newDevWallet != address(0), "Invalid address");
        developerWallet = _newDevWallet;
    }

    function setLiquidityWallet(address _newLiquidityWallet) external onlyOwner {
        require(_newLiquidityWallet != address(0), "Invalid address");
        liquidityWallet = _newLiquidityWallet;
    }

    function setFeePercent(uint256 _newFee) external onlyOwner {
        require(_newFee <= 5, "Fee too high"); // Max 5%
        feePercent = _newFee;
    }

    // Emergency Pause Functionality (Optional)
    // Implement Pausable from OpenZeppelin if needed

    // Withdraw LINK (in case of excess)
    function withdrawLink() external onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }
}
