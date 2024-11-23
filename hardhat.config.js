require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomicfoundation/hardhat-verify");
require("dotenv").config();

module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  etherscan: {
    apiKey: process.env.POLYGON_ETHERSCAN_API_KEY, // For verification on Polygon Etherscan
  },
  networks: {
    amoy: {
      url: process.env.AMOY_RPC_URL,
      accounts: [
        process.env.DEVELOPER_WALLET_PRIVATE_KEY.startsWith("0x")
          ? process.env.DEVELOPER_WALLET_PRIVATE_KEY
          : `0x${process.env.DEVELOPER_WALLET_PRIVATE_KEY}`,
        process.env.LIQUIDITY_WALLET_PRIVATE_KEY.startsWith("0x")
          ? process.env.LIQUIDITY_WALLET_PRIVATE_KEY
          : `0x${process.env.LIQUIDITY_WALLET_PRIVATE_KEY}`,
      ],
      chainId: 80002,
    },
    polygon: {
      url: process.env.POLYGON_RPC_URL,
      accounts: [
        process.env.DEVELOPER_WALLET_PRIVATE_KEY.startsWith("0x")
          ? process.env.DEVELOPER_WALLET_PRIVATE_KEY
          : `0x${process.env.DEVELOPER_WALLET_PRIVATE_KEY}`,
        process.env.LIQUIDITY_WALLET_PRIVATE_KEY.startsWith("0x")
          ? process.env.LIQUIDITY_WALLET_PRIVATE_KEY
          : `0x${process.env.LIQUIDITY_WALLET_PRIVATE_KEY}`,
      ],
      chainId: 137, // Polygon Mainnet Chain ID
    },
    localhost: {
      url: "http://127.0.0.1:8545/",
      accounts: [
        "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199", // Sample Private Key
      ],
    },
  },
};
