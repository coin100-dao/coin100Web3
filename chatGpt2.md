// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import OpenZeppelin Contracts
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Import Chainlink Functions Contracts
import { FunctionsClient } from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import { FunctionsRequest } from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

// Import Chainlink Automation Contracts
import { AutomationCompatibleInterface } from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

// Import Uniswap V2 Interfaces
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/**
 * @title COIN100 (C100) Token
 * @dev A decentralized cryptocurrency index fund tracking the top 100 cryptocurrencies by market capitalization.
 */
contract COIN100 is ERC20, Ownable, Pausable, ReentrancyGuard, FunctionsClient, AutomationCompatibleInterface {
    using FunctionsRequest for FunctionsRequest.Request;

    // =======================
    // ======= EVENTS ========
    // =======================
    event PriceAdjusted(uint256 newMarketCap, uint256 timestamp);
    event TokensBurned(uint256 amount);
    event TokensMinted(uint256 amount);
    event FeesUpdated(uint256 developerFee, uint256 liquidityFee, uint256 burnFee);
    event WalletsUpdated(address developerWallet, address liquidityWallet);
    event RebaseIntervalUpdated(uint256 newInterval);
    event UpkeepPerformed(bytes performData);
    event FunctionsRequestSent(bytes32 indexed requestId);
    event FunctionsRequestFulfilled(bytes32 indexed requestId, uint256 newMarketCap);
    event FunctionsRequestFailed(bytes32 indexed requestId, string reason);
    event TokensPurchased(address indexed buyer, uint256 amount, uint256 cost);

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

    // Transaction fee percentages (in basis points)
    uint256 public developerFee = 100; // 1%
    uint256 public liquidityFee = 100; // 1%
    uint256 public burnFee = 100; // 1%
    uint256 public constant FEE_DIVISOR = 10000;

    // Chainlink Functions Configuration
    address public constant FUNCTIONS_ROUTER_ADDRESS = 0xC22a79eBA640940ABB6dF0f7982cc119578E11De; // Chainlink Functions Router Address on Polygon
    bytes32 public constant DON_ID = 0x66756e2d706f6c79676f6e2d616d6f792d310000000000000000000000000000; // DON ID: fun-polygon-amoy-1

    // Subscription ID for Chainlink Functions
    uint64 public subscriptionId;

    // Chainlink Automation Configuration
    uint256 public lastRebaseTime;
    uint256 public rebaseInterval = 1 hours;

    // Initial Market Cap for scaling (assumed initial top 100 market cap at deployment)
    uint256 public initialMarketCap = 3_800_000_000_000; // 3.8 Trillion USD

    // Public Sale Parameters
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    uint256 public tokenPrice; // Price in wei per C100 token
    uint256 public tokensSold;

    // Sale Allocation
    uint256 public constant PUBLIC_SALE_ALLOCATION = (TOTAL_SUPPLY * 70) / 100;

    // Uniswap
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    /**
     * @dev Constructor that initializes the token, mints initial allocations, and sets up Chainlink Functions.
     * @param _developerWallet Address of the developer wallet.
     * @param _liquidityWallet Address of the liquidity wallet.
     * @param _subscriptionId Chainlink subscription ID.
     */
    constructor(
        address _developerWallet,
        address _liquidityWallet,
        uint64 _subscriptionId
    )
        ERC20("COIN100", "C100")
        Ownable()
        FunctionsClient(FUNCTIONS_ROUTER_ADDRESS)
    {
        require(_developerWallet != address(0), "Invalid developer wallet");
        require(_liquidityWallet != address(0), "Invalid liquidity wallet");

        developerWallet = _developerWallet;
        liquidityWallet = _liquidityWallet;
        subscriptionId = _subscriptionId;

        // Mint allocations
        _mint(msg.sender, (TOTAL_SUPPLY * 75) / 100); // 75% Public Sale
        _mint(developerWallet, (TOTAL_SUPPLY * 5) / 100); // 5% Developer
        _mint(liquidityWallet, (TOTAL_SUPPLY * 20) / 100); // 20% Liquidity

        // Initialize rebasing timestamp
        lastRebaseTime = block.timestamp;

        // Initialize Uniswap V2 Router
        uniswapV2Router = IUniswapV2Router02(0xedf6066a2b290C185783862C7F4776A2C8077AD1);
        
        // Create a Uniswap pair for this token
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        
        // Approve the router to spend tokens
        _approve(address(this), address(uniswapV2Router), TOTAL_SUPPLY);
    }


    // =======================
    // ====== ERC20 OVERRIDES ==
    // =======================

    /**
     * @dev Overrides the ERC20 _transfer function to include fee logic.
     * @param sender Address sending the tokens.
     * @param recipient Address receiving the tokens.
     * @param amount Amount of tokens being transferred.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override whenNotPaused {
        // If sender or recipient is the owner, transfer without fees
        if (sender == owner() || recipient == owner()) {
            super._transfer(sender, recipient, amount);
        } else {
            uint256 feeAmount = (amount * feePercent) / 100;
            uint256 transferAmount = amount - feeAmount;

            // Calculate individual fees
            uint256 devFeeAmount = (amount * developerFee) / FEE_DIVISOR;
            uint256 liqFeeAmount = (amount * liquidityFee) / FEE_DIVISOR;
            uint256 burnFeeAmount = (amount * burnFee) / FEE_DIVISOR;

            // Transfer fees to respective wallets
            super._transfer(sender, developerWallet, devFeeAmount); // 1% to Developer
            super._transfer(sender, liquidityWallet, liqFeeAmount); // 1% to Liquidity
            super._transfer(sender, address(0), burnFeeAmount); // 1% Burn

            // Transfer remaining tokens to recipient
            super._transfer(sender, recipient, transferAmount);
        }
    }

    // =======================
    // ====== FUNCTIONS =======
    // =======================

    /**
     * @dev Initializes the public sale parameters.
     * @param _saleStartTime Timestamp when the sale starts.
     * @param _saleEndTime Timestamp when the sale ends.
     * @param _tokenPrice Price per C100 token in wei.
     */
    function initializePublicSale(
        uint256 _saleStartTime,
        uint256 _saleEndTime,
        uint256 _tokenPrice
    ) external onlyOwner {
        require(_saleStartTime < _saleEndTime, "Invalid sale duration");
        require(_saleStartTime > block.timestamp, "Sale start must be in the future");
        saleStartTime = _saleStartTime;
        saleEndTime = _saleEndTime;
        tokenPrice = _tokenPrice;
    }

    /**
     * @dev Allows users to purchase C100 tokens during the public sale.
     */
    function buyTokens() external payable nonReentrant whenNotPaused {
        require(block.timestamp >= saleStartTime, "Sale has not started");
        require(block.timestamp <= saleEndTime, "Sale has ended");
        require(msg.value > 0, "Must send ETH to buy tokens");

        uint256 tokensToBuy = (msg.value * 1e18) / tokenPrice; // Adjust decimals
        require(tokensSold + tokensToBuy <= PUBLIC_SALE_ALLOCATION, "Not enough tokens left for sale");

        tokensSold += tokensToBuy;
        _transfer(owner(), msg.sender, tokensToBuy);

        emit TokensPurchased(msg.sender, tokensToBuy, msg.value);
    }

    /**
     * @dev Allows the owner to withdraw collected funds after the sale ends.
     */
    function withdrawFunds() external onlyOwner {
        require(block.timestamp > saleEndTime, "Sale not yet ended");
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev Initiates a Chainlink Functions request to fetch the total market cap of the top 100 cryptocurrencies.
     */
    function requestMarketCapData() public onlyOwner {
        // JavaScript code to fetch total market cap
        string memory source = string(
            abi.encodePacked(
                "async function run(request) {",
                "  const response = await fetch('https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&page=1');",
                "  const data = await response.json();",
                "  let totalMarketCap = 0;",
                "  for (const coin of data) {",
                "    totalMarketCap += coin.market_cap;",
                "  }",
                "  return totalMarketCap.toString();",
                "}"
            )
        );

        // Initialize a new FunctionsRequest
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source);

        // Encode the request
        bytes memory encodedRequest = req.encodeCBOR();

        // Send the request using the internal _sendRequest method
        bytes32 requestId = _sendRequest(
            encodedRequest,
            subscriptionId,
            300000, // gas limit
            DON_ID
        );

        emit FunctionsRequestSent(requestId);
    }

    /**
     * @dev Callback function for Chainlink Functions to fulfill the request.
     * @param requestId The request ID.
     * @param response The response from the Chainlink Function.
     * @param err The error, if any.
     */
    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (response.length > 0) {
            // Parse the response to uint256
            uint256 fetchedMarketCap = parseInt(string(response));
            totalMarketCap = fetchedMarketCap;

            // Adjust the token supply based on the fetched market cap
            adjustSupply(fetchedMarketCap);

            emit FunctionsRequestFulfilled(requestId, fetchedMarketCap);
        } else {
            // Handle the error
            emit FunctionsRequestFailed(requestId, string(err));
        }
    }

    /**
     * @dev Adjusts the token supply based on the latest market cap data.
     * @param fetchedMarketCap The latest total market cap in USD.
     *
     * Logic:
     * - Calculate the desired total supply based on the fetched market cap.
     * - Mint or burn tokens to match the desired supply.
     * - Example: If market cap increases, mint tokens; if it decreases, burn tokens.
     */
    function adjustSupply(uint256 fetchedMarketCap) internal nonReentrant {
        // Calculate the target C100 market cap based on scaling factor
        uint256 targetC100MarketCap = fetchedMarketCap / SCALING_FACTOR;
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
        lastMarketCap = fetchedMarketCap;

        // Emit PriceAdjusted event
        emit PriceAdjusted(fetchedMarketCap, block.timestamp);
    }

    /**
     * @dev Parses a string to a uint256. Assumes the string is a valid number.
     * @param _a The string to parse.
     * @return _parsed The parsed uint256.
     */
    function parseInt(string memory _a) internal pure returns (uint256 _parsed) {
        bytes memory bresult = bytes(_a);
        uint256 result = 0;
        for (uint256 i = 0; i < bresult.length; i++) {
            if (uint8(bresult[i]) >= 48 && uint8(bresult[i]) <= 57) {
                result = result * 10 + (uint8(bresult[i]) - 48);
            }
        }
        return result;
    }

    // =======================
    // ====== ADMIN ==========
    // =======================

    /**
     * @dev Allows the owner to update transaction fees.
     * @param _developerFee New developer fee in basis points.
     * @param _liquidityFee New liquidity fee in basis points.
     * @param _burnFee New burn fee in basis points.
     */
    function updateFees(uint256 _developerFee, uint256 _liquidityFee, uint256 _burnFee) external onlyOwner {
        require(_developerFee + _liquidityFee + _burnFee <= 300, "Total fees cannot exceed 3%");
        developerFee = _developerFee;
        liquidityFee = _liquidityFee;
        burnFee = _burnFee;
        emit FeesUpdated(_developerFee, _liquidityFee, _burnFee);
    }

    /**
     * @dev Allows the owner to update wallet addresses for fee collection.
     * @param _developerWallet New developer wallet address.
     * @param _liquidityWallet New liquidity wallet address.
     */
    function updateWallets(address _developerWallet, address _liquidityWallet) external onlyOwner {
        require(_developerWallet != address(0), "Invalid developer wallet address");
        require(_liquidityWallet != address(0), "Invalid liquidity wallet address");
        developerWallet = _developerWallet;
        liquidityWallet = _liquidityWallet;
        emit WalletsUpdated(_developerWallet, _liquidityWallet);
    }

    /**
     * @dev Allows the owner to update the Chainlink subscription ID.
     * @param _subscriptionId The new subscription ID.
     */
    function updateSubscriptionId(uint64 _subscriptionId_) external onlyOwner {
        subscriptionId = _subscriptionId_;
    }

    /**
     * @dev Allows the owner to update the rebase interval.
     * @param _newInterval The new interval in seconds.
     */
    function updateRebaseInterval(uint256 _newInterval) external onlyOwner {
        require(_newInterval >= 1 hours, "Interval too short");
        rebaseInterval = _newInterval;
        emit RebaseIntervalUpdated(_newInterval);
    }

    // =======================
    // ====== PAUSABLE ========
    // =======================

    /**
     * @dev Allows the owner to pause all token transfers.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Allows the owner to unpause all token transfers.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // =======================
    // ====== AUTOMATION ======
    // =======================

    /**
     * @dev Chainlink Automation checkUpkeep function.
     * This function is called by Chainlink nodes to check if upkeep is needed.
     * It returns true if the rebase interval has passed.
     * @param checkData Not used in this implementation.
     * @return upkeepNeeded Whether upkeep is needed.
     * @return performData Empty bytes.
     */
    function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = (block.timestamp - lastRebaseTime) >= rebaseInterval;
        // performData can be empty as we don't need to pass any specific data
        performData = "";
    }

    /**
     * @dev Chainlink Automation performUpkeep function.
     * This function is called by Chainlink nodes when checkUpkeep returns true.
     * It performs the upkeep by requesting new market cap data.
     * @param performData Not used in this implementation.
     */
    function performUpkeep(bytes calldata performData) external override {
        // Check again to prevent multiple executions
        if ((block.timestamp - lastRebaseTime) < rebaseInterval) {
            return;
        }

        lastRebaseTime = block.timestamp;
        requestMarketCapData();

        emit UpkeepPerformed(performData);
    }
}


## **Project Overview**

**COIN100** aims to provide a diversified investment vehicle by representing the top 100 cryptocurrencies by market capitalization. Inspired by traditional index funds like the S\&P 500, COIN100 offers both novice and experienced investors a secure, transparent, and efficient way to invest in the overall crypto market.

**Ultimate Goal:** Dynamically track and reflect the top 100 cryptocurrencies by market capitalization, ensuring that COIN100 remains a relevant and accurate representation of the cryptocurrency market.
this contract is built on polygon

