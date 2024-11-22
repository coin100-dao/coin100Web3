// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract COIN100 is ERC20, Ownable {
    AggregatorV3Interface private priceFeed;
    address public developerWallet;
    address public liquidityWallet;
    uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * 10 ** 18; // 1 billion tokens
    uint256 public constant INITIAL_PRICE = 0.01 ether; // $0.01 in ETH

    // Fees
    uint256 public constant TRANSACTION_FEE = 30; // 0.3% in basis points (10000 = 100%)
    uint256 private constant BP_DIVISOR = 10000; // Basis points divisor

    event PriceUpdated(uint256 newPrice);

    constructor(
        address _priceFeed,
        address _developerWallet,
        address _liquidityWallet
    ) ERC20("COIN100", "C100") {
        require(_developerWallet != address(0), "Developer wallet cannot be zero");
        require(_liquidityWallet != address(0), "Liquidity wallet cannot be zero");
        require(_priceFeed != address(0), "Price feed cannot be zero");

        developerWallet = _developerWallet;
        liquidityWallet = _liquidityWallet;
        priceFeed = AggregatorV3Interface(_priceFeed);

        // Initial distribution
        _mint(developerWallet, (INITIAL_SUPPLY * 5) / 100); // 5%
        _mint(liquidityWallet, (INITIAL_SUPPLY * 5) / 100); // 5%
        _mint(msg.sender, (INITIAL_SUPPLY * 90) / 100); // 90% for public sale
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        uint256 fee = (amount * TRANSACTION_FEE) / BP_DIVISOR;
        uint256 amountAfterFee = amount - fee;

        super._transfer(sender, developerWallet, fee / 2); // 50% of fee to developer
        super._transfer(sender, liquidityWallet, fee / 2); // 50% of fee to liquidity
        super._transfer(sender, recipient, amountAfterFee);
    }

    function updatePrice() external onlyOwner {
        (, int256 marketCap, , , ) = priceFeed.latestRoundData();
        require(marketCap > 0, "Invalid market cap");

        uint256 newPrice = uint256(marketCap) / totalSupply();
        emit PriceUpdated(newPrice);
    }

    function mint(uint256 amount) external onlyOwner {
        _mint(msg.sender, amount);
    }

    function burn(uint256 amount) external onlyOwner {
        _burn(msg.sender, amount);
    }

    // Fetch latest market cap data
    function getMarketCap() public view returns (uint256) {
        (, int256 marketCap, , , ) = priceFeed.latestRoundData();
        require(marketCap > 0, "Market cap data unavailable");
        return uint256(marketCap);
    }

}
