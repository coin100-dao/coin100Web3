// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Import OpenZeppelin Contracts
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Import Chainlink Contracts
import "@chainlink/contracts/src/v0.8/interfaces/ChainlinkRequestInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract COIN100 is Ownable, ReentrancyGuard, ChainlinkClient, AutomationCompatibleInterface {
    using Chainlink for Chainlink.Request;

    // ============ State Variables ============

    // ERC20 Parameters
    string public name = "COIN100";
    string public symbol = "C100";
    uint8 public decimals = 18;

    // Total Shares (fixed)
    uint256 private constant INITIAL_TOTAL_SHARES = 10_000_000 * (10 ** 18); // 10 million shares

    // Scaling Factor (fixed-point with 18 decimals)
    uint256 public scalingFactor = 1 * 10 ** 18; // Initially 1

    // Total Market Cap of Top 100 Cryptocurrencies
    uint256 public totalMarketCap;

    // Mapping from address to shares
    mapping(address => uint256) private _shares;

    // Total Shares (fixed)
    uint256 public totalShares = INITIAL_TOTAL_SHARES;

    // Transaction Fee Percentages (Basis Points: 100 = 1%)
    uint256 public constant DEV_FEE_BP = 100; // 1%
    uint256 public constant LIQUIDITY_FEE_BP = 100; // 1%
    uint256 public constant BURN_FEE_BP = 100; // 1%
    uint256 public constant TOTAL_TX_FEE_BP = DEV_FEE_BP + LIQUIDITY_FEE_BP + BURN_FEE_BP; // 3%

    // Initial Allocation Percentages
    uint256 public constant DEV_ALLOC_BP = 500; // 5%
    uint256 public constant LIQUIDITY_ALLOC_BP = 500; // 5%

    // Wallet Addresses
    address public devWallet;
    address public liquidityWallet;

    // Chainlink Variables
    address private oracle;
    bytes32 private jobId;
    uint256 private fee; // LINK fee per request

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Rebase(uint256 newScalingFactor);
    event MarketCapUpdated(uint256 newMarketCap);
    event DevWalletUpdated(address newDevWallet);
    event LiquidityWalletUpdated(address newLiquidityWallet);
    event ScalingFactorUpdated(uint256 newScalingFactor);
    event TokensMinted(address to, uint256 shares);
    event TokensBurned(address from, uint256 shares);

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
    ) {
        require(_devWallet != address(0), "Dev wallet cannot be zero address");
        require(_liquidityWallet != address(0), "Liquidity wallet cannot be zero address");

        devWallet = _devWallet;
        liquidityWallet = _liquidityWallet;

        // Initialize Chainlink
        setChainlinkToken(_link);
        oracle = _oracle;
        jobId = _jobId;
        fee = _fee;

        // Assign initial shares to deployer
        _shares[msg.sender] = INITIAL_TOTAL_SHARES;
        emit Transfer(address(0), msg.sender, INITIAL_TOTAL_SHARES);

        // Allocate initial dev and liquidity shares
        uint256 devAllocShares = (INITIAL_TOTAL_SHARES * DEV_ALLOC_BP) / 10_000; // 5%
        uint256 liquidityAllocShares = (INITIAL_TOTAL_SHARES * LIQUIDITY_ALLOC_BP) / 10_000; // 5%

        // Transfer shares
        _transferShares(msg.sender, devWallet, devAllocShares);
        _transferShares(msg.sender, liquidityWallet, liquidityAllocShares);
    }

    // ============ ERC20 Standard Functions ============

    /**
     * @notice Returns the token balance of a given address.
     * @param account The address to query
     * @return The token balance
     */
    function balanceOf(address account) public view returns (uint256) {
        return (_shares[account] * scalingFactor) / (10 ** 18);
    }

    /**
     * @notice Transfers tokens to a specified address.
     * @param recipient The address to transfer to
     * @param amount The amount to transfer
     * @return success Boolean indicating success
     */
    function transfer(address recipient, uint256 amount) public nonReentrant returns (bool success) {
        _transfer(msg.sender, recipient, amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @notice Approves a spender to spend a certain amount of tokens.
     * @param spender The address authorized to spend
     * @param amount The maximum amount they can spend
     * @return success Boolean indicating success
     */
    function approve(address spender, uint256 amount) public nonReentrant returns (bool success) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Transfers tokens from one address to another using allowance.
     * @param sender The address to transfer from
     * @param recipient The address to transfer to
     * @param amount The amount to transfer
     * @return success Boolean indicating success
     */
    function transferFrom(address sender, address recipient, uint256 amount) public nonReentrant returns (bool success) {
        require(_allowances[sender][msg.sender] >= amount, "Allowance exceeded");
        _allowances[sender][msg.sender] -= amount;
        emit Approval(sender, msg.sender, _allowances[sender][msg.sender]);

        _transfer(sender, recipient, amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // ============ Allowance Storage ============

    mapping(address => mapping(address => uint256)) private _allowances;

    /**
     * @notice Returns the remaining number of tokens that spender can spend on behalf of owner.
     * @param owner The owner address
     * @param spender The spender address
     * @return The remaining allowance
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    // ============ Internal Functions ============

    /**
     * @notice Internal function to handle transfers with fees.
     * @param sender The address sending tokens
     * @param recipient The address receiving tokens
     * @param amount The amount to transfer
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from zero address");
        require(recipient != address(0), "Transfer to zero address");
        require(balanceOf(sender) >= amount, "Insufficient balance");

        // Calculate fees
        uint256 devFee = (amount * DEV_FEE_BP) / 10_000; // 1%
        uint256 liquidityFee = (amount * LIQUIDITY_FEE_BP) / 10_000; // 1%
        uint256 burnFee = (amount * BURN_FEE_BP) / 10_000; // 1%
        uint256 totalFee = devFee + liquidityFee + burnFee; // 3%

        uint256 transferAmount = amount - totalFee;

        // Calculate shares
        uint256 senderShares = (_shares[sender] * amount) / balanceOf(sender);
        uint256 transferShares = (_shares[sender] * transferAmount) / balanceOf(sender);
        uint256 devShares = (_shares[sender] * devFee) / balanceOf(sender);
        uint256 liquidityShares = (_shares[sender] * liquidityFee) / balanceOf(sender);
        uint256 burnShares = (_shares[sender] * burnFee) / balanceOf(sender);

        // Update shares
        _shares[sender] -= (transferShares + devShares + liquidityShares + burnShares);
        _shares[recipient] += transferShares;
        _shares[devWallet] += devShares;
        _shares[liquidityWallet] += liquidityShares;
        _burnShares(sender, burnShares);
    }

    /**
     * @notice Internal function to burn shares from an account.
     * @param account The account to burn shares from
     * @param sharesAmount The amount of shares to burn
     */
    function _burnShares(address account, uint256 sharesAmount) internal {
        require(_shares[account] >= sharesAmount, "Burn amount exceeds shares");
        _shares[account] -= sharesAmount;
        totalShares -= sharesAmount;
        emit TokensBurned(account, sharesAmount);
    }

    /**
     * @notice Internal function to transfer shares between accounts.
     * @param sender The sender address
     * @param recipient The recipient address
     * @param sharesAmount The amount of shares to transfer
     */
    function _transferShares(address sender, address recipient, uint256 sharesAmount) internal {
        require(_shares[sender] >= sharesAmount, "Transfer shares exceed balance");
        _shares[sender] -= sharesAmount;
        _shares[recipient] += sharesAmount;
        emit Transfer(sender, recipient, (sharesAmount * scalingFactor) / (10 ** 18));
    }

    // ============ Rebase Mechanism ============

    /**
     * @notice Adjusts the scaling factor based on the total market cap to influence the token's price.
     */
    function rebase() external onlyOwner {
        require(totalMarketCap > 0, "Total market cap is zero");

        // Define target price (in USD with 18 decimals)
        uint256 targetPrice = 100 * (10 ** 18); // $100

        // Calculate new scaling factor
        // newScalingFactor = (totalMarketCap / totalShares) / targetPrice
        // To maintain precision, scale appropriately
        uint256 newScalingFactor = (totalMarketCap * (10 ** 18)) / (totalShares * targetPrice);

        // Update scaling factor
        scalingFactor = newScalingFactor;
        emit Rebase(newScalingFactor);
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

    // ============ Chainlink Functions ============

    /**
     * @notice Initiates a Chainlink request to fetch the total market cap from CoinGecko.
     * @return requestId The unique ID of the Chainlink request
     */
    function requestMarketCapData() public onlyOwner returns (bytes32 requestId) {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfillMarketCap.selector);

        // Set the full URL with query parameters
        // Example: https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&page=1
        string memory url = "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&page=1";
        request.add("get", url);
        request.add("path", "total_market_cap"); // Custom path handled by Chainlink Job

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
        emit MarketCapUpdated(_marketCap);

        // Perform rebase based on the new market cap
        rebase();
    }

    // ============ Owner Functions ============

    /**
     * @notice Updates the Development Wallet address.
     * @param _newDevWallet The new Development Wallet address
     */
    function updateDevWallet(address _newDevWallet) external onlyOwner {
        require(_newDevWallet != address(0), "Dev wallet cannot be zero address");
        devWallet = _newDevWallet;
        emit DevWalletUpdated(_newDevWallet);
    }

    /**
     * @notice Updates the Liquidity Wallet address.
     * @param _newLiquidityWallet The new Liquidity Wallet address
     */
    function updateLiquidityWallet(address _newLiquidityWallet) external onlyOwner {
        require(_newLiquidityWallet != address(0), "Liquidity wallet cannot be zero address");
        liquidityWallet = _newLiquidityWallet;
        emit LiquidityWalletUpdated(_newLiquidityWallet);
    }

    /**
     * @notice Updates the scaling factor manually if needed.
     * @param _newScalingFactor The new scaling factor (fixed-point with 18 decimals)
     */
    function updateScalingFactor(uint256 _newScalingFactor) external onlyOwner {
        require(_newScalingFactor > 0, "Scaling factor must be positive");
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

    // ============ ERC20 Additional Functions ============

    /**
     * @notice Returns the total supply of tokens.
     * @return The total supply
     */
    function totalSupply() public view returns (uint256) {
        return (totalShares * scalingFactor) / (10 ** 18);
    }

    /**
     * @notice Returns the number of shares owned by an account.
     * @param account The account to query
     * @return The number of shares
     */
    function sharesOf(address account) public view returns (uint256) {
        return _shares[account];
    }

    // ============ Receive and Fallback Functions ============

    receive() external payable {}
    fallback() external payable {}
}
