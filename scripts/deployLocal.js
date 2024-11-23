// scripts/deployLocal.js

const hre = require("hardhat");

async function main() {
  // Fetch the contract to deploy
  const COIN100 = await hre.ethers.getContractFactory("COIN100");

  // Define developer and liquidity wallet addresses from .env
  const developerWallet = process.env.DEVELOPER_WALLET;
  const liquidityWallet = process.env.LIQUIDITY_WALLET;

  console.log("Deploying COIN100 contract with:");
  console.log("Developer Wallet:", developerWallet);
  console.log("Liquidity Wallet:", liquidityWallet);

  // Deploy the contract
  const coin100 = await COIN100.deploy(developerWallet, liquidityWallet);

  await coin100.deployed();

  console.log("COIN100 deployed to:", coin100.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error deploying COIN100:", error);
    process.exit(1);
  });
