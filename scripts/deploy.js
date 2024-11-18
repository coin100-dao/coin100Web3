const hre = require("hardhat");

async function main() {
  // Deploy COIN100Token
  const COIN100Token = await hre.ethers.getContractFactory("COIN100Token");
  
  // Wallet Addresses
  const developerTreasury = "0x4f2ee2Cf708F6641d5C7e6aD3128d15d91d15e60"; // COIN100 Developer Treasury
  const liquidityPool = "0x799f59a724Cc6a745083cE8A160ba7D13FD471A0"; // COIN100 Liquidity Pool
  const marketingWallet = "0x9Bb4346295797f5d38A1F18FDfe946e372A7be4a"; // COIN100 Marketing
  const stakingRewards = "0x3D8029660048e7E0a7bD04623802Ab815cc84CF8"; // COIN100 Staking Rewards
  const communityTreasury = "0xYourCommunityTreasuryAddress"; // COIN100 Community Treasury
  const reserveWallet = "0xE51edf567dc8162d1EAe53764A864f34deB0DdE9"; // COIN100 Reserve Wallet

  // Deploy COIN100Token
  const coin100 = await COIN100Token.deploy(
    developerTreasury,   // COIN100 Developer Treasury
    liquidityPool,       // COIN100 Liquidity Pool
    marketingWallet,     // COIN100 Marketing
    stakingRewards,      // COIN100 Staking Rewards
    communityTreasury,   // COIN100 Community Treasury
    reserveWallet        // COIN100 Reserve Wallet
  );

  await coin100.deployed();
  console.log("COIN100Token deployed to:", coin100.address);

  // Deploy COIN100DeveloperTreasury
  const COIN100DeveloperTreasury = await hre.ethers.getContractFactory("COIN100DeveloperTreasury");
  const developerTreasuryContract = await COIN100DeveloperTreasury.deploy(
    coin100.address,
    hre.ethers.utils.parseUnits("100000000", 18) // 100,000,000 COIN100
  );

  await developerTreasuryContract.deployed();
  console.log("COIN100DeveloperTreasury deployed to:", developerTreasuryContract.address);

  // Deploy COIN100CommunityGovernance
  const COIN100CommunityGovernance = await hre.ethers.getContractFactory("COIN100CommunityGovernance");
  const communityGovernance = await COIN100CommunityGovernance.deploy(
    coin100.address,
    communityTreasury,
    100 // Example: 100 required votes
  );

  await communityGovernance.deployed();
  console.log("COIN100CommunityGovernance deployed to:", communityGovernance.address);

  // Deploy COIN100StakingRewards
  const COIN100StakingRewards = await hre.ethers.getContractFactory("COIN100StakingRewards");
  const stakingRewardsContract = await COIN100StakingRewards.deploy(
    coin100.address,
    coin100.address // Staking COIN100
  );

  await stakingRewardsContract.deployed();
  console.log("COIN100StakingRewards deployed to:", stakingRewardsContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error deploying contracts:", error);
    process.exit(1);
  });
