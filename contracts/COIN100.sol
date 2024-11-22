// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Import OpenZeppelin Contracts
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

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

contract COIN100 is ERC20, Ownable {
    uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * 10 ** 18; // 1 billion tokens
    address public developerWallet;
    address public liquidityWallet;

    uint256 public devFeePercent = 3; // 0.3%
    uint256 public liquidityFeePercent = 3; // 0.3%
    uint256 public totalFeePercent = devFeePercent + liquidityFeePercent; // 0.6%

    AggregatorV3Interface internal priceFeed;

    // Events
    event FeesDistributed(uint256 devFee, uint256 liquidityFee);

    constructor(
        address _developerWallet,
        address _liquidityWallet,
        address _priceFeedAddress
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

    // Event for price update
    event PriceUpdated(int newPrice);

    // Function to update the price based on external data
    function updatePrice() external onlyOwner {
        int latestPrice = getLatestPrice();
        // Implement your logic to adjust the supply based on the latest price
        // For example, adjust total supply to reflect price changes

        // Placeholder logic: emit event (implement actual logic as needed)
        emit PriceUpdated(latestPrice);
    }

}
