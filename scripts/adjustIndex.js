// scripts/adjustIndex.ts

import { ethers } from "ethers";
import axios from "axios";
import * as dotenv from "dotenv";

dotenv.config();

// Configuration Constants
const COINGECKO_API_URL = "https://api.coingecko.com/api/v3/coins/markets";
const COINGECKO_PARAMS = {
    vs_currency: "usd",
    order: "market_cap_desc",
    per_page: 100,
    page: 1,
    sparkline: false,
};

const INITIAL_TOKEN_PRICE = 0.01; // $0.01
const INITIAL_SUPPLY = ethers.utils.parseEther("1000000000"); // 1,000,000,000 tokens

// Smart Contract ABI (Only the functions we need)
const CONTRACT_ABI = [
    "function totalSupply() view returns (uint256)",
    "function mint(address to, uint256 amount) external",
    "function burn(address from, uint256 amount) external",
    "function balanceOf(address account) view returns (uint256)",
];

// Initialize Ethereum Provider and Signer
const provider = new ethers.providers.InfuraProvider(
    process.env.NETWORK || "mainnet",
    process.env.INFURA_PROJECT_ID
);
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

// Initialize Smart Contract Instance
const contract = new ethers.Contract(
    process.env.CONTRACT_ADDRESS,
    CONTRACT_ABI,
    wallet
);

/**
 * Fetches the top 100 cryptocurrencies by market cap from CoinGecko.
 * @returns Total market capitalization of the top 100 cryptocurrencies.
 */
async function fetchTop100MarketCap() {
    try {
        const response = await axios.get(COINGECKO_API_URL, {
            params: COINGECKO_PARAMS,
        });

        const data = response.data;
        let totalMarketCap = 0;

        data.forEach((coin) => {
            totalMarketCap += coin.market_cap;
        });

        console.log(`Fetched Top 100 Market Cap: $${totalMarketCap.toLocaleString()}`);
        return totalMarketCap;
    } catch (error) {
        console.error("Error fetching data from CoinGecko:", error);
        throw error;
    }
}

/**
 * Calculates the current index market cap based on the token supply and initial price.
 * @param totalSupply Current total supply of the COIN100 token.
 * @returns Current index market capitalization.
 */
function calculateIndexMarketCap(totalSupply) {
    const supplyInEther = parseFloat(ethers.utils.formatEther(totalSupply));
    const indexMarketCap = supplyInEther * INITIAL_TOKEN_PRICE;
    console.log(`Current Index Market Cap: $${indexMarketCap.toLocaleString()}`);
    return indexMarketCap;
}

/**
 * Determines the adjustment ratio based on the fetched market cap and current index cap.
 * @param fetchedMarketCap Total market cap fetched from CoinGecko.
 * @param currentIndexCap Current index market cap.
 * @returns Adjustment Ratio.
 */
function calculateAdjustmentRatio(fetchedMarketCap, currentIndexCap) {
    const ratio = fetchedMarketCap / currentIndexCap;
    console.log(`Adjustment Ratio: ${ratio}`);
    return ratio;
}

/**
 * Determines the amount of tokens to mint or burn based on the adjustment ratio.
 * @param ratio Adjustment Ratio.
 * @param totalSupply Current total supply of the COIN100 token.
 * @returns Object containing mint and burn amounts.
 */
function determineAdjustment(ratio, totalSupply) {
    let mintAmount = ethers.BigNumber.from(0);
    let burnAmount = ethers.BigNumber.from(0);

    if (ratio > 1.01) { // Threshold to prevent frequent small adjustments
        const increaseFactor = ratio - 1;
        const supplyInEther = parseFloat(ethers.utils.formatEther(totalSupply));
        const additionalMarketCap = supplyInEther * INITIAL_TOKEN_PRICE * increaseFactor;
        const tokensToMint = additionalMarketCap / INITIAL_TOKEN_PRICE;
        mintAmount = ethers.utils.parseEther(tokensToMint.toFixed(18));
        console.log(`Tokens to Mint: ${ethers.utils.formatEther(mintAmount)} C100`);
    } else if (ratio < 0.99) {
        const decreaseFactor = 1 - ratio;
        const supplyInEther = parseFloat(ethers.utils.formatEther(totalSupply));
        const reducedMarketCap = supplyInEther * INITIAL_TOKEN_PRICE * decreaseFactor;
        const tokensToBurn = reducedMarketCap / INITIAL_TOKEN_PRICE;
        burnAmount = ethers.utils.parseEther(tokensToBurn.toFixed(18));
        console.log(`Tokens to Burn: ${ethers.utils.formatEther(burnAmount)} C100`);
    } else {
        console.log("No adjustment needed.");
    }

    return { mint: mintAmount, burn: burnAmount };
}

/**
 * Executes the minting or burning of tokens based on the adjustment.
 * @param mintAmount Amount of tokens to mint.
 * @param burnAmount Amount of tokens to burn.
 */
async function executeAdjustment(mintAmount, burnAmount) {
    try {
        if (mintAmount.gt(0)) {
            const tx = await contract.mint(process.env.DEVELOPER_WALLET, mintAmount);
            console.log(`Minting ${ethers.utils.formatEther(mintAmount)} C100... Transaction Hash: ${tx.hash}`);
            await tx.wait();
            console.log("Minting completed.");
        }

        if (burnAmount.gt(0)) {
            const tx = await contract.burn(process.env.DEVELOPER_WALLET, burnAmount);
            console.log(`Burning ${ethers.utils.formatEther(burnAmount)} C100... Transaction Hash: ${tx.hash}`);
            await tx.wait();
            console.log("Burning completed.");
        }
    } catch (error) {
        console.error("Error executing adjustment:", error);
    }
}

/**
 * Main function to orchestrate the dynamic price adjustment.
 */
async function adjustIndex() {
    try {
        // Step 1: Fetch Top 100 Market Cap from CoinGecko
        const fetchedMarketCap = await fetchTop100MarketCap();

        // Step 2: Get Current Total Supply from the Smart Contract
        const totalSupply = await contract.totalSupply();
        console.log(`Total Supply: ${ethers.utils.formatEther(totalSupply)} C100`);

        // Step 3: Calculate Current Index Market Cap
        const currentIndexCap = calculateIndexMarketCap(totalSupply);

        // Step 4: Calculate Adjustment Ratio
        const ratio = calculateAdjustmentRatio(fetchedMarketCap, currentIndexCap);

        // Step 5: Determine Mint or Burn Amount
        const { mint, burn } = determineAdjustment(ratio, totalSupply);

        // Step 6: Execute Minting or Burning
        await executeAdjustment(mint, burn);

        console.log("Index adjustment process completed.");
    } catch (error) {
        console.error("Error in adjustIndex process:", error);
    }
}

// Execute the adjustment
adjustIndex();
