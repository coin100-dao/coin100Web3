/* eslint-disable no-undef */
// hardhat.config.js
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("dotenv").config();

const PRIVATE_KEY = "6333e92d436ede7fa755bab070e1c2cfa43c96c91d3c626f96e4d8888b25417e";
const AMOY_RPC_URL = "https://rpc-amoy.polygon.technology/";

const config = {
  solidity: "0.8.28",
  networks: {
    hardhat: {
      chainId: 31337
    },
    amoy: {
      url: AMOY_RPC_URL,
      accounts: [PRIVATE_KEY],
      chainId: 80002,
      gasPrice: "auto",
      timeout: 60000 // 1 minute timeout
    }
  },
  mocha: {
    timeout: 100000
  }
};

module.exports = config;
