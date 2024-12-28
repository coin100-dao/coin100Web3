// hardhat.config.js
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require('dotenv').config();

const { PRIVATE_KEY, POLYGON_RPC_URL } = process.env;

module.exports = {
  solidity: "0.8.28",
  networks: {
    hardhat: {
      forking: {
        url: POLYGON_RPC_URL || "https://polygon-rpc.com/",
        blockNumber: 42700000, // Optional: specify a block number to fork from
      },
      chainId: 137,
    },
    polygon: {
      url: POLYGON_RPC_URL || "https://polygon-rpc.com/",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
  },
};
