// scripts/deploy_public_sale.js
const { ethers } = require("hardhat");

async function main() {
  const {
    COIN100_ADDRESS,
    PAYMENT_TOKEN,
    RATE,
    TOKEN_SYMBOL,
    TOKEN_NAME,
    TOKEN_DECIMALS
  } = process.env;

  if (!COIN100_ADDRESS) {
    throw new Error('COIN100_ADDRESS not provided');
  }

  const paymentToken = PAYMENT_TOKEN || "0x0000000000000000000000000000000000000000";
  const rate = ethers.utils.parseUnits(RATE || "0.001", 18);
  const symbol = TOKEN_SYMBOL || "ETH";
  const name = TOKEN_NAME || "Ethereum";
  const decimals = parseInt(TOKEN_DECIMALS || "18");
  
  const now = Math.floor(Date.now() / 1000);
  const startTime = now + 60; // Start in 1 minute
  const endTime = startTime + (30 * 24 * 60 * 60); // End in 30 days

  const [, treasury] = await ethers.getSigners();

  // Deploy C100PublicSale
  console.log('Deploying C100PublicSale with parameters:');
  console.log({
    coin100Address: COIN100_ADDRESS,
    paymentToken,
    rate: rate.toString(),
    symbol,
    name,
    decimals,
    treasury: treasury.address,
    startTime,
    endTime
  });

  const C100PublicSale = await ethers.getContractFactory("C100PublicSale");
  const publicSale = await C100PublicSale.deploy(
    COIN100_ADDRESS,
    paymentToken,
    rate,
    symbol,
    name,
    decimals,
    treasury.address,
    startTime,
    endTime
  );

  await publicSale.deployed();

  console.log("C100PublicSale deployed to:", publicSale.address);
  console.log("Transaction hash:", publicSale.deployTransaction.hash);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
