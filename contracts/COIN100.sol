// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Import OpenZeppelin Contracts
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Import Chainlink Functions Contracts
import { FunctionsClient } from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import { FunctionsRequest } from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";


/**
 * @title COIN100
 * @dev A decentralized cryptocurrency index fund representing the top 100 cryptocurrencies by market capitalization.
 */
contract COIN100 is ERC20, Pausable, Ownable, FunctionsClient {
    using FunctionsRequest for FunctionsRequest.Request;
    // Addresses for fee collection
    address public developerWallet;
    address public liquidityWallet;

    // Transaction fee percentages (in basis points)
    uint256 public developerFee = 30; // 0.3%
    uint256 public liquidityFee = 30; // 0.3%
    uint256 public constant FEE_DIVISOR = 10_000;

    // Total supply constants
    uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * 10**18; // 1 Billion tokens
    uint256 public constant DEVELOPER_ALLOCATION = (INITIAL_SUPPLY * 5) / 100; // 5%
    uint256 public constant LIQUIDITY_ALLOCATION = (INITIAL_SUPPLY * 5) / 100; // 5%
    uint256 public constant PUBLIC_SALE_ALLOCATION = INITIAL_SUPPLY - DEVELOPER_ALLOCATION - LIQUIDITY_ALLOCATION; // 90%

    // Chainlink Functions Configuration
    address public constant FUNCTIONS_ROUTER_ADDRESS = 0xC22a79eBA640940ABB6dF0f7982cc119578E11De; // Chainlink Functions Router Address on Polygon
    bytes32 public constant DON_ID = 0x66756e2d706f6c79676f6e2d616d6f792d310000000000000000000000000000; // DON ID: fun-polygon-amoy-1

    // Subscription ID for Chainlink Functions
    uint64 public subscriptionId;

    // Events
    event FeesUpdated(uint256 developerFee, uint256 liquidityFee);
    event WalletsUpdated(address developerWallet, address liquidityWallet);
    event TokensMinted(address to, uint256 amount);
    event TokensBurned(address from, uint256 amount);
    event PriceAdjusted(uint256 newTotalSupply);
    event FunctionsRequestSent(bytes32 indexed requestId);
    event FunctionsRequestFulfilled(bytes32 indexed requestId, uint256 newTotalSupply);
    event FunctionsRequestFailed(bytes32 indexed requestId, string reason);

    // Stored total market cap
    uint256 public totalMarketCap;

    /**
     * @dev Constructor that mints the initial allocations and sets up Chainlink Functions.
     * @param _developerWallet Address of the developer wallet.
     * @param _liquidityWallet Address of the liquidity wallet.
     * @param _subscriptionId Chainlink subscription ID.
     */
    constructor(
        address _developerWallet,
        address _liquidityWallet,
        uint64 _subscriptionId
    )
        ERC20("COIN100", "C100")
        FunctionsClient(FUNCTIONS_ROUTER_ADDRESS)
    {
        require(_developerWallet != address(0), "Invalid developer wallet address");
        require(_liquidityWallet != address(0), "Invalid liquidity wallet address");

        developerWallet = _developerWallet;
        liquidityWallet = _liquidityWallet;
        subscriptionId = _subscriptionId;

        // Mint initial allocations
        _mint(_developerWallet, DEVELOPER_ALLOCATION);
        _mint(_liquidityWallet, LIQUIDITY_ALLOCATION);
        _mint(msg.sender, PUBLIC_SALE_ALLOCATION);
    }

    /**
     * @dev Overrides the ERC20 _transfer function to include fee logic.
     * @param sender Address sending the tokens.
     * @param recipient Address receiving the tokens.
     * @param amount Amount of tokens being transferred.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override whenNotPaused {
        // If sender or recipient is the owner, transfer without fees
        if (sender == owner() || recipient == owner()) {
            super._transfer(sender, recipient, amount);
        } else {
            uint256 totalFee = developerFee + liquidityFee;
            uint256 feeAmount = (amount * totalFee) / FEE_DIVISOR; // Calculate total fee
            uint256 amountAfterFee = amount - feeAmount;

            // Calculate individual fees
            uint256 devFeeAmount = (amount * developerFee) / FEE_DIVISOR;
            uint256 liqFeeAmount = feeAmount - devFeeAmount; // Remaining fee goes to liquidity

            // Transfer fees to respective wallets
            super._transfer(sender, developerWallet, devFeeAmount);
            super._transfer(sender, liquidityWallet, liqFeeAmount);

            // Transfer the remaining amount to the recipient
            super._transfer(sender, recipient, amountAfterFee);
        }
    }

    /**
     * @dev Allows the owner to update transaction fees.
     * @param _developerFee New developer fee in basis points.
     * @param _liquidityFee New liquidity fee in basis points.
     */
    function updateFees(uint256 _developerFee, uint256 _liquidityFee) external onlyOwner {
        require(_developerFee + _liquidityFee <= 1000, "Total fees cannot exceed 10%");
        developerFee = _developerFee;
        liquidityFee = _liquidityFee;
        emit FeesUpdated(_developerFee, _liquidityFee);
    }

    /**
     * @dev Allows the owner to update wallet addresses for fee collection.
     * @param _developerWallet New developer wallet address.
     * @param _liquidityWallet New liquidity wallet address.
     */
    function updateWallets(address _developerWallet, address _liquidityWallet) external onlyOwner {
        require(_developerWallet != address(0), "Invalid developer wallet address");
        require(_liquidityWallet != address(0), "Invalid liquidity wallet address");
        developerWallet = _developerWallet;
        liquidityWallet = _liquidityWallet;
        emit WalletsUpdated(_developerWallet, _liquidityWallet);
    }

    /**
     * @dev Allows the owner to mint new tokens.
     * @param to Address to receive the minted tokens.
     * @param amount Amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    /**
     * @dev Allows the owner to burn tokens from a specific address.
     * @param from Address from which tokens will be burned.
     * @param amount Amount of tokens to burn.
     */
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
        emit TokensBurned(from, amount);
    }

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

    /**
     * @dev Initiates a Chainlink Functions request to fetch the total market cap of the top 100 cryptocurrencies.
     */
    function requestMarketCapData() external onlyOwner {
        // JavaScript code to fetch total market cap
        string memory source = string(
            abi.encodePacked(
                "const axios = require('axios');",
                "async function run(request) {",
                "  const response = await axios.get('https://api.coingecko.com/api/v3/global');",
                "  const totalMarketCap = response.data.data.total_market_cap.usd;",
                "  return totalMarketCap.toString();",
                "}"
            )
        );
        // Initialize a new FunctionsRequest
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source);

        // Set any secrets if required (empty in this case)
        req.setSecrets("");

        // Set any arguments if required (empty in this case)
        req.setArgs("");

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
    function adjustSupply(uint256 fetchedMarketCap) internal {
        // Example logic: Adjust total supply proportionally to the market cap
        // Initial market cap assumed at deployment (e.g., $3.38T)
        uint256 initialMarketCap = 3_380_000_000_000; // $3.38 Trillion

        // Calculate the desired supply based on the ratio
        uint256 desiredSupply = (INITIAL_SUPPLY * fetchedMarketCap) / initialMarketCap;

        uint256 currentSupply = totalSupply();

        if (desiredSupply > currentSupply) {
            uint256 mintAmount = desiredSupply - currentSupply;
            _mint(owner(), mintAmount);
            emit PriceAdjusted(desiredSupply);
        } else if (desiredSupply < currentSupply) {
            uint256 burnAmount = currentSupply - desiredSupply;
            _burn(owner(), burnAmount);
            emit PriceAdjusted(desiredSupply);
        }
        // If desiredSupply == currentSupply, no action is taken
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
     * @dev Allows the owner to update the Chainlink subscription ID.
     * @param _subscriptionId The new subscription ID.
     */
    function updateSubscriptionId(uint64 _subscriptionId) external onlyOwner {
        subscriptionId = _subscriptionId;
    }
}
