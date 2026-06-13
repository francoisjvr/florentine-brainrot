import "@nomicfoundation/hardhat-toolbox";
import dotenv from "dotenv";

dotenv.config();

const privateKey = process.env.PRIVATE_KEY || "";
const accounts = privateKey ? [privateKey] : [];
const mainnetRpc = process.env.ETHEREUM_RPC_URL || process.env.MAINNET_RPC_URL || "";
const sepoliaRpc = process.env.SEPOLIA_RPC_URL || "";

export default {
  solidity: {
    version: "0.8.25",
    settings: {
      optimizer: { enabled: true, runs: 1 },
      viaIR: true,
      evmVersion: "cancun"
    }
  },
  paths: {
    sources: "./src",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  networks: {
    hardhat: { chainId: 31337 },
    mainnet: {
      url: mainnetRpc,
      chainId: 1,
      accounts
    },
    sepolia: {
      url: sepoliaRpc,
      chainId: 11155111,
      accounts
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY || ""
  }
};
