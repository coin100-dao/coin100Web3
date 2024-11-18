require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
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
  networks: {
    amoy: {
      url: process.env.AMOY_RPC_URL,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      chainId: 80002,
    },
    polygon: {
      url: process.env.POLYGON_RPC_URL,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      chainId: 137, // Polygon Mainnet Chain ID
    },
  },
  etherscan: {
    apiKey: process.env.POLYGON_ETHERSCAN_API_KEY, // Add your Polygon Etherscan API Key
  },
};
