// scripts/deploy.js

const { ethers } = require("hardhat");
require("dotenv").config();

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const COIN100 = await ethers.getContractFactory("COIN100");
    const coin100 = await COIN100.deploy(process.env.DEVELOPER_WALLET, process.env.LIQUIDITY_WALLET);

    await coin100.deployed();
    console.log("COIN100 deployed to:", coin100.address);
    console.log(coin100);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
