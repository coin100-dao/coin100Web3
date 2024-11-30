// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import OpenZeppelin Contracts
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Import Uniswap V2 Interfaces
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

// Import Chainlink Aggregator Interface
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title COIN100 (C100) Token
 * @dev A decentralized cryptocurrency index fund tracking the top 100 cryptocurrencies by market capitalization.
 */
contract COIN100 is ERC20Pausable, Ownable, ReentrancyGuard {
    // =======================
    // ======= EVENTS ========
    // =======================
    event PriceAdjusted(uint256 newMarketCap, uint256 timestamp);
    event TokensBurned(uint256 amount);
    event TokensMinted(uint256 amount);
    event FeesUpdated(uint256 developerFee, uint256 burnFee, uint256 rewardFee);
    event FeePercentUpdated(uint256 newFeePercent);
    event WalletsUpdated(address developerWallet);
    event RebaseIntervalUpdated(uint256 newInterval);
    event UpkeepPerformed(address indexed performer, uint256 timestamp);
    event RewardsDistributed(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 newRewardRate, uint256 currentPrice);
    event RewardFeeUpdated(uint256 newRewardFee);
    event RewardsReplenished(uint256 amount, uint256 timestamp);
    event UniswapV2RouterUpdated(address newUniswapV2Router);
    event MaticPriceFeedUpdated(address newPriceFeed);
    event C100UsdPriceFeedUpdated(address newPriceFeed); // New Event for C100/USD Price Feed

    // =======================
    // ======= STATE =========
    // =======================

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

    // Uniswap
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    // Chainlink Price Feeds
    AggregatorV3Interface public maticUsdPriceFeed;
    AggregatorV3Interface public c100UsdPriceFeed; // New Price Feed for C100/USD

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    // Upkeep Variables
    uint256 public lastRebaseTime;
    uint256 public rebaseInterval = 7 days; // Minimum 7 days between upkeeps
    uint256 public upkeepReward = 10 * 1e18; // Reward for performing upkeep (10 C100 tokens)

    // =======================
    // ====== FUNCTIONS =======
    // =======================

    /**
     * @dev Constructor that initializes the token, mints initial allocations, and sets up price feeds.
     * @param _wmatic Address of the WMATIC token.
     * @param _quickswapUniswapRouterAddress Address of the Uniswap V2 router.
     * @param _developerWallet Address of the developer wallet.
     * @param _maticUsdPriceFeed Address of the Chainlink MATIC/USD price feed.
     */
    constructor(
        address _wmatic,
        address _quickswapUniswapRouterAddress, 
        address _developerWallet,
        address _maticUsdPriceFeed
    )
        ERC20("COIN100", "C100")
        Ownable(msg.sender)
    {
        require(_wmatic != address(0), "Invalid WMATIC address");
        require(_developerWallet != address(0), "Invalid developer wallet");
        require(_quickswapUniswapRouterAddress != address(0), "Invalid Uniswap router address");
        require(_maticUsdPriceFeed != address(0), "Invalid MATIC/USD price feed address");

        developerWallet = _developerWallet;
        maticUsdPriceFeed = AggregatorV3Interface(_maticUsdPriceFeed);

        // Mint allocations
        _mint(owner(), (TOTAL_SUPPLY * 90) / 100); // 90% Public Sale + Treasury
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
    // ====== OVERRIDES ======
    // =======================

    /**
    * @dev Overrides the ERC20 transfer function to include fee logic and reward allocation.
    * @param recipient Address receiving the tokens.
    * @param amount Amount of tokens being transferred.
    * @return bool indicating success.
    */
    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        address sender = _msgSender();
        updateReward(sender);
        updateReward(recipient);

        if (sender == owner() || recipient == owner()) {
            // Owner transfers bypass fees
            return super.transfer(recipient, amount);
        }

        // Calculate total fee
        uint256 feeAmount = (amount * feePercent) / 100; // 3% total fee

        // Allocate fees based on adjusted percentages
        uint256 devFeeAmount = (feeAmount * developerFee) / FEE_DIVISOR; // 1.2%
        uint256 burnFeeAmount = (feeAmount * burnFee) / FEE_DIVISOR;     // 1.2%
        uint256 rewardFeeAmount = (feeAmount * rewardFee) / FEE_DIVISOR; // 0.6%

        // Transfer Developer Fee
        if (devFeeAmount > 0) {
            super.transfer(developerWallet, devFeeAmount);
        }

        // Burn Fee
        if (burnFeeAmount > 0) {
            _burn(sender, burnFeeAmount);
        }

        // Reward Fee
        if (rewardFeeAmount > 0) {
            super.transfer(address(this), rewardFeeAmount);
            totalRewards += rewardFeeAmount;
            emit RewardsDistributed(address(this), rewardFeeAmount); // Optional: Emit event for internal tracking
        }

        // Transfer the remaining amount to the recipient
        uint256 transferAmount = amount - feeAmount;
        return super.transfer(recipient, transferAmount);
    }

    /**
    * @dev Overrides the ERC20 transferFrom function to include fee logic and reward allocation.
    * @param sender Address sending the tokens.
    * @param recipient Address receiving the tokens.
    * @param amount Amount of tokens being transferred.
    * @return bool indicating success.
    */
    function transferFrom(address sender, address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        updateReward(sender);
        updateReward(recipient);

        if (sender == owner() || recipient == owner()) {
            // Owner transfers bypass fees
            return super.transferFrom(sender, recipient, amount);
        }

        // Calculate total fee
        uint256 feeAmount = (amount * feePercent) / 100; // 3% total fee

        // Allocate fees based on adjusted percentages
        uint256 devFeeAmount = (feeAmount * developerFee) / FEE_DIVISOR; // 1.2%
        uint256 burnFeeAmount = (feeAmount * burnFee) / FEE_DIVISOR;     // 1.2%
        uint256 rewardFeeAmount = (feeAmount * rewardFee) / FEE_DIVISOR; // 0.6%

        // Transfer Developer Fee
        if (devFeeAmount > 0) {
            super.transferFrom(sender, developerWallet, devFeeAmount);
        }

        // Burn Fee
        if (burnFeeAmount > 0) {
            _burn(sender, burnFeeAmount);
        }

        // Reward Fee
        if (rewardFeeAmount > 0) {
            super.transferFrom(sender, address(this), rewardFeeAmount);
            totalRewards += rewardFeeAmount;
            emit RewardsDistributed(address(this), rewardFeeAmount); // Optional: Emit event for internal tracking
        }

        // Transfer the remaining amount to the recipient
        uint256 transferAmount = amount - feeAmount;
        return super.transferFrom(sender, recipient, transferAmount);
    }

    // =======================
    // ====== ADMIN FUNCTIONS ==
    // =======================

    /**
     * @dev Allows the owner to set the total transaction fee percentage.
     * @param _feePercent The new fee percentage (e.g., 3 for 3%).
     */
    function setFeePercent(uint256 _feePercent) external onlyOwner {
        require(_feePercent <= 100, "Fee percent cannot exceed 100%");
        feePercent = _feePercent;
        emit FeePercentUpdated(_feePercent);
    }

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

    /**
     * @dev Allows the owner to update the Uniswap V2 Router address.
     * @param _newRouter Address of the new Uniswap V2 Router.
     */
    function setUniswapV2Router(address _newRouter) external onlyOwner {
        require(_newRouter != address(0), "Invalid Uniswap V2 Router address");
        uniswapV2Router = IUniswapV2Router02(_newRouter);
        emit UniswapV2RouterUpdated(_newRouter);
        
        // Approve the new router to spend tokens as needed
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
    }

    /**
     * @dev Allows the owner to update the rebase interval.
     *      Ensures that the new interval is within acceptable bounds to prevent abuse.
     * @param _newInterval The new interval in seconds. Must be at least 7 days and no more than 365 days.
     */
    function updateRebaseInterval(uint256 _newInterval) external onlyOwner {
        require(_newInterval >= 7 days, "Interval too short");
        require(_newInterval <= 365 days, "Interval too long");
        rebaseInterval = _newInterval;
        emit RebaseIntervalUpdated(_newInterval);
    }

    /**
     * @dev Allows the owner to set the upkeep reward amount.
     * @param _newReward The new reward amount in C100 tokens.
     */
    function setUpkeepReward(uint256 _newReward) external onlyOwner {
        upkeepReward = _newReward;
        emit RewardFeeUpdated(_newReward);
    }

    /**
     * @dev Allows the owner to update the MATIC/USD price feed address.
     * @param _newPriceFeed Address of the new Chainlink MATIC/USD price feed.
     */
    function updateMaticUsdPriceFeed(address _newPriceFeed) external onlyOwner {
        require(_newPriceFeed != address(0), "Invalid price feed address");
        maticUsdPriceFeed = AggregatorV3Interface(_newPriceFeed);
        emit MaticPriceFeedUpdated(_newPriceFeed);
    }

    /**
     * @dev Allows the owner to set or update the C100/USD price feed address.
     *      Once set, the contract will use this direct price feed for price determination.
     * @param _newC100UsdPriceFeed Address of the new Chainlink C100/USD price feed.
     */
    function setC100UsdPriceFeed(address _newC100UsdPriceFeed) external onlyOwner {
        require(_newC100UsdPriceFeed != address(0), "Invalid C100/USD price feed address");
        c100UsdPriceFeed = AggregatorV3Interface(_newC100UsdPriceFeed);
        emit C100UsdPriceFeedUpdated(_newC100UsdPriceFeed);
    }

    // =======================
    // ====== FUNCTIONS =======
    // =======================

    /**
     * @dev Retrieves the latest price of C100 in USD.
     *      - If a direct C100/USD price feed is available, it uses that.
     *      - Otherwise, it derives the price using the C100/MATIC pair and the MATIC/USD price feed.
     * @return price The latest C100 price in USD with 6 decimals (USDC has 6 decimals).
     */
    function getLatestPrice() public view returns (uint256 price) {
        if (address(c100UsdPriceFeed) != address(0)) {
            // Directly fetch C100/USD price from Chainlink
            price = getPriceFromC100UsdFeed();
        } else {
            // Derive price via C100/MATIC and MATIC/USD
            price = getDerivedPriceFromMatic();
        }
    }

    /**
     * @dev Internal function to fetch the C100/USD price directly from the Chainlink price feed.
     * @return price The price of C100 in USD with 6 decimals.
     */
    function getPriceFromC100UsdFeed() internal view returns (uint256 price) {
        (
            ,
            int256 priceInt,
            ,
            ,

        ) = c100UsdPriceFeed.latestRoundData();
        require(priceInt > 0, "Invalid C100/USD price from oracle");
        uint8 decimals = c100UsdPriceFeed.decimals();
        price = uint256(priceInt) * (10 ** (6 - decimals)); // Adjust to 6 decimals
    }

    /**
     * @dev Internal function to derive the C100/USD price using C100/MATIC and MATIC/USD prices.
     * @return priceViaMATIC The derived price of C100 in USD with 6 decimals.
     */
    function getDerivedPriceFromMatic() internal view returns (uint256 priceViaMATIC) {
        // Fetch C100/MATIC price
        address pairMATIC = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), WMATIC);
        require(pairMATIC != address(0), "C100/MATIC pair does not exist");
        IUniswapV2Pair pair2 = IUniswapV2Pair(pairMATIC);
        (uint112 reserve0MATIC, uint112 reserve1MATIC, ) = pair2.getReserves();
        address token0MATIC = pair2.token0();
        uint256 reserveC100_MATIC = token0MATIC == address(this) ? uint256(reserve0MATIC) : uint256(reserve1MATIC);
        uint256 reserveMATIC = token0MATIC == address(this) ? uint256(reserve1MATIC) : uint256(reserve0MATIC);
        require(reserveC100_MATIC > 0 && reserveMATIC > 0, "Uniswap reserves not available for MATIC pair");
        uint256 priceMATIC = (reserveMATIC * 1e18) / reserveC100_MATIC; // MATIC typically has 18 decimals

        // Fetch MATIC/USD price from Chainlink
        (, int256 price, , , ) = maticUsdPriceFeed.latestRoundData();
        require(price > 0, "Invalid MATIC/USD price from oracle");
        uint8 decimals = maticUsdPriceFeed.decimals();
        uint256 maticPriceUSD = uint256(price) * (10 ** (6 - decimals)); // Adjust to 6 decimals

        // Calculate C100/USD price via MATIC
        priceViaMATIC = (priceMATIC * maticPriceUSD) / 1e18; // Adjusting decimals
    }

    /**
     * @dev Adjusts the token supply based on the latest market cap data with rebase limits.
     * @param fetchedMarketCap The latest total market cap in USD (6 decimals, matching USDC).
     */
    function adjustSupply(uint256 fetchedMarketCap) internal nonReentrant {
        uint256 currentPrice = getLatestPrice(); // Price with 6 decimals
        uint256 currentC100MarketCap = (totalSupply() * currentPrice) / 1e6; // Adjusted scaling

        // Compute Price Adjustment Factor (PAF)
        uint256 paf = (fetchedMarketCap * 1e18) / currentC100MarketCap;

        if (paf > 1e18 + (MAX_REBASE_PERCENT * 1e16)) { // Allow up to MAX_REBASE_PERCENT% increase
            uint256 rebaseFactor = (MAX_REBASE_PERCENT * 1e16); // 5% in 1e18 scale
            uint256 mintAmount = (totalSupply() * rebaseFactor) / 1e18;
            require(mintAmount <= MAX_MINT_AMOUNT, "Mint amount exceeds maximum");
            _mint(address(this), mintAmount);
            emit TokensMinted(mintAmount);
        } else if (paf < 1e18 - (MAX_REBASE_PERCENT * 1e16)) { // Allow up to MAX_REBASE_PERCENT% decrease
            uint256 rebaseFactor = (MAX_REBASE_PERCENT * 1e16);
            uint256 burnAmount = (totalSupply() * rebaseFactor) / 1e18;
            require(burnAmount <= MAX_BURN_AMOUNT, "Burn amount exceeds maximum");
            _burn(address(this), burnAmount);
            emit TokensBurned(burnAmount);
        }

        lastMarketCap = fetchedMarketCap;
        emit PriceAdjusted(fetchedMarketCap, block.timestamp);
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

    // =======================
    // ====== REWARDS ========
    // =======================

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
        uint256 totalSupplyLP = IUniswapV2Pair(uniswapV2Pair).totalSupply();
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
        uint256 balance = IUniswapV2Pair(uniswapV2Pair).balanceOf(account);
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
        uint256 currentPrice = getLatestPrice(); // Price with 6 decimals
        uint256 newRewardRate;
        
        if (currentPrice < 1 * 1e6) { // Below $1
            newRewardRate = 2000 * 1e18; // Highest rewards per rebase
        } else if (currentPrice >= 1 * 1e6 && currentPrice < 5 * 1e6) { // $1 - $5
            newRewardRate = 1500 * 1e18;
        } else if (currentPrice >= 5 * 1e6 && currentPrice < 10 * 1e6) { // $5 - $10
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
    // ====== UPKEEP =========
    // =======================

    /**
     * @dev Allows anyone to perform upkeep tasks manually.
     * Requires that at least `rebaseInterval` has passed since the last upkeep.
     * Rewards the caller with `upkeepReward` C100 tokens.
     * @param _fetchedMarketCap The latest total market cap in USD (6 decimals, matching USDC).
     */
    function performUpkeep(uint256 _fetchedMarketCap) external nonReentrant {
        require(block.timestamp >= lastRebaseTime + rebaseInterval, "Upkeep interval not reached");
        require(_fetchedMarketCap > 0, "Invalid market cap");

        // Update the total market cap
        totalMarketCap = _fetchedMarketCap;

        // Adjust the supply based on the new market cap
        adjustSupply(_fetchedMarketCap);

        // Update the last rebase time
        lastRebaseTime = block.timestamp;

        // Reward the caller
        if (upkeepReward > 0 && balanceOf(address(this)) >= upkeepReward) {
            _transfer(address(this), msg.sender, upkeepReward);
            emit RewardsDistributed(msg.sender, upkeepReward);
        }

        emit UpkeepPerformed(msg.sender, block.timestamp);
    }
}
