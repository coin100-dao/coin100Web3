// scripts/deploy_public_sale.js
const hre = require("hardhat");

async function main() {
  const [deployer, treasury] = await hre.ethers.getSigners();

  // Assume COIN100 is already deployed
  const coin100Address = "YOUR_COIN100_DEPLOYED_ADDRESS_HERE"; // Replace with actual address

  // Deploy C100PublicSale
  const C100PublicSale = await hre.ethers.getContractFactory("C100PublicSale");

  // Define initial parameters
  const initialPaymentToken = "0x0000000000000000000000000000000000000000"; // Replace with a mock or actual token address
  const initialRate = hre.ethers.utils.parseUnits("0.001", 18); // 0.001 token per C100
  const initialSymbol = "MCK"; // Mock Token
  const initialName = "Mock Token";
  const initialDecimals = 18;
  const startTime = Math.floor(Date.now() / 1000) + 60; // ICO starts in 1 minute
  const endTime = startTime + 30 * 24 * 60 * 60; // ICO ends in 30 days

  const publicSale = await C100PublicSale.deploy(
    coin100Address,
    initialPaymentToken,
    initialRate,
    initialSymbol,
    initialName,
    initialDecimals,
    treasury.address,
    startTime,
    endTime
  );

  await publicSale.deployed();

  console.log("C100PublicSale deployed to:", publicSale.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
