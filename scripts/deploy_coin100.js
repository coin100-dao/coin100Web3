// scripts/deploy_coin100.js
import { ethers } from "hardhat";
import process from "process";

async function main() {
  const [deployer, treasury] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Treasury address:", treasury.address);

  // Deploy COIN100
  const COIN100 = await ethers.getContractFactory("COIN100");
  
  // Initialize with an initial market cap and treasury address
  const initialMarketCap = ethers.utils.parseUnits("1000", 18); // 1000 * 1e18
  const tx = await COIN100.deploy(initialMarketCap, treasury.address);
  await tx.deployed();

  console.log("COIN100 deployed to:", tx.address);
}

main()
  .then(() => process.exitCode = 0)
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
