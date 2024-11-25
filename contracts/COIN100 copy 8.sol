// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Import OpenZeppelin Contracts
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Import Chainlink Contracts
import "@chainlink/contracts/src/v0.8/interfaces/ChainlinkRequestInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract COIN100 is ERC20, Ownable, ReentrancyGuard, ChainlinkClient, AutomationCompatibleInterface {
    using Chainlink for Chainlink.Request;

    // ============ State Variables ============

    // Wallet Addresses
    address public devWallet;
    address public liquidityWallet;

    // Fee Percentages
    uint256 public constant DEV_FEE_INITIAL = 5; // 5% initial allocation
    uint256 public constant LIQUIDITY_FEE_INITIAL = 5; // 5% initial allocation
    uint256 public constant TRANSACTION_FEE_PERCENTAGE = 3; // 3% on transactions

    // Transaction Fee Allocations
    uint256 public constant DEV_TRANSACTION_FEE = 1; // 1% to Dev
    uint256 public constant LIQUIDITY_TRANSACTION_FEE = 1; // 1% to Liquidity
    uint256 public constant BURN_TRANSACTION_FEE = 1; // 1% to Burn

    // Scaling Factor for Price Calculation (scaled by 1e6 for precision)
    uint256 public scalingFactor = 263; // Represents 0.000263

    // Total Market Cap of Top 100 Cryptocurrencies
    uint256 public totalMarketCap;

    // Chainlink Variables
    address private oracle;
    bytes32 private jobId;
    uint256 private fee; // LINK fee for the request

    // Token Price (for reference, not stored on-chain)
    uint256 public currentPrice; // Price in USD with 18 decimals

    // Events
    event MarketCapRequested(bytes32 indexed requestId);
    event MarketCapFulfilled(bytes32 indexed requestId, uint256 marketCap);
    event PriceUpdated(uint256 newPrice);
    event DevWalletUpdated(address newDevWallet);
    event LiquidityWalletUpdated(address newLiquidityWallet);
    event ScalingFactorUpdated(uint256 newScalingFactor);

    // ============ Constructor ============

    /**
     * @notice Initializes the COIN100 token with initial allocations and Chainlink configurations.
     * @param _devWallet Address of the Development Wallet
     * @param _liquidityWallet Address of the Liquidity Wallet
     * @param _link Token address for LINK on the respective network
     * @param _oracle Address of the Chainlink Oracle
     * @param _jobId Job ID for fetching and processing market cap data
     * @param _fee LINK fee required for the Chainlink request
     */
    constructor(
        address _devWallet,
        address _liquidityWallet,
        address _link,
        address _oracle,
        bytes32 _jobId,
        uint256 _fee
    ) ERC20("COIN100", "C100") {
        require(_devWallet != address(0), "Dev wallet cannot be zero address");
        require(_liquidityWallet != address(0), "Liquidity wallet cannot be zero address");

        devWallet = _devWallet;
        liquidityWallet = _liquidityWallet;

        // Initialize Chainlink
        setChainlinkToken(_link);
        oracle = _oracle;
        jobId = _jobId;
        fee = _fee;

        // Mint initial supply to the owner
        uint256 initialSupply = 10_000_000 * 10 ** decimals();
        _mint(msg.sender, initialSupply);

        // Allocate initial dev and liquidity fees
        uint256 devFee = (initialSupply * DEV_FEE_INITIAL) / 100; // 5%
        uint256 liquidityFee = (initialSupply * LIQUIDITY_FEE_INITIAL) / 100; // 5%
        _transfer(msg.sender, devWallet, devFee);
        _transfer(msg.sender, liquidityWallet, liquidityFee);

        // Initialize current price
        currentPrice = 0.01 * 10 ** 18; // Starting price $0.01 with 18 decimals
    }

    // ============ ERC20 Overrides ============

    /**
     * @notice Overrides the ERC20 _transfer function to include fee mechanisms.
     * @param sender Address sending the tokens
     * @param recipient Address receiving the tokens
     * @param amount Amount of tokens being transferred
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override nonReentrant {
        // Exclude owner from fees
        if (sender == owner() || recipient == owner()) {
            super._transfer(sender, recipient, amount);
            return;
        }

        // Calculate total fee
        uint256 feeAmount = (amount * TRANSACTION_FEE_PERCENTAGE) / 100; // 3%

        // Calculate individual fees
        uint256 devFee = (feeAmount * DEV_TRANSACTION_FEE) / TRANSACTION_FEE_PERCENTAGE; // 1%
        uint256 liquidityFee = (feeAmount * LIQUIDITY_TRANSACTION_FEE) / TRANSACTION_FEE_PERCENTAGE; // 1%
        uint256 burnFee = feeAmount - devFee - liquidityFee; // 1%

        // Transfer fees
        if (devFee > 0) {
            super._transfer(sender, devWallet, devFee);
        }
        if (liquidityFee > 0) {
            super._transfer(sender, liquidityWallet, liquidityFee);
        }
        if (burnFee > 0) {
            _burn(sender, burnFee);
        }

        // Transfer remaining amount
        uint256 transferAmount = amount - feeAmount;
        super._transfer(sender, recipient, transferAmount);
    }

    // ============ Chainlink Functions ============

    /**
     * @notice Initiates a Chainlink request to fetch the total market cap from CoinGecko.
     * @return requestId The unique ID of the Chainlink request
     */
    function requestMarketCapData() public onlyOwner returns (bytes32 requestId) {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfillMarketCap.selector);

        // Set the URL to perform the GET request on
        // The actual URL with query parameters should be handled by the Chainlink job
        request.add("get", "https://api.coingecko.com/api/v3/coins/markets");

        // Since CoinGecko requires query parameters, they should be configured in the Chainlink job
        // Alternatively, you can encode the full URL with query parameters if the Chainlink job allows it
        // Example: "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&page=1"

        // Set the path to extract totalMarketCap from the response
        // Assuming the Chainlink job sums the market_caps and returns it directly
        request.add("path", "total_market_cap");

        // Send the request
        requestId = sendChainlinkRequestTo(oracle, request, fee);
        emit MarketCapRequested(requestId);
    }

    /**
     * @notice Callback function called by Chainlink Oracle with the fetched market cap.
     * @param _requestId The unique ID of the Chainlink request
     * @param _marketCap The total market cap fetched from CoinGecko
     */
    function fulfillMarketCap(bytes32 _requestId, uint256 _marketCap) public recordChainlinkFulfillment(_requestId) {
        totalMarketCap = _marketCap;
        emit MarketCapFulfilled(_requestId, _marketCap);

        // Adjust the price based on the new market cap
        adjustPrice();
    }

    // ============ Price Adjustment Mechanism ============

    /**
     * @notice Adjusts the token price based on the total market cap and scaling factor.
     */
    function adjustPrice() internal {
        require(totalMarketCap > 0, "Total market cap is zero");

        // Calculate new price: (Total Market Cap / Total Supply) * Scaling Factor
        // To maintain precision, use fixed-point arithmetic with 18 decimals

        // (totalMarketCap * scalingFactor) / totalSupply
        // totalMarketCap is in USD with 18 decimals
        uint256 newPrice = (totalMarketCap * scalingFactor) / totalSupply();

        currentPrice = newPrice;
        emit PriceUpdated(newPrice);
    }

    // ============ Chainlink Automation (Keepers) Functions ============

    /**
     * @notice Checks if upkeep is needed. Here, it always returns true to perform upkeep hourly.
     * @param /* checkData */ Not used in this implementation
     * @return upkeepNeeded Indicates if upkeep is needed
     * @return performData Not used in this implementation
     */
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory performData) {
        // For simplicity, always return true. In a production scenario, implement time-based checks.
        upkeepNeeded = true;
        performData = "";
    }

    /**
     * @notice Performs upkeep by requesting new market cap data.
     * @param /* performData */ Not used in this implementation
     */
    function performUpkeep(bytes calldata /* performData */) external override {
        requestMarketCapData();
    }

    // ============ Owner Functions ============

    /**
     * @notice Updates the Development Wallet address.
     * @param _newDevWallet The new Development Wallet address
     */
    function updateDevWallet(address _newDevWallet) external onlyOwner {
        require(_newDevWallet != address(0), "New Dev wallet cannot be zero address");
        devWallet = _newDevWallet;
        emit DevWalletUpdated(_newDevWallet);
    }

    /**
     * @notice Updates the Liquidity Wallet address.
     * @param _newLiquidityWallet The new Liquidity Wallet address
     */
    function updateLiquidityWallet(address _newLiquidityWallet) external onlyOwner {
        require(_newLiquidityWallet != address(0), "New Liquidity wallet cannot be zero address");
        liquidityWallet = _newLiquidityWallet;
        emit LiquidityWalletUpdated(_newLiquidityWallet);
    }

    /**
     * @notice Updates the scaling factor used in price calculation.
     * @param _newScalingFactor The new scaling factor (scaled by 1e6)
     */
    function updateScalingFactor(uint256 _newScalingFactor) external onlyOwner {
        scalingFactor = _newScalingFactor;
        emit ScalingFactorUpdated(_newScalingFactor);
    }

    /**
     * @notice Updates Chainlink Oracle details.
     * @param _oracle The new Oracle address
     * @param _jobId The new Job ID
     * @param _fee The new fee in LINK
     */
    function updateChainlinkDetails(address _oracle, bytes32 _jobId, uint256 _fee) external onlyOwner {
        oracle = _oracle;
        jobId = _jobId;
        fee = _fee;
    }

    /**
     * @notice Withdraws LINK tokens from the contract. Useful if you need to retrieve excess LINK.
     * @param _to The address to send the LINK tokens to
     * @param _amount The amount of LINK to withdraw
     */
    function withdrawLink(address _to, uint256 _amount) external onlyOwner {
        require(LinkTokenInterface(chainlinkTokenAddress()).transfer(_to, _amount), "Unable to transfer");
    }

    // ============ Fallback and Receive ============

    receive() external payable {}
    fallback() external payable {}
}
