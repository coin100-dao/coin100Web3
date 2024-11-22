// contracts/COIN100.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Import OpenZeppelin Contracts
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Import Chainlink Contracts
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol"; // Not needed for HTTP GET
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract COIN100 is ERC20, Ownable, ChainlinkClient {
    using Chainlink for Chainlink.Request;

    // Addresses for fees
    address public developerAddress;
    address public liquidityAddress;

    // Fee percentages (in basis points: 30 = 0.3%)
    uint256 public devFee = 30;
    uint256 public liquidityFee = 30;
    uint256 public totalFees = 60; // 0.6%

    // Chainlink variables
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    // Market Cap
    uint256 public marketCap;

    // Events
    event MarketCapUpdated(uint256 newMarketCap);
    event SupplyAdjusted(uint256 newSupply);

    constructor(
        address _developerAddress,
        address _liquidityAddress,
        address _linkToken,
        address _oracle,
        string memory _jobId,
        uint256 _fee
    ) ERC20("COIN100", "C100") {
        require(_developerAddress != address(0), "Invalid developer address");
        require(_liquidityAddress != address(0), "Invalid liquidity address");
        developerAddress = _developerAddress;
        liquidityAddress = _liquidityAddress;

        // Set Chainlink parameters
        setChainlinkToken(_linkToken);
        oracle = _oracle;
        jobId = stringToBytes32(_jobId);
        fee = _fee;

        // Mint total supply
        uint256 totalSupplyInitial = 1_000_000_000 * 10 ** decimals(); // 1 billion tokens
        _mint(address(this), totalSupplyInitial);

        // Distribute initial supply
        uint256 devAmount = (totalSupplyInitial * 5) / 100; // 5%
        uint256 liquidityAmount = (totalSupplyInitial * 5) / 100; // 5%
        uint256 publicSaleAmount = totalSupplyInitial - devAmount - liquidityAmount; // 90%

        _transfer(address(this), developerAddress, devAmount);
        _transfer(address(this), liquidityAddress, liquidityAmount);
        // The rest remains in the contract for public sale
    }

    // Override transfer to include fees
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (sender == owner() || recipient == owner()) {
            super._transfer(sender, recipient, amount);
        } else {
            uint256 devFeeAmount = (amount * devFee) / 10000;
            uint256 liquidityFeeAmount = (amount * liquidityFee) / 10000;
            uint256 totalFeeAmount = devFeeAmount + liquidityFeeAmount;
            uint256 transferAmount = amount - totalFeeAmount;

            super._transfer(sender, developerAddress, devFeeAmount);
            super._transfer(sender, liquidityAddress, liquidityFeeAmount);
            super._transfer(sender, recipient, transferAmount);
        }
    }

    /**
     * @notice Creates a Chainlink request to retrieve market cap data
     */
    function requestMarketCapData() public onlyOwner {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

        // Set the URL to perform the GET request on
        request.add("get", "https://api.coingecko.com/api/v3/global");

        // Set the path to extract the total market cap in USD
        request.add("path", "data.total_market_cap.usd");

        // Sends the request
        sendChainlinkRequestTo(oracle, request, fee);
    }

    /**
     * @notice Callback function called by Chainlink oracle
     * @param _requestId The ID of the request
     * @param _marketCap The total market cap in USD
     */
    function fulfill(bytes32 _requestId, uint256 _marketCap) public recordChainlinkFulfillment(_requestId) {
        marketCap = _marketCap;
        emit MarketCapUpdated(_marketCap);
        adjustSupply();
    }

    /**
     * @notice Adjusts the token supply based on the market cap
     */
    function adjustSupply() internal {
        // Define a target market cap (e.g., initial market cap)
        uint256 targetMarketCap = 10_000_000 * 10 ** 18; // Example: $10 million

        if (marketCap > targetMarketCap) {
            uint256 increase = marketCap - targetMarketCap;
            uint256 mintAmount = increase / 10; // Example ratio: 1 LINK = 10 tokens
            _mint(liquidityAddress, mintAmount);
            emit SupplyAdjusted(totalSupply());
        } else if (marketCap < targetMarketCap) {
            uint256 decrease = targetMarketCap - marketCap;
            uint256 burnAmount = decrease / 10; // Example ratio
            _burn(liquidityAddress, burnAmount);
            emit SupplyAdjusted(totalSupply());
        }
    }

    /**
     * @notice Sets new Chainlink parameters
     * @param _oracle The address of the Chainlink oracle
     * @param _jobId The job ID for the request
     * @param _fee The fee in LINK for the request
     */
    function setChainlinkParameters(
        address _oracle,
        string memory _jobId,
        uint256 _fee
    ) external onlyOwner {
        oracle = _oracle;
        jobId = stringToBytes32(_jobId);
        fee = _fee;
    }

    /**
     * @notice Converts a string to bytes32
     * @param source The string to convert
     * @return result The bytes32 representation
     */
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        require(tempEmptyStringTest.length <= 32, "String too long");
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    // Developer functions to mint and burn
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

    // Function to withdraw LINK tokens
    function withdrawLink() external onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(owner(), link.balanceOf(address(this))), "Unable to transfer");
    }
}
