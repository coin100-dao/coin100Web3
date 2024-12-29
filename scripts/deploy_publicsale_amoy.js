/* eslint-disable no-undef */
const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function estimateGasWithBuffer(transaction) {
  const gasEstimate = await transaction.estimateGas();
  // Add 20% buffer for safety
  return gasEstimate.mul(120).div(100);
}

async function checkBalance(signer, requiredBalance) {
  const balance = await signer.getBalance();
  return balance.gte(requiredBalance);
}

async function main() {
  console.log("Starting C100PublicSale deployment to Amoy testnet...");

  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);

  const balance = await deployer.getBalance();
  console.log("Account balance:", ethers.utils.formatEther(balance), "MATIC");

  // Estimate total gas needed for deployment (rough estimate)
  const estimatedGasPrice = await ethers.provider.getGasPrice();
  const estimatedGasLimit = ethers.utils.parseUnits("1", "6"); // 1M gas units
  const estimatedCost = estimatedGasPrice.mul(estimatedGasLimit);
  const requiredBalance = estimatedCost.mul(2); // Double for safety

  // Check if we have enough balance
  if (!await checkBalance(deployer, requiredBalance)) {
    console.error("Insufficient balance for deployment");
    console.log("Required (estimated):", ethers.utils.formatEther(requiredBalance), "MATIC");
    console.log("Current balance:", ethers.utils.formatEther(balance), "MATIC");
    process.exit(1);
  }

  // Load COIN100 deployment info
  const coin100DeploymentPath = path.join(__dirname, "../deployments/amoy_coin100_deployment.json");
  if (!fs.existsSync(coin100DeploymentPath)) {
    console.error("COIN100 deployment info not found. Please deploy COIN100 first.");
    process.exit(1);
  }
  const coin100Deployment = JSON.parse(fs.readFileSync(coin100DeploymentPath, "utf8"));
  const coin100Address = coin100Deployment.coin100.address;

  // Verify COIN100 contract exists
  const code = await ethers.provider.getCode(coin100Address);
  if (code === "0x") {
    console.error("COIN100 contract not found at the specified address");
    process.exit(1);
  }

  try {
    // Deploy MockERC20 as USDC
    console.log("\nPreparing to deploy MockERC20 as USDC...");
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    const mockUSDCFactory = await MockERC20.getDeployTransaction("Mock USDC", "MUSDC", 6);
    const mockUSDCGas = await estimateGasWithBuffer(mockUSDCFactory);
    
    if (!await checkBalance(deployer, mockUSDCGas.mul(estimatedGasPrice))) {
      console.error("Insufficient balance for MockUSDC deployment");
      process.exit(1);
    }

    console.log("Deploying MockERC20...");
    const mockUSDC = await MockERC20.deploy("Mock USDC", "MUSDC", 6);
    await mockUSDC.deployed();
    console.log("MockUSDC deployed to:", mockUSDC.address);

    // Get current timestamp
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const startTime = currentTimestamp + 300; // Start in 5 minutes
    const endTime = startTime + (30 * 24 * 60 * 60); // 30 days duration

    // Deploy C100PublicSale
    console.log("\nPreparing to deploy C100PublicSale...");
    const C100PublicSale = await ethers.getContractFactory("C100PublicSale");
    const publicSaleFactory = await C100PublicSale.getDeployTransaction(
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
    const publicSaleGas = await estimateGasWithBuffer(publicSaleFactory);
    
    if (!await checkBalance(deployer, publicSaleGas.mul(estimatedGasPrice))) {
      console.error("Insufficient balance for C100PublicSale deployment");
      process.exit(1);
    }

    console.log("Deploying C100PublicSale...");
    const publicSale = await C100PublicSale.deploy(
      coin100Address,
      mockUSDC.address,
      ethers.utils.parseUnits("1", 18),
      "MUSDC",
      "Mock USDC",
      6,
      deployer.address,
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
    console.log("\nPreparing initial setup...");

    // Estimate gas for minting
    const mintTx = await mockUSDC.populateTransaction.mint(
      deployer.address,
      ethers.utils.parseUnits("1000000", 6)
    );
    const mintGas = await estimateGasWithBuffer(mintTx);
    
    if (!await checkBalance(deployer, mintGas.mul(estimatedGasPrice))) {
      console.error("Insufficient balance for minting MockUSDC");
      process.exit(1);
    }

    console.log("Minting MockUSDC...");
    await mockUSDC.mint(deployer.address, ethers.utils.parseUnits("1000000", 6));
    console.log("Minted 1000000.0 MockUSDC to deployer");

    // Get COIN100 contract instance and check balance
    const COIN100 = await ethers.getContractFactory("COIN100");
    const coin100 = COIN100.attach(coin100Address);
    const coin100Balance = await coin100.balanceOf(deployer.address);
    const transferAmount = ethers.utils.parseUnits("1000000", 18);

    if (coin100Balance.lt(transferAmount)) {
      console.error("Insufficient COIN100 balance for transfer");
      process.exit(1);
    }

    // Estimate gas for approval
    const approveTx = await coin100.populateTransaction.approve(
      publicSale.address,
      transferAmount
    );
    const approveGas = await estimateGasWithBuffer(approveTx);
    
    if (!await checkBalance(deployer, approveGas.mul(estimatedGasPrice))) {
      console.error("Insufficient balance for COIN100 approval");
      process.exit(1);
    }

    console.log("Approving COIN100 transfer...");
    await coin100.approve(publicSale.address, transferAmount);
    console.log("Approved COIN100 transfer to public sale contract");

    // Add a delay to ensure the approval is processed
    await new Promise(resolve => setTimeout(resolve, 5000));

    // Estimate gas for transfer
    const transferTx = await coin100.populateTransaction.transfer(
      publicSale.address,
      transferAmount
    );
    const transferGas = await estimateGasWithBuffer(transferTx);
    
    if (!await checkBalance(deployer, transferGas.mul(estimatedGasPrice))) {
      console.error("Insufficient balance for COIN100 transfer");
      process.exit(1);
    }

    console.log("Transferring COIN100 tokens...");
    await coin100.transfer(publicSale.address, transferAmount);
    console.log("Transferred COIN100 tokens to public sale contract");

    console.log("\nDeployment and setup completed successfully!");
  } catch (error) {
    console.error("Error during deployment:", error);
    process.exit(1);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error during deployment:", error);
    process.exit(1);
  }); 