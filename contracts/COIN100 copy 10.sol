// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import Statements
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

/**
 * @title COIN100 (C100) Token
 * @dev A decentralized cryptocurrency index fund tracking the top 100 cryptocurrencies by market capitalization.
 */
contract COIN100 is ERC20, Ownable, ReentrancyGuard, AutomationCompatibleInterface, ChainlinkClient {
    using Chainlink for Chainlink.Request;

    // =======================
    // ======= EVENTS ========
    // =======================
    event PriceAdjusted(uint256 newMarketCap, uint256 timestamp);
    event TokensBurned(uint256 amount);
    event TokensMinted(uint256 amount);

    // =======================
    // ======= STATE =========
    // =======================
    uint256 public constant INITIAL_PRICE = 1e16; // $0.01 with 18 decimals
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 1e18; // 1 billion tokens with 18 decimals
    uint256 public lastMarketCap;
    uint256 public feePercent = 3; // 3% fee on transactions
    uint256 public constant SCALING_FACTOR = 380000;

    address public developerWallet;
    address public liquidityWallet;

    // Chainlink Variables
    bytes32 private jobId;
    uint256 private fee;

    /**
     * @dev Constructor that initializes the token, mints initial allocations, and sets up Chainlink.
     * @param _developerWallet Address of the developer wallet.
     * @param _liquidityWallet Address of the liquidity wallet.
     */
    constructor(address _developerWallet, address _liquidityWallet) ERC20("COIN100", "C100") {
        require(_developerWallet != address(0), "Invalid developer wallet");
        require(_liquidityWallet != address(0), "Invalid liquidity wallet");

        developerWallet = _developerWallet;
        liquidityWallet = _liquidityWallet;

        // Mint allocations
        _mint(msg.sender, (TOTAL_SUPPLY * 70) / 100); // 70% Public Sale
        _mint(developerWallet, (TOTAL_SUPPLY * 5) / 100); // 5% Developer
        _mint(liquidityWallet, (TOTAL_SUPPLY * 5) / 100); // 5% Liquidity
        _mint(address(this), (TOTAL_SUPPLY * 10) / 100); // 10% Reserve

        // Initial Burn of 10% Reserve
        _burn(address(this), (TOTAL_SUPPLY * 10) / 100); // Burn 10% Reserve

        // Initialize Chainlink
        setPublicChainlinkToken();
        jobId = "JOB_ID"; // Replace with actual Job ID from Chainlink
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Adjust based on network and job requirements)
    }

    /**
     * @dev Overrides the ERC20 _transfer function to include transaction fees.
     * @param sender Address sending the tokens.
     * @param recipient Address receiving the tokens.
     * @param amount Amount of tokens being transferred.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        uint256 feeAmount = (amount * feePercent) / 100;
        uint256 transferAmount = amount - feeAmount;

        // Distribute fees
        super._transfer(sender, developerWallet, feeAmount / 3); // 1% to Developer
        super._transfer(sender, liquidityWallet, feeAmount / 3); // 1% to Liquidity
        super._transfer(sender, address(0), feeAmount / 3); // 1% Burn

        // Transfer remaining tokens to recipient
        super._transfer(sender, recipient, transferAmount);
    }

    /**
     * @dev Chainlink Automation checkUpkeep function. Always returns true to perform upkeep hourly.
     * @param checkData Not used in this implementation.
     * @return upkeepNeeded Always true.
     * @return performData Empty bytes.
     */
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = true; // Always perform upkeep
        performData = "";
    }

    /**
     * @dev Chainlink Automation performUpkeep function. Initiates the market cap data request.
     * @param performData Not used in this implementation.
     */
    function performUpkeep(bytes calldata /* performData */) external override {
        _requestMarketCapData();
    }

    /**
     * @dev Builds and sends a Chainlink request to fetch the total market cap of the top 100 cryptocurrencies.
     */
    function _requestMarketCapData() internal {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfillMarketCap.selector);
        
        // Set the URL to fetch
        request.add("get", "https://api.coingecko.com/api/v3/coins/markets");
        
        // Add query parameters
        request.add("qs", "vs_currency=usd&order=market_cap_desc&per_page=100&page=1");
        
        // Set the path to extract and sum the market caps
        request.add("path", "sum.market_cap"); // Custom parsing required in the Chainlink Job
        
        // Send the Chainlink request
        sendChainlinkRequest(request, fee);
    }

    /**
     * @dev Callback function used by Chainlink to fulfill the market cap data request.
     * @param _requestId The ID of the request.
     * @param _marketCap The total market cap of the top 100 cryptocurrencies.
     */
    function fulfillMarketCap(bytes32 _requestId, uint256 _marketCap) public recordChainlinkFulfillment(_requestId) {
        require(_marketCap > 0, "Invalid market cap data");
        _adjustPrice(_marketCap);
        emit PriceAdjusted(_marketCap, block.timestamp);
    }

    /**
     * @dev Adjusts the token supply based on the new market cap.
     * @param _newMarketCap The latest total market cap of the top 100 cryptocurrencies.
     */
    function _adjustPrice(uint256 _newMarketCap) internal nonReentrant {
        uint256 targetC100MarketCap = _newMarketCap / SCALING_FACTOR;
        uint256 currentC100MarketCap = (totalSupply() * INITIAL_PRICE) / 1e18; // Calculate current market cap

        // Calculate Price Adjustment Factor (PAF) with 18 decimals precision
        uint256 paf = (targetC100MarketCap * 1e18) / currentC100MarketCap;

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

        // Update the lastMarketCap
        lastMarketCap = _newMarketCap;
    }

    // =======================
    // ====== ADMIN ==========
    // =======================

    /**
     * @dev Updates the developer wallet address.
     * @param _newDevWallet The new developer wallet address.
     */
    function setDeveloperWallet(address _newDevWallet) external onlyOwner {
        require(_newDevWallet != address(0), "Invalid address");
        developerWallet = _newDevWallet;
    }

    /**
     * @dev Updates the liquidity wallet address.
     * @param _newLiquidityWallet The new liquidity wallet address.
     */
    function setLiquidityWallet(address _newLiquidityWallet) external onlyOwner {
        require(_newLiquidityWallet != address(0), "Invalid address");
        liquidityWallet = _newLiquidityWallet;
    }

    /**
     * @dev Updates the transaction fee percentage.
     * @param _newFee The new fee percentage (max 5%).
     */
    function setFeePercent(uint256 _newFee) external onlyOwner {
        require(_newFee <= 5, "Fee too high"); // Maximum 5%
        feePercent = _newFee;
    }

    /**
     * @dev Withdraws LINK tokens from the contract.
     */
    function withdrawLink() external onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }

    // =======================
    // ====== UTILITIES =======
    // =======================

    /**
     * @dev Allows the owner to update the Chainlink job ID.
     * @param _jobId The new Chainlink job ID.
     */
    function setJobId(bytes32 _jobId) external onlyOwner {
        jobId = _jobId;
    }

    /**
     * @dev Allows the owner to update the Chainlink fee.
     * @param _fee The new fee in LINK tokens.
     */
    function setChainlinkFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    /**
     * @dev Retrieves the current Chainlink job ID.
     * @return The current job ID.
     */
    function getJobId() external view returns (bytes32) {
        return jobId;
    }

    /**
     * @dev Retrieves the current Chainlink fee.
     * @return The current fee.
     */
    function getChainlinkFee() external view returns (uint256) {
        return fee;
    }
}
