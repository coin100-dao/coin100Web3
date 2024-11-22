// scripts/deploy.js

import hre from "hardhat";

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const COIN100 = await hre.ethers.getContractFactory("COIN100");
  const coin100 = await COIN100.deploy(deployer.address, deployer.address); // Replace with actual wallet addresses

  await coin100.deployed();
  console.log("COIN100 deployed to:", coin100.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
