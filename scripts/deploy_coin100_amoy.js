/* eslint-disable no-undef */
const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  console.log("Starting COIN100 deployment to Amoy testnet...");

  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  try {
    // Deploy COIN100
    console.log("\nDeploying COIN100...");
    const COIN100 = await ethers.getContractFactory("COIN100");
    const initialMarketCap = ethers.utils.parseUnits("3316185190709", 18);
    const coin100 = await COIN100.deploy(initialMarketCap, deployer.address);
    await coin100.deployed();
    console.log("COIN100 deployed to:", coin100.address);

    // Wait for a few blocks for better confirmation
    console.log("Waiting for confirmations...");
    await coin100.deployTransaction.wait(5);
    console.log("Deployment confirmed");

    // Save deployment info
    const deploymentInfo = {
      network: "amoy",
      coin100: {
        address: coin100.address,
        initialMarketCap: initialMarketCap.toString(),
        deployer: deployer.address
      },
      timestamp: new Date().toISOString()
    };

    // Create deployments directory if it doesn't exist
    const deploymentsDir = path.join(__dirname, "../deployments");
    if (!fs.existsSync(deploymentsDir)) {
      fs.mkdirSync(deploymentsDir);
    }

    // Save deployment info to file
    fs.writeFileSync(
      path.join(deploymentsDir, "amoy_coin100_deployment.json"),
      JSON.stringify(deploymentInfo, null, 2)
    );
    console.log("\nDeployment info saved to deployments/amoy_coin100_deployment.json");

    console.log("\nCOIN100 deployment completed successfully!");

  } catch (error) {
    console.error("Error during deployment:", error);
    process.exit(1);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 