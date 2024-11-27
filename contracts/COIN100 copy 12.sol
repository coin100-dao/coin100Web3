// SPDX-License-Identifier: MIT
/**
**COIN100** is a decentralized cryptocurrency index fund built on the polygon network. It represents the top 100 cryptocurrencies by market capitalization, offering users a diversified portfolio that mirrors the performance of the overall crypto market. Inspired by traditional index funds like the S\&P 500, COIN100

**Ultimate Goal:** To dynamically track and reflect the top 100 cryptocurrencies by market capitalization, ensuring that COIN100 remains a relevant and accurate representation of the cryptocurrency market.
*/
pragma solidity ^0.8.20;

// Import OpenZeppelin Contracts
import "@openzeppelin/contracts@4.8.0/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.8.0/security/Pausable.sol";
import "@openzeppelin/contracts@4.8.0/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Import Chainlink Functions Contracts
import { FunctionsClient } from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import { FunctionsRequest } from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

// Import Chainlink Automation Contracts
import { AutomationCompatibleInterface } from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Import Uniswap V2 Interfaces
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";


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
    event FeesUpdated(uint256 developerFee, uint256 burnFee, uint256 rewardFee);
    event WalletsUpdated(address developerWallet);
    event RebaseIntervalUpdated(uint256 newInterval);
    event UpkeepPerformed(bytes performData);
    event FunctionsRequestSent(bytes32 indexed requestId);
    event FunctionsRequestFulfilled(bytes32 indexed requestId, uint256 newMarketCap);
    event FunctionsRequestFailed(bytes32 indexed requestId, string reason);
    event RewardsDistributed(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 newRewardRate, uint256 currentPrice);
    event RewardFeeUpdated(uint256 newRewardFee);
    event RewardsReplenished(uint256 amount, uint256 timestamp);
    event PriceFeedUpdated(address newPriceFeed);

    // =======================
    // ======= STATE =========
    // =======================
    AggregatorV3Interface internal priceFeed;
    bool public useDirectPriceFeed = false; // false: use Uniswap + MATIC/USD; true: use direct C100/USD

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

    // Chainlink Functions Configuration
    address public functionsRouterAddress;
    bytes32 public donId;

    // Subscription ID for Chainlink Functions
    uint64 public subscriptionId;

    // Chainlink Automation Configuration
    uint256 public lastRebaseTime;
    uint256 public rebaseInterval = 24 hours;

    // Uniswap
    IUniswapV2Router02 public uniswapV2Router;
    
    address public uniswapV2Pair;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    // =======================
    // ====== FUNCTIONS =======
    // =======================

    /**
     * @dev Allows the owner to set the Chainlink price feed address and specify its type.
     * @param _priceFeedAddress The address of the price feed.
     * @param _isDirectUSDFeed If true, the price feed is assumed to be C100/USD. If false, it's MATIC/USD.
     */
    function setPriceFeed(address _priceFeedAddress, bool _isDirectUSDFeed) public onlyOwner {
        require(_priceFeedAddress != address(0), "Invalid price feed address");
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        useDirectPriceFeed = _isDirectUSDFeed;
        emit PriceFeedUpdated(_priceFeedAddress);
    }

    /**
    * @dev Constructor that initializes the token, mints initial allocations, and sets up Chainlink Functions.
    * @param _priceFeedAddress Address of the price feed.
    * @param _wmatic Address of the WMATIC token.
    * @param _developerWallet Address of the developer wallet.
    * @param _subscriptionId Chainlink subscription ID.
    * @param _quickswapUniswapRouterAddress Address of the Uniswap V2 router.
    * @param _functionsRouterAddress Address of the Chainlink Functions Router.
    * @param _donId DON ID for Chainlink Functions.
    */
    constructor(
        address _priceFeedAddress,
        address _wmatic,
        address _quickswapUniswapRouterAddress, 
        address _developerWallet,
        uint64 _subscriptionId,
        address _functionsRouterAddress,
        bytes32 _donId
    )
        ERC20("COIN100", "C100")
        Ownable()
        FunctionsClient(_functionsRouterAddress)
    {
        require(_priceFeedAddress != address(0), "Invalid price feed address");
        require(_wmatic != address(0), "Invalid WMATIC address");
        require(_developerWallet != address(0), "Invalid developer wallet");
        require(_quickswapUniswapRouterAddress != address(0), "Invalid Uniswap router address");
        require(_functionsRouterAddress != address(0), "Invalid Functions router address");
        require(_donId != bytes32(0), "Invalid DON ID");
        require(_subscriptionId > 0, "Invalid subscription ID");

        developerWallet = _developerWallet;
        subscriptionId = _subscriptionId;

        // Assign dynamic Chainlink Functions parameters
        functionsRouterAddress = _functionsRouterAddress;
        donId = _donId;

        // Set the price feed address for MATIC/USD
        setPriceFeed(_priceFeedAddress, false); // false indicates it's not a direct C100/USD feed

        // Mint allocations
        _mint(owner(), (TOTAL_SUPPLY * 90) / 100); // 70% Public Sale + 20% Treasury
        _mint(developerWallet, (TOTAL_SUPPLY * 5) / 100); // 5% Developer
        _mint(address(this), (TOTAL_SUPPLY * 5) / 100); // 5% Rewards Pool

        // Initialize totalRewards with the initial rewards pool
        totalRewards += (TOTAL_SUPPLY * 5) / 100;

        // Initialize rebasing and reward tracking timestamps
        lastRebaseTime = block.timestamp;
        lastUpdateTime = block.timestamp;

        // Initialize Uniswap V2 Router
        uniswapV2Router = IUniswapV2Router02(_quickswapUniswapRouterAddress);

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
    // ====== ERC20 OVERRIDES ==
    // =======================

    /**
    * @dev Overrides the ERC20 _transfer function to include fee logic and reward allocation.
    * @param sender Address sending the tokens.
    * @param recipient Address receiving the tokens.
    * @param amount Amount of tokens being transferred.
    */
    function _transfer(address sender, address recipient, uint256 amount) internal override whenNotPaused {
        updateReward(sender);
        updateReward(recipient);

        if (sender == owner() || recipient == owner()) {
            // Owner transfers bypass fees
            super._transfer(sender, recipient, amount);
            return;
        }

        // Calculate total fee
        uint256 feeAmount = (amount * feePercent) / 100; // 3% of amount

        // Allocate fees based on adjusted percentages
        uint256 devFeeAmount = (feeAmount * developerFee) / FEE_DIVISOR; // 1.2%
        uint256 burnFeeAmount = (feeAmount * burnFee) / FEE_DIVISOR; // 1.2%
        uint256 rewardFeeAmount = (feeAmount * rewardFee) / FEE_DIVISOR; // 0.6%

        // Transfer individual fees
        super._transfer(sender, developerWallet, devFeeAmount); // Developer fee
        super._transfer(sender, address(0), burnFeeAmount); // Burn fee

        // Allocate rewards
        if (rewardFeeAmount > 0) {
            totalRewards += rewardFeeAmount;
            emit RewardsDistributed(address(this), rewardFeeAmount); // Optional: Emit event for internal tracking
        }

        // Transfer the remaining amount to the recipient
        uint256 transferAmount = amount - feeAmount;
        super._transfer(sender, recipient, transferAmount);
    }

    // =======================
    // ====== FUNCTIONS =======
    // =======================

    /**
    * @dev Retrieves the latest price of C100 in USD.
    * If useDirectPriceFeed is true, it uses the direct C100/USD price feed.
    * Otherwise, it derives the price using Uniswap C100/MATIC reserves and the MATIC/USD price feed.
    * @return price The latest C100 price in USD with 8 decimals.
    */
    function getLatestPrice() public view returns (uint256 price) {
        require(address(priceFeed) != address(0), "Price feed not set");

        if (useDirectPriceFeed) {
            // Direct C100/USD price feed
            (, int256 c100Price, , , ) = priceFeed.latestRoundData();
            require(c100Price > 0, "Invalid C100 price data");
            price = uint256(c100Price); // Assuming 8 decimals
        } else {
            // Derive C100/USD price using Uniswap C100/MATIC and Chainlink MATIC/USD

            // Get MATIC/USD price from Chainlink
            (, int256 maticPrice, , , ) = priceFeed.latestRoundData();
            require(maticPrice > 0, "Invalid MATIC price data");
            uint256 maticPriceUSD = uint256(maticPrice); // Assuming 8 decimals

            // Get reserves from Uniswap pair
            (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(uniswapV2Pair).getReserves();
            address token0 = IUniswapV2Pair(uniswapV2Pair).token0();

            uint112 reserveC100;
            uint112 reserveMATIC;

            if (token0 == address(this)) {
                reserveC100 = reserve0;
                reserveMATIC = reserve1;
            } else {
                reserveC100 = reserve1;
                reserveMATIC = reserve0;
            }

            require(reserveC100 > 0 && reserveMATIC > 0, "Uniswap reserves not available");

            // Calculate C100/MATIC price (MATIC per C100)
            // reserveMATIC / reserveC100
            // To maintain precision, multiply by 1e18
            uint256 c100PerMATIC = (uint256(reserveMATIC) * 1e18) / uint256(reserveC100);

            // Calculate C100/USD price
            // C100/USD = C100/MATIC * MATIC/USD
            // (1e18 / 1e18) * (1e8) = 1e8
            // So final price has 8 decimals
            price = (c100PerMATIC * maticPriceUSD) / 1e18;
        }
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
            donId // Updated to use dynamic DON ID
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
    * @dev Adjusts the token supply based on the latest market cap data with rebase limits.
    * @param fetchedMarketCap The latest total market cap in USD (8 decimals).
    */
    function adjustSupply(uint256 fetchedMarketCap) internal nonReentrant {
        uint256 currentPrice = getLatestPrice(); // Price with 8 decimals
        uint256 currentC100MarketCap = (totalSupply() * currentPrice) / 1e8; // Adjusted scaling

        // Assuming fetchedMarketCap is already in USD with 8 decimals
        uint256 paf = (fetchedMarketCap * 1e18) / currentC100MarketCap;

        if (paf > 1e18 + (MAX_REBASE_PERCENT * 1e16)) { // Allow up to MAX_REBASE_PERCENT% increase
            uint256 rebaseFactor = (MAX_REBASE_PERCENT * 1e16); // 5% in 1e18 scale
            uint256 mintAmount = (totalSupply() * rebaseFactor) / 1e18;
            _mint(address(this), mintAmount);
            emit TokensMinted(mintAmount);
        } else if (paf < 1e18 - (MAX_REBASE_PERCENT * 1e16)) { // Allow up to MAX_REBASE_PERCENT% decrease
            uint256 rebaseFactor = (MAX_REBASE_PERCENT * 1e16);
            uint256 burnAmount = (totalSupply() * rebaseFactor) / 1e18;
            _burn(address(this), burnAmount);
            emit TokensBurned(burnAmount);
        }

        lastMarketCap = fetchedMarketCap;
        emit PriceAdjusted(fetchedMarketCap, block.timestamp);
    }

    /**
    * @dev Parses a string to a uint256.
    * @param _a The string to parse.
    * @return _parsed The parsed uint256.
    */
    function parseInt(string memory _a) internal pure returns (uint256 _parsed) {
        bytes memory bresult = bytes(_a);
        uint256 result = 0;
        uint256 decimalPlaces = 0;
        bool decimalPointEncountered = false;
        for (uint256 i = 0; i < bresult.length; i++) {
            if (bresult[i] == ".") {
                decimalPointEncountered = true;
                continue;
            }
            if (uint8(bresult[i]) >= 48 && uint8(bresult[i]) <= 57) {
                if (decimalPointEncountered) {
                    if (decimalPlaces < 8) { // Limit to 8 decimal places
                        result = result * 10 + (uint8(bresult[i]) - 48);
                        decimalPlaces++;
                    }
                } else {
                    result = result * 10 + (uint8(bresult[i]) - 48);
                }
            }
        }
        // Scale to 8 decimals instead of 18
        if (decimalPlaces < 8) {
            result = result * (10**(8 - decimalPlaces));
        } else if (decimalPlaces > 8) {
            result = result / (10**(decimalPlaces - 8));
        }
        return result;
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
        uint256 totalSupplyLP = IERC20(uniswapV2Pair).totalSupply();
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
        uint256 balance = IERC20(uniswapV2Pair).balanceOf(account);
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
        uint256 currentPrice = getLatestPrice(); // Price with 8 decimals
        uint256 newRewardRate;
        
        if (currentPrice < 1 * 1e8) { // Below $1
            newRewardRate = 2000 * 1e18; // Highest rewards per rebase
        } else if (currentPrice >= 1 * 1e8 && currentPrice < 5 * 1e8) { // $1 - $5
            newRewardRate = 1500 * 1e18;
        } else if (currentPrice >= 5 * 1e8 && currentPrice < 10 * 1e8) { // $5 - $10
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
    // ====== ADMIN ==========
    // =======================

    /**
    * @dev Allows the owner to update transaction fees.
    * @param _developerFee New developer fee in basis points (percentage of feePercent).
    * @param _burnFee New burn fee in basis points (percentage of feePercent).
    * @param _rewardFee New reward fee in basis points (percentage of feePercent).
    */
    function updateFees(uint256 _developerFee, uint256 _burnFee, uint256 _rewardFee) external onlyOwner {
        require(_developerFee + _burnFee + _rewardFee <= FEE_DIVISOR, "Total fee allocation cannot exceed 100%");
        developerFee = _developerFee;
        burnFee = _burnFee;
        rewardFee = _rewardFee;
        emit FeesUpdated(_developerFee, _burnFee, _rewardFee);
    }

    /**
     * @dev Allows the owner to update wallet addresses for fee collection.
     * @param _developerWallet New developer wallet address.
     */
    function updateWallets(address _developerWallet) external onlyOwner {
        require(_developerWallet != address(0), "Invalid developer wallet address");
        developerWallet = _developerWallet;
        emit WalletsUpdated(_developerWallet);
    }

    // /**
    //  * @dev Allows the owner to update the Chainlink subscription ID.
    //  * @param _subscriptionId The new subscription ID.
    //  */
    function updateSubscriptionId(uint64 _subscriptionId_) external onlyOwner {
        subscriptionId = _subscriptionId_;
    }

    /**
    * @dev Allows the owner to update the rebase interval.
    *      Ensures that the new interval is within acceptable bounds to prevent abuse.
    * @param _newInterval The new interval in seconds. Must be at least 1 hour and no more than 7 days.
    */
    function updateRebaseInterval(uint256 _newInterval) external onlyOwner {
        require(_newInterval >= 1 hours, "Interval too short");
        require(_newInterval <= 30 days, "Interval too long");

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
     * @return upkeepNeeded Whether upkeep is needed.
     * @return performData Empty bytes.
     */
    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = (block.timestamp - lastRebaseTime) >= rebaseInterval;
        // performData can be empty as we don't need to pass any specific data
        performData = "";
    }

    /**
    * @dev Chainlink Automation performUpkeep function.
    * This function is called by Chainlink nodes when checkUpkeep returns true.
    * It performs the upkeep by requesting new market cap data and distributing rewards.
    * @param performData Not used in this implementation.
    */
    function performUpkeep(bytes calldata performData) external override {
        // Check again to prevent multiple executions
        if ((block.timestamp - lastRebaseTime) < rebaseInterval) {
            return;
        }

        lastRebaseTime = block.timestamp;
        requestMarketCapData();

        // Distribute rewards to ensure the rewards pool is replenished
        distributeRewards();

        emit UpkeepPerformed(performData);
    }

}
