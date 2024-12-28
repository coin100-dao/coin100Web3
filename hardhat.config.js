// hardhat.config.js
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("dotenv").config();

const { PRIVATE_KEY, POLYGON_RPC_URL } = process.env;

const config = {
  solidity: "0.8.28",
  networks: {
    hardhat: {
      chainId: 31337
    },
    polygon: {
      url: POLYGON_RPC_URL || "https://polygon-rpc.com/",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
  },
};

module.exports = config;
