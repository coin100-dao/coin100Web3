// hardhat.config.js
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers";
import * as dotenv from "dotenv";
import { process } from 'process';

dotenv.config();

const { PRIVATE_KEY, POLYGON_RPC_URL } = process.env;

const config = {
  solidity: "0.8.28",
  networks: {
    hardhat: {
      forking: {
        url: POLYGON_RPC_URL || "https://polygon-rpc.com/",
      },
      chainId: 137,
    },
    polygon: {
      url: POLYGON_RPC_URL || "https://polygon-rpc.com/",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
  },
};

export default config;
