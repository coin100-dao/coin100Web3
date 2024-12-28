/* eslint-disable no-undef */
// scripts/deploy_coin100.js
const { ethers } = require("hardhat");

async function main() {
  const [deployer, treasury] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Treasury address:", treasury.address);

  // Deploy COIN100
  const COIN100 = await ethers.getContractFactory("COIN100");
  
  // Initialize with an initial market cap and treasury address
  const initialMarketCap = ethers.utils.parseUnits("3316185190709", 18); // 3316185190709 * 1e18
  const tx = await COIN100.deploy(initialMarketCap, treasury.address);
  await tx.deployed();

  console.log("COIN100 deployed to:", tx.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
