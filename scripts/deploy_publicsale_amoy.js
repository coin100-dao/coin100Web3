/* eslint-disable no-undef */
const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  console.log("Starting C100PublicSale deployment to Amoy testnet...");

  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);

  const balance = await deployer.getBalance();
  console.log("Account balance:", balance.toString());

  // Load COIN100 deployment info
  const coin100DeploymentPath = path.join(__dirname, "../deployments/amoy_coin100_deployment.json");
  const coin100Deployment = JSON.parse(fs.readFileSync(coin100DeploymentPath, "utf8"));
  const coin100Address = coin100Deployment.coin100.address;

  // Deploy MockERC20 as USDC
  console.log("\nDeploying MockERC20 as USDC...");
  const MockERC20 = await ethers.getContractFactory("MockERC20");
  const mockUSDC = await MockERC20.deploy("Mock USDC", "MUSDC", 6);
  await mockUSDC.deployed();
  console.log("MockUSDC deployed to:", mockUSDC.address);

  // Get current timestamp
  const currentTimestamp = Math.floor(Date.now() / 1000);
  const startTime = currentTimestamp + 300; // Start in 5 minutes
  const endTime = startTime + (30 * 24 * 60 * 60); // 30 days duration

  // Deploy C100PublicSale
  console.log("\nDeploying C100PublicSale...");
  const C100PublicSale = await ethers.getContractFactory("C100PublicSale");
  const publicSale = await C100PublicSale.deploy(
    coin100Address,
    mockUSDC.address,
    ethers.utils.parseUnits("1", 18), // Initial rate
    "MUSDC", // Initial token symbol
    "Mock USDC", // Initial token name
    6, // Initial token decimals
    deployer.address, // Treasury
    startTime,
    endTime
  );
  await publicSale.deployed();
  console.log("C100PublicSale deployed to:", publicSale.address);

  // Save deployment info
  const deploymentInfo = {
    network: "amoy",
    mockUSDC: {
      address: mockUSDC.address,
      symbol: "MUSDC",
      decimals: 6
    },
    publicSale: {
      address: publicSale.address,
      coin100Address: coin100Address,
      startTime: startTime,
      endTime: endTime,
      deployer: deployer.address
    },
    timestamp: new Date().toISOString()
  };

  const deploymentPath = path.join(__dirname, "../deployments/amoy_publicsale_deployment.json");
  fs.writeFileSync(deploymentPath, JSON.stringify(deploymentInfo, null, 2));
  console.log("\nDeployment info saved to deployments/amoy_publicsale_deployment.json");

  // Perform initial setup
  console.log("\nPerforming initial setup...");

  // Mint MockUSDC to deployer
  const mintAmount = ethers.utils.parseUnits("1000000", 6);
  await mockUSDC.mint(deployer.address, mintAmount);
  console.log("Minted 1000000.0 MockUSDC to deployer");

  // Get COIN100 contract instance
  const COIN100 = await ethers.getContractFactory("COIN100");
  const coin100 = COIN100.attach(coin100Address);

  // Approve and transfer COIN100 tokens to public sale contract
  const transferAmount = ethers.utils.parseUnits("1000000", 18);
  await coin100.approve(publicSale.address, transferAmount);
  console.log("Approved COIN100 transfer to public sale contract");

  // Add a delay to ensure the approval is processed
  await new Promise(resolve => setTimeout(resolve, 5000));

  await coin100.transfer(publicSale.address, transferAmount);
  console.log("Transferred COIN100 tokens to public sale contract");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error during deployment:", error);
    process.exit(1);
  }); 