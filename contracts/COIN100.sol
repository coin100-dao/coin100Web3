// contracts/COIN100.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import OpenZeppelin Contracts
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Import Chainlink Contracts
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

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
    uint256 public marketCap;
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    // Events
    event SupplyAdjusted(uint256 newMarketCap, uint256 adjustedSupply);

    constructor(
        address _developerAddress,
        address _liquidityAddress,
        address _linkToken,
        address _oracle,
        string memory _jobId,
        uint256 _feeAmount
    ) ERC20("COIN100", "C100") {
        require(_developerAddress != address(0), "Invalid developer address");
        require(_liquidityAddress != address(0), "Invalid liquidity address");
        developerAddress = _developerAddress;
        liquidityAddress = _liquidityAddress;

        // Set Chainlink parameters
        setChainlinkToken(_linkToken);
        oracle = _oracle;
        jobId = stringToBytes32(_jobId);
        fee = _feeAmount;

        // Mint total supply
        uint256 totalSupply = 1_000_000_000 * 10 ** decimals(); // 1 billion tokens
        _mint(address(this), totalSupply);

        // Distribute initial supply
        uint256 devAmount = (totalSupply * 5) / 100; // 5%
        uint256 liquidityAmount = (totalSupply * 5) / 100; // 5%
        uint256 publicSaleAmount = totalSupply - devAmount - liquidityAmount; // 90%

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

    // Chainlink function to request market cap data
    function requestMarketCapData() public onlyOwner returns (bytes32 requestId) {
        Chainlink.Request memory request = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfillMarketCap.selector
        );

        // Set the request parameters (depends on the external adapter)
        // Example: get the total market cap of top 100 coins
        request.add("get", "https://api.example.com/top100marketcap"); // Replace with actual API
        request.add("path", "market_cap");

        // Sends the request
        return sendChainlinkRequestTo(oracle, request, fee);
    }

    // Callback function for Chainlink
    function fulfillMarketCap(bytes32 _requestId, uint256 _marketCap)
        public
        recordChainlinkFulfillment(_requestId)
    {
        marketCap = _marketCap;
        adjustSupply();
    }

    // Function to adjust supply based on market cap
    function adjustSupply() internal {
        // Example logic: if market cap increases, mint more tokens to liquidity
        // If decreases, burn tokens from liquidity
        // For simplicity, assume target market cap is initial_market_cap

        uint256 targetMarketCap = 10_000_000 * 10 ** 18; // Example: $10 million

        if (marketCap > targetMarketCap) {
            uint256 increase = marketCap - targetMarketCap;
            // Mint tokens proportional to the increase
            uint256 mintAmount = increase / 10; // Example ratio
            _mint(liquidityAddress, mintAmount);
            emit SupplyAdjusted(marketCap, totalSupply());
        } else if (marketCap < targetMarketCap) {
            uint256 decrease = targetMarketCap - marketCap;
            // Burn tokens proportional to the decrease
            uint256 burnAmount = decrease / 10; // Example ratio
            _burn(liquidityAddress, burnAmount);
            emit SupplyAdjusted(marketCap, totalSupply());
        }
    }

    // Function to set Chainlink parameters
    function setChainlinkParameters(
        address _oracle,
        string memory _jobId,
        uint256 _feeAmount
    ) external onlyOwner {
        oracle = _oracle;
        jobId = stringToBytes32(_jobId);
        fee = _feeAmount;
    }

    // Utility function to convert string to bytes32
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
        require(
            LinkTokenInterface(chainlinkTokenAddress()).transfer(
                owner(),
                LinkTokenInterface(chainlinkTokenAddress()).balanceOf(address(this))
            ),
            "Unable to transfer"
        );
    }
}
