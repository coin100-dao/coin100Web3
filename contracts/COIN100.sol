// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Import OpenZeppelin Contracts
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Import Chainlink Automation Interface
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

// Interface for Chainlink Price Feeds
interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundID,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract COIN100 is ERC20, Ownable, AutomationCompatibleInterface {
    uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * 10 ** 18; // 1 billion tokens
    address public developerWallet;
    address public liquidityWallet;

    uint256 public devFeePercent = 3; // 0.3%
    uint256 public liquidityFeePercent = 3; // 0.3%
    uint256 public totalFeePercent = devFeePercent + liquidityFeePercent; // 0.6%

    AggregatorV3Interface internal priceFeed;

    // Events
    event FeesDistributed(uint256 devFee, uint256 liquidityFee);
    event PriceUpdated(int newPrice);

    // Automation variables
    uint256 public lastTimeStamp;
    uint256 public interval;

    constructor(
        address _developerWallet,
        address _liquidityWallet,
        address _priceFeedAddress,
        uint256 _updateInterval
    ) ERC20("COIN100", "C100") {
        require(
            _developerWallet != address(0) && _liquidityWallet != address(0),
            "Invalid wallet address"
        );
        developerWallet = _developerWallet;
        liquidityWallet = _liquidityWallet;
        priceFeed = AggregatorV3Interface(_priceFeedAddress);

        // Mint initial supply
        _mint(msg.sender, (INITIAL_SUPPLY * 90) / 100); // 90% public sale
        _mint(developerWallet, (INITIAL_SUPPLY * 5) / 100); // 5% developer
        _mint(liquidityWallet, (INITIAL_SUPPLY * 5) / 100); // 5% liquidity

        // Initialize Automation variables
        interval = _updateInterval;
        lastTimeStamp = block.timestamp;
    }

    // Override transfer to include fee mechanism
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (sender == owner() || recipient == owner()) {
            super._transfer(sender, recipient, amount);
            return;
        }

        uint256 devFee = (amount * devFeePercent) / 1000; // 0.3%
        uint256 liquidityFee = (amount * liquidityFeePercent) / 1000; // 0.3%
        uint256 totalFees = devFee + liquidityFee;
        uint256 amountAfterFees = amount - totalFees;

        super._transfer(sender, developerWallet, devFee);
        super._transfer(sender, liquidityWallet, liquidityFee);
        super._transfer(sender, recipient, amountAfterFees);

        emit FeesDistributed(devFee, liquidityFee);
    }

    // Function to update fee percentages (if needed)
    function updateFees(uint256 _devFeePercent, uint256 _liquidityFeePercent) external onlyOwner {
        require(_devFeePercent + _liquidityFeePercent <= 100, "Total fee too high");
        devFeePercent = _devFeePercent;
        liquidityFeePercent = _liquidityFeePercent;
        totalFeePercent = _devFeePercent + _liquidityFeePercent;
    }

    // Mint function (only owner)
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // Burn function (only owner)
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

    // Function to get the latest price from Chainlink
    function getLatestPrice() public view returns (int) {
        (
            ,
            int price,
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price;
    }

    // Function to update the price based on external data
    function updatePrice() external onlyOwner {
        int latestPrice = getLatestPrice();
        // Implement your logic to adjust the supply based on the latest price
        // For example, adjust total supply to reflect price changes

        // Placeholder logic: emit event (implement actual logic as needed)
        emit PriceUpdated(latestPrice);
    }

    /**
     * @notice method that is simulated by the keepers to see if any work needs to be performed
     * @dev This method does not actually need to be executable, and since it is only ever
     *      simulated it can consume lots of gas, however it must be view
     * @param checkData The data which is passed to the contract when simulating the call
     * @return upkeepNeeded boolean to indicate whether upkeep is needed
     * @return performData bytes that the Keeper should call `performUpkeep` with, if upkeep is needed
     */
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        performData = "";
    }

    /**
     * @notice method that is actually executed by the keepers, via the registry
     * @dev The data returned by the checkUpkeep simulation will be passed into the
     *      performUpkeep method to actually be executed
     * @param performData is the data which was passed back from the checkUpkeep simulation
     */
    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        if ((block.timestamp - lastTimeStamp) > interval ) {
            lastTimeStamp = block.timestamp;
            updatePrice();
        }
    }
}
