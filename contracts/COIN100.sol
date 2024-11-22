// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import OpenZeppelin Contracts
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title COIN100
 * @dev A decentralized cryptocurrency index fund representing the top 100 cryptocurrencies by market capitalization.
 */
contract COIN100 is ERC20, Ownable, Pausable {
    // Addresses for fee collection
    address public developerWallet;
    address public liquidityWallet;

    // Transaction fee percentages (in basis points)
    uint256 public developerFee = 30; // 0.3%
    uint256 public liquidityFee = 30; // 0.3%

    // Total supply constants
    uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * 10**18; // 1 Billion tokens
    uint256 public constant DEVELOPER_ALLOCATION = (INITIAL_SUPPLY * 5) / 100; // 5%
    uint256 public constant LIQUIDITY_ALLOCATION = (INITIAL_SUPPLY * 5) / 100; // 5%
    uint256 public constant PUBLIC_SALE_ALLOCATION = INITIAL_SUPPLY - DEVELOPER_ALLOCATION - LIQUIDITY_ALLOCATION; // 90%

    // Events
    event FeesUpdated(uint256 developerFee, uint256 liquidityFee);
    event WalletsUpdated(address developerWallet, address liquidityWallet);
    event TokensMinted(address to, uint256 amount);
    event TokensBurned(address from, uint256 amount);

    /**
     * @dev Constructor that mints the initial allocations.
     * @param _developerWallet Address of the developer wallet.
     * @param _liquidityWallet Address of the liquidity wallet.
     */
    constructor(address _developerWallet, address _liquidityWallet) ERC20("COIN100", "C100") {
        require(_developerWallet != address(0), "Invalid developer wallet address");
        require(_liquidityWallet != address(0), "Invalid liquidity wallet address");

        developerWallet = _developerWallet;
        liquidityWallet = _liquidityWallet;

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
        uint256 totalFee = developerFee + liquidityFee;
        uint256 feeAmount = (amount * totalFee) / 10_000; // Basis points calculation
        uint256 amountAfterFee = amount - feeAmount;

        // Transfer fees
        super._transfer(sender, developerWallet, (amount * developerFee) / 10_000);
        super._transfer(sender, liquidityWallet, (amount * liquidityFee) / 10_000);

        // Transfer the remaining amount to the recipient
        super._transfer(sender, recipient, amountAfterFee);
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
}
