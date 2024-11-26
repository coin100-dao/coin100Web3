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
    event FeesUpdated(uint256 developerFee, uint256 burnFee);
    event WalletsUpdated(address developerWallet);
    event RebaseIntervalUpdated(uint256 newInterval);
    event UpkeepPerformed(bytes performData);
    event FunctionsRequestSent(bytes32 indexed requestId);
    event FunctionsRequestFulfilled(bytes32 indexed requestId, uint256 newMarketCap);
    event FunctionsRequestFailed(bytes32 indexed requestId, string reason);
    event TokensPurchased(address indexed buyer, uint256 amount, uint256 cost);
    event RewardsDistributed(address indexed user, uint256 amount);

    // =======================
    // ======= STATE =========
    // =======================
    uint256 public constant INITIAL_PRICE = 1e16; // $0.01 with 18 decimals
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 1e18; // 1 billion tokens with 18 decimals
    uint256 public lastMarketCap;
    uint256 public feePercent = 3; // 3% fee on transactions
    uint256 public constant SCALING_FACTOR = 380000;

    address public developerWallet;

    // Transaction fee percentages (in basis points)
    uint256 public developerFee = 100;
    uint256 public burnFee = 100;
    uint256 public constant FEE_DIVISOR = 10000;

    // Chainlink Functions Configuration
    address public constant FUNCTIONS_ROUTER_ADDRESS = 0xC22a79eBA640940ABB6dF0f7982cc119578E11De; // Chainlink Functions Router Address on Polygon
    bytes32 public constant DON_ID = 0x66756e2d706f6c79676f6e2d616d6f792d310000000000000000000000000000; // DON ID: fun-polygon-amoy-1

    // Subscription ID for Chainlink Functions
    uint64 public subscriptionId;

    // Chainlink Automation Configuration
    uint256 public lastRebaseTime;
    uint256 public rebaseInterval = 1 hours;

    // Public Sale Parameters
    uint256 public saleStartTime;
    uint256 public saleEndTime;
    uint256 public tokenPrice; // Price in wei per C100 token
    uint256 public tokensSold;

    uint256 public totalMarketCap; // Current total market cap in USD

    // Sale Allocation
    uint256 public constant PUBLIC_SALE_ALLOCATION = (TOTAL_SUPPLY * 70) / 100;

    // Uniswap
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    // Reward Tracking Variables
    uint256 public rewardPerTokenStored;
    uint256 public lastUpdateTime;
    uint256 public rewardRate = 1000; // Example: 1000 C100 tokens distributed per rebase
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    /**
    * @dev Constructor that initializes the token, mints initial allocations, and sets up Chainlink Functions.
    * @param _developerWallet Address of the developer wallet.
    * @param _subscriptionId Chainlink subscription ID.
    */
    constructor(
        address _developerWallet,
        uint64 _subscriptionId
    )
        ERC20("COIN100", "C100")
        Ownable()
        FunctionsClient(FUNCTIONS_ROUTER_ADDRESS)
    {
        require(_developerWallet != address(0), "Invalid developer wallet");

        developerWallet = _developerWallet;
        subscriptionId = _subscriptionId;

        // Mint allocations
        _mint(msg.sender, (TOTAL_SUPPLY * 70) / 100); // 70% Public Sale
        _mint(developerWallet, (TOTAL_SUPPLY * 5) / 100); // 5% Developer
        _mint(address(this), (TOTAL_SUPPLY * 5) / 100); // 5% Rewards Pool

        // Initialize totalRewards with the initial rewards pool
        totalRewards += (TOTAL_SUPPLY * 5) / 100;

        // Initialize rebasing timestamp
        lastRebaseTime = block.timestamp;
        lastUpdateTime = block.timestamp;

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
    * @dev Overrides the ERC20 _transfer function to include fee logic and reward allocation.
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
            uint256 burnFeeAmount = (amount * burnFee) / FEE_DIVISOR;
            uint256 rewardFeeAmount = (amount * liquidityRewardPercent) / 100; // Allocate to rewards

            // Transfer fees to respective wallets
            super._transfer(sender, developerWallet, devFeeAmount); // 1% to Developer
            super._transfer(sender, address(0), burnFeeAmount); // 1% Burn

            // Allocate rewards
            totalRewards += rewardFeeAmount;
            // Optionally, you can emit an event for reward allocation
            // emit RewardsAllocated(sender, rewardFeeAmount);

            // Transfer remaining tokens to recipient
            super._transfer(sender, recipient, transferAmount);
        }
    }

    // =======================
    // ====== FUNCTIONS =======
    // =======================

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

    
    /**
    * @dev Distributes rewards by updating the rewardPerTokenStored and transferring tokens from the rewards pool.
    */
    function distributeRewards() internal {
        updateReward(address(0)); // Update global rewards

        uint256 distributionAmount = (TOTAL_SUPPLY * 1) / 1000; // 0.1% of TOTAL_SUPPLY per interval

        // Check the contract's token balance in the rewards pool
        uint256 contractBalance = balanceOf(address(this));
        uint256 availableForDistribution = contractBalance - totalRewards;

        // Adjust the distributionAmount if not enough tokens are available
        if (availableForDistribution < distributionAmount) {
            distributionAmount = availableForDistribution;
        }

        // Ensure there is something to distribute
        if (distributionAmount > 0) {
            // Update the totalRewards pool
            totalRewards += distributionAmount;

            // Optionally, transfer tokens to a staking pool or keep them in the contract
            // For this one, we'll keep them in the contract
        }

        emit RewardsDistributed(address(this), distributionAmount);
    }

    /**
    * @dev Updates the reward variables to be up-to-date.
    */
    function updateReward(address account) internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
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
        if (IERC20(uniswapV2Pair).totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / IERC20(uniswapV2Pair).totalSupply());
    }

    /**
    * @dev Calculates the earned rewards for a user.
    * @param account The address of the user.
    * @return The amount of rewards earned.
    */
    function earned(address account) public view returns (uint256) {
        return
            ((IERC20(uniswapV2Pair).balanceOf(account) *
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
            rewards[account];
    }

    /**
    * @dev Allows liquidity providers to claim their accumulated rewards.
    * Users must hold LP tokens from the Uniswap pair to be eligible.
    */
    function claimRewards() external nonReentrant {
        // Fetch user's LP token balance
        uint256 userLPBalance = IERC20(uniswapV2Pair).balanceOf(msg.sender);
        require(userLPBalance > 0, "No LP tokens held");

        // Fetch total LP tokens
        uint256 totalLP = IERC20(uniswapV2Pair).totalSupply();
        require(totalLP > 0, "No liquidity in the pool");

        // Calculate user's share (with 18 decimals precision)
        uint256 userShare = (userLPBalance * 1e18) / totalLP;

        // Calculate reward amount based on user's share
        uint256 rewardAmount = (totalRewards * userShare) / 1e18;
        require(rewardAmount > 0, "No rewards available");

        // Update the rewards pool
        totalRewards -= rewardAmount;

        // Transfer rewards to the user
        _transfer(address(this), msg.sender, rewardAmount);

        emit RewardsDistributed(msg.sender, rewardAmount);
    }

    // =======================
    // ====== ADMIN ==========
    // =======================

    /**
     * @dev Allows the owner to update transaction fees.
     * @param _developerFee New developer fee in basis points.
     * @param _burnFee New burn fee in basis points.
     */
    function updateFees(uint256 _developerFee, uint256 _burnFee) external onlyOwner {
        require(_developerFee + _burnFee <= 300, "Total fees cannot exceed 3%");
        developerFee = _developerFee;
        burnFee = _burnFee;
        emit FeesUpdated(_developerFee, _burnFee);
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

        // distribute a portion of rewards periodically
        distributeRewards();

        emit UpkeepPerformed(performData);
    }

}
