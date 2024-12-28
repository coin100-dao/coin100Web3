// scripts/deploy_public_sale.js
/**
 * Deploy script for C100PublicSale contract
 * 
 * Required environment variables or command line arguments:
 * - COIN100_ADDRESS: Address of the deployed COIN100 token
 * - PAYMENT_TOKEN: Address of the token used for payment (use zero address for native token)
 * - RATE: Exchange rate (e.g., "0.001" means 0.001 payment token per C100)
 * - TOKEN_SYMBOL: Symbol of the payment token
 * - TOKEN_NAME: Name of the payment token
 * - TOKEN_DECIMALS: Decimals of the payment token
 * - START_TIME: Unix timestamp for sale start (optional, defaults to 1 minute from deployment)
 * - END_TIME: Unix timestamp for sale end (optional, defaults to 30 days after start)
 * 
 * Example usage:
 * ```
 * npx hardhat run scripts/deploy_public_sale.js --network <network> \
 *   --coin100-address 0x... \
 *   --payment-token 0x... \
 *   --rate 0.001 \
 *   --token-symbol "USDT" \
 *   --token-name "Tether USD" \
 *   --token-decimals 6
 * ```
 */

import { ethers } from "hardhat";
import { process } from 'process';

async function main() {
  // Get command line arguments
  const args = process.argv.slice(2);
  const getArg = (flag) => {
    const index = args.indexOf(flag);
    return index !== -1 ? args[index + 1] : null;
  };

  // Get deployment parameters from arguments or environment variables
  const coin100Address = getArg('--coin100-address') || process.env.COIN100_ADDRESS;
  if (!coin100Address) {
    throw new Error('COIN100_ADDRESS not provided');
  }

  const paymentToken = getArg('--payment-token') || process.env.PAYMENT_TOKEN || "0x0000000000000000000000000000000000000000";
  const rate = ethers.utils.parseUnits(getArg('--rate') || process.env.RATE || "0.001", 18);
  const symbol = getArg('--token-symbol') || process.env.TOKEN_SYMBOL || "ETH";
  const name = getArg('--token-name') || process.env.TOKEN_NAME || "Ethereum";
  const decimals = parseInt(getArg('--token-decimals') || process.env.TOKEN_DECIMALS || "18");
  
  const now = Math.floor(Date.now() / 1000);
  const startTime = parseInt(getArg('--start-time') || process.env.START_TIME || (now + 60).toString());
  const endTime = parseInt(getArg('--end-time') || process.env.END_TIME || (startTime + 30 * 24 * 60 * 60).toString());

  const [, treasury] = await ethers.getSigners();

  // Deploy C100PublicSale
  console.log('Deploying C100PublicSale with parameters:');
  console.log({
    coin100Address,
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
    coin100Address,
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
  .then(() => process.exitCode = 0)
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
