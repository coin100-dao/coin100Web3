// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract COIN100 is ERC20, Ownable, ChainlinkClient {
    using Chainlink for Chainlink.Request;

    uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * 10 ** 18;
    uint256 public developerFee = 3; // 0.3%
    uint256 public liquidityFee = 3;  // 0.3%
    address public developerAddress;
    address public liquidityAddress;

    // Chainlink variables
    bytes32 private jobId;
    uint256 private fee;
    int256 public currentPrice;

    event PriceUpdated(int256 newPrice);
    event PriceAdjusted(uint256 newSupply);

    constructor(address _developer, address _liquidity) ERC20("COIN100", "C100") {
        _mint(msg.sender, (INITIAL_SUPPLY * 90) / 100); // Public Sale
        _mint(_developer, (INITIAL_SUPPLY * 5) / 100); // Developer
        _mint(_liquidity, (INITIAL_SUPPLY * 5) / 100); // Liquidity

        developerAddress = _developer;
        liquidityAddress = _liquidity;

        // Chainlink setup
        // Polygon mainnet link token: 0x514910771AF9Ca656af840dff83E8264EcF986CA
        // Amoy Testnet LINK Token: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB); // Polygon LINK Token

        // testnet oracle address: 
        setChainlinkOracle(0xOracleAddress); // Replace with actual Oracle Address
        jobId = "your-job-id"; // Replace with actual Job ID
        fee = 0.1 * 10 ** 18; // 0.1 LINK
    }

    // Override transfer to include fees
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        uint256 devFeeAmount = (amount * developerFee) / 1000;
        uint256 liqFeeAmount = (amount * liquidityFee) / 1000;
        uint256 transferAmount = amount - devFeeAmount - liqFeeAmount;

        super._transfer(sender, developerAddress, devFeeAmount);
        super._transfer(sender, liquidityAddress, liqFeeAmount);
        super._transfer(sender, recipient, transferAmount);
    }

    // Mint function restricted to owner
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // Burn function restricted to owner
    function burn(uint256 amount) external onlyOwner {
        _burn(msg.sender, amount);
    }

    // Function to request price update
    function requestPriceUpdate() public onlyOwner {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        // Example API endpoint: Fetch top 100 market caps from Coingecko
        request.add("get", "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&page=1&sparkline=false");
        request.add("path", "0.current_price"); // Adjust path based on actual response structure
        sendChainlinkRequest(request, fee);
    }

    // Callback function for Chainlink
    function fulfill(bytes32 _requestId, int256 _price) public recordChainlinkFulfillment(_requestId) {
        currentPrice = _price;
        emit PriceUpdated(_price);
    }

    // Function to adjust price logic
    function adjustPrice() external onlyOwner {
        require(currentPrice > 0, "Price not set");

        // Example: Implement a rebasing mechanism based on currentPrice
        uint256 newSupply = (INITIAL_SUPPLY * uint256(currentPrice)) / 1e18;
        if (newSupply > totalSupply()) {
            uint256 mintAmount = newSupply - totalSupply();
            _mint(owner(), mintAmount);
        } else if (newSupply < totalSupply()) {
            uint256 burnAmount = totalSupply() - newSupply;
            _burn(owner(), burnAmount);
        }

        emit PriceAdjusted(newSupply);
    }

    // Override ownership transfer to secure contract
    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "New owner is zero address");
        super.transferOwnership(newOwner);
    }

    // Emergency withdrawal functions
    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner(), amount);
    }

    function withdrawMatic(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

    // Fallback functions
    receive() external payable {}
    fallback() external payable {}
}
