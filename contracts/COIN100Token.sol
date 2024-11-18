// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract COIN100Token is ERC20, Ownable {
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 10 ** 18;

    // Allocation percentages
    uint256 public constant PUBLIC_SALE_PERCENT = 50;
    uint256 public constant DEVELOPER_TREASURY_PERCENT = 10;
    uint256 public constant LIQUIDITY_POOL_PERCENT = 20;
    uint256 public constant MARKETING_PERCENT = 7;
    uint256 public constant STAKING_REWARDS_PERCENT = 5;
    uint256 public constant COMMUNITY_TREASURY_PERCENT = 3;
    uint256 public constant RESERVE_PERCENT = 5;

    // Addresses for allocations
    address public developerTreasury;
    address public liquidityPool;
    address public marketingWallet;
    address public stakingRewards;
    address public communityTreasury;
    address public reserveWallet;

    // Fee percentages (in basis points)
    uint256 public transferFee = 30; // 0.3% = 30 basis points
    uint256 public developerFee = 20; // 0.2%
    uint256 public liquidityFee = 16; // 0.16%
    uint256 public communityFee = 12; // 0.12%

    constructor(
        address _developerTreasury,
        address _liquidityPool,
        address _marketingWallet,
        address _stakingRewards,
        address _communityTreasury,
        address _reserveWallet
    ) ERC20("COIN100", "C100") {
        require(
            _developerTreasury != address(0) &&
            _liquidityPool != address(0) &&
            _marketingWallet != address(0) &&
            _stakingRewards != address(0) &&
            _communityTreasury != address(0) &&
            _reserveWallet != address(0),
            "Invalid address"
        );

        developerTreasury = _developerTreasury;
        liquidityPool = _liquidityPool;
        marketingWallet = _marketingWallet;
        stakingRewards = _stakingRewards;
        communityTreasury = _communityTreasury;
        reserveWallet = _reserveWallet;

        // Mint the total supply to the contract itself
        _mint(address(this), TOTAL_SUPPLY);

        // Distribute allocations
        uint256 publicSaleAmount = (TOTAL_SUPPLY * PUBLIC_SALE_PERCENT) / 100;
        uint256 developerAmount = (TOTAL_SUPPLY * DEVELOPER_TREASURY_PERCENT) / 100;
        uint256 liquidityAmount = (TOTAL_SUPPLY * LIQUIDITY_POOL_PERCENT) / 100;
        uint256 marketingAmount = (TOTAL_SUPPLY * MARKETING_PERCENT) / 100;
        uint256 stakingAmount = (TOTAL_SUPPLY * STAKING_REWARDS_PERCENT) / 100;
        uint256 communityAmount = (TOTAL_SUPPLY * COMMUNITY_TREASURY_PERCENT) / 100;
        uint256 reserveAmount = (TOTAL_SUPPLY * RESERVE_PERCENT) / 100;

        // Distribute tokens to respective wallets
        _transfer(address(this), owner(), publicSaleAmount); // COIN100 Owner
        _transfer(address(this), developerTreasury, developerAmount); // Developer Treasury
        _transfer(address(this), liquidityPool, liquidityAmount); // Liquidity Pool
        _transfer(address(this), marketingWallet, marketingAmount); // Marketing Wallet
        _transfer(address(this), stakingRewards, stakingAmount); // Staking Rewards
        _transfer(address(this), communityTreasury, communityAmount); // Community Treasury
        _transfer(address(this), reserveWallet, reserveAmount); // Reserve Wallet
    }

    // Override the transfer function to include fees
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (sender == owner() || recipient == owner()) {
            super._transfer(sender, recipient, amount);
            return;
        }

        uint256 feeAmount = (amount * transferFee) / 10000;
        uint256 developerAmount = (feeAmount * developerFee) / 100;
        uint256 liquidityAmount = (feeAmount * liquidityFee) / 100;
        uint256 communityAmount = (feeAmount * communityFee) / 100;

        uint256 totalFees = developerAmount + liquidityAmount + communityAmount;
        uint256 transferAmount = amount - totalFees;

        super._transfer(sender, developerTreasury, developerAmount);
        super._transfer(sender, liquidityPool, liquidityAmount);
        super._transfer(sender, communityTreasury, communityAmount);
        super._transfer(sender, recipient, transferAmount);
    }

    // Functions to update fees (onlyOwner)
    function updateTransferFee(uint256 _transferFee) external onlyOwner {
        require(_transferFee <= 1000, "Transfer fee too high"); // Max 10%
        transferFee = _transferFee;
    }

    function updateDeveloperFee(uint256 _developerFee) external onlyOwner {
        require(_developerFee <= 100, "Developer fee too high"); // Max 1%
        developerFee = _developerFee;
    }

    function updateLiquidityFee(uint256 _liquidityFee) external onlyOwner {
        require(_liquidityFee <= 100, "Liquidity fee too high"); // Max 1%
        liquidityFee = _liquidityFee;
    }

    function updateCommunityFee(uint256 _communityFee) external onlyOwner {
        require(_communityFee <= 100, "Community fee too high"); // Max 1%
        communityFee = _communityFee;
    }
}
