// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Importing OpenZeppelin's ERC20 implementation and related contracts
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Importing Chainlink interfaces
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/FunctionsClient.sol";

contract COIN100 is ERC20, Ownable, AutomationCompatibleInterface, FunctionsClient {
    // Fee percentages
    uint256 public constant DEV_FEE_PERCENT = 1;
    uint256 public constant LIQUIDITY_FEE_PERCENT = 1;
    uint256 public constant BURN_FEE_PERCENT = 1;
    uint256 public constant TOTAL_FEE_PERCENT = 3;

    // Initial allocations
    uint256 public constant DEV_ALLOCATION_PERCENT = 5;
    uint256 public constant LIQUIDITY_ALLOCATION_PERCENT = 5;

    // Wallet addresses
    address public devWallet;
    address public liquidityWallet;

    // Initial parameters for rebase
    uint256 public initialMarketCap;
    uint256 public initialTotalSupply;
    uint256 public scalingFactor;

    // Chainlink Automation variables
    uint256 public lastRebaseTimestamp;
    uint256 public constant REBASE_INTERVAL = 1 hours;

    // Events
    event Rebased(uint256 newTotalSupply, uint256 newPrice);
    event FeesDistributed(uint256 devFee, uint256 liquidityFee, uint256 burnFee);
    event WalletsUpdated(address devWallet, address liquidityWallet);

    constructor(address _devWallet, address _liquidityWallet) ERC20("COIN100", "C100") {
        require(_devWallet != address(0), "Dev wallet cannot be zero address");
        require(_liquidityWallet != address(0), "Liquidity wallet cannot be zero address");

        devWallet = _devWallet;
        liquidityWallet = _liquidityWallet;

        // Initial total supply and allocations
        initialTotalSupply = 10_000_000 * 10 ** decimals(); // 10,000,000 C100
        _mint(address(this), initialTotalSupply);

        uint256 devAllocation = (initialTotalSupply * DEV_ALLOCATION_PERCENT) / 100;
        uint256 liquidityAllocation = (initialTotalSupply * LIQUIDITY_ALLOCATION_PERCENT) / 100;

        _transfer(address(this), devWallet, devAllocation);
        _transfer(address(this), liquidityWallet, liquidityAllocation);

        // Remaining tokens are available for public distribution
        // initialMarketCap is set to $100,000
        initialMarketCap = 100_000 * 10 ** 18; // Represented with 18 decimals for precision

        scalingFactor = 1; // Initially 1

        lastRebaseTimestamp = block.timestamp;
    }

    // Override the transfer function to include fee mechanism
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (sender == owner() || recipient == owner()) {
            super._transfer(sender, recipient, amount);
            return;
        }

        uint256 devFee = (amount * DEV_FEE_PERCENT) / 100;
        uint256 liquidityFee = (amount * LIQUIDITY_FEE_PERCENT) / 100;
        uint256 burnFee = (amount * BURN_FEE_PERCENT) / 100;
        uint256 totalFee = devFee + liquidityFee + burnFee;

        uint256 amountAfterFee = amount - totalFee;

        super._transfer(sender, devWallet, devFee);
        super._transfer(sender, liquidityWallet, liquidityFee);
        _burn(sender, burnFee);
        super._transfer(sender, recipient, amountAfterFee);

        emit FeesDistributed(devFee, liquidityFee, burnFee);
    }

    // Chainlink Automation: check if rebase is needed
    function checkUpkeep(bytes calldata /*checkData*/) external view override returns (bool upkeepNeeded, bytes memory /*performData*/) {
        upkeepNeeded = (block.timestamp >= lastRebaseTimestamp + REBASE_INTERVAL);
    }

    // Chainlink Automation: perform rebase
    function performUpkeep(bytes calldata /*performData*/) external override {
        if (block.timestamp < lastRebaseTimestamp + REBASE_INTERVAL) {
            return;
        }
        lastRebaseTimestamp = block.timestamp;
        _rebase();
    }

    // Internal rebase function
    function _rebase() internal {
        // Fetch current total market cap from Chainlink Function
        uint256 currentMarketCap = getTotalMarketCap();

        // Calculate scaling factor
        scalingFactor = (currentMarketCap * 1e18) / initialMarketCap; // Using 1e18 for precision

        // Calculate new total supply
        uint256 newTotalSupply = (initialTotalSupply * scalingFactor) / 1e18;

        // Calculate the ratio of new supply to current supply
        uint256 supplyDelta = newTotalSupply > totalSupply() ? newTotalSupply - totalSupply() : totalSupply() - newTotalSupply;
        bool supplyIncrease = newTotalSupply > totalSupply();

        if (supplyIncrease) {
            _mint(address(this), supplyDelta);
        } else {
            _burn(address(this), supplyDelta);
        }

        emit Rebased(newTotalSupply, getTokenPrice());
    }

    // Placeholder function to get total market cap via Chainlink Functions
    function getTotalMarketCap() internal view returns (uint256) {
        // In a production environment, implement Chainlink Functions to fetch data from CoinGecko
        // For demonstration, returning a mock value. Replace this with actual oracle call.
        return initialMarketCap; // Replace with actual data
    }

    // Function to calculate current token price
    function getTokenPrice() public view returns (uint256) {
        // tokenPrice = initialPrice * scalingFactor
        // initialPrice = $0.01, represented with 18 decimals: 0.01 * 1e18 = 1e16
        uint256 initialPrice = 1e16;
        return (initialPrice * scalingFactor) / 1e18;
    }

    // Admin functions to update wallets
    function updateDevWallet(address _devWallet) external onlyOwner {
        require(_devWallet != address(0), "Dev wallet cannot be zero address");
        devWallet = _devWallet;
        emit WalletsUpdated(devWallet, liquidityWallet);
    }

    function updateLiquidityWallet(address _liquidityWallet) external onlyOwner {
        require(_liquidityWallet != address(0), "Liquidity wallet cannot be zero address");
        liquidityWallet = _liquidityWallet;
        emit WalletsUpdated(devWallet, liquidityWallet);
    }

    // Emergency function to pause rebasing in case of issues
    bool public paused = false;

    function pauseRebase() external onlyOwner {
        paused = true;
    }

    function resumeRebase() external onlyOwner {
        paused = false;
    }

    // Override performUpkeep to respect paused state
    function performUpkeep(bytes calldata /*performData*/) external override {
        if (paused) {
            return;
        }
        if (block.timestamp < lastRebaseTimestamp + REBASE_INTERVAL) {
            return;
        }
        lastRebaseTimestamp = block.timestamp;
        _rebase();
    }
}
