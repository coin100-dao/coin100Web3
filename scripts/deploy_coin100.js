// scripts/deploy_coin100.js
const hre = require("hardhat");

async function main() {
  const [deployer, treasury] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Treasury address:", treasury.address);

  // Deploy COIN100
  const COIN100 = await hre.ethers.getContractFactory("COIN100");
  
  // Initialize with an initial market cap and treasury address
  const initialMarketCap = hre.ethers.utils.parseUnits("1000", 18); // 1000 * 1e18
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
