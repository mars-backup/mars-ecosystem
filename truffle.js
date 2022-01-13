const HDWalletProvider = require("truffle-hdwallet-provider");

require('dotenv').config();
var Web3 = require('web3');

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // for more about customizing your Truffle configuration!
  migrations_directory: "./migrations",

  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      gasPrice: 5000000000,
      // provider: () => new Web3.providers.HttpProvider(`http://127.0.0.1:7545`),
      network_id: "*" // Match any network id
    },
    testnet: {
      provider: () => new HDWalletProvider(`${process.env.mnemonic}`, `https://data-seed-prebsc-1-s1.binance.org:8545`),
      // provider: () => new HDWalletProvider([`${process.env.private_key}`], `https://data-seed-prebsc-1-s3.binance.org:8545`),
      network_id: 97,
      gas: 6990000,
      gasPrice: 10000000000,
      confirmations: 5,
      timeoutBlocks: 3600 * 1000,
      websocket: true,
      skipDryRun: true,
      networkCheckTimeout: 3600 * 1000
    },
    mainnet: {
      // provider: () => new HDWalletProvider([`${process.env.private_key}`], `https://bsc-dataseed1.ninicoin.io/`),
      provider: () => new HDWalletProvider([`${process.env.private_key}`], `https://bsc-dataseed.binance.org`),
      network_id: 56,
      gas: 6990000,
      gasPrice: 5000000000,
      confirmations: 10,
      timeoutBlocks: 3600 * 1000,
      websocket: true,
      skipDryRun: true,
      networkCheckTimeout: 3600 * 1000
    }
  },
  compilers: {
    solc: {
      version: "0.7.6",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200 // Optimize for how many times you intend to run the code
        }
      }
    }
  },
  plugins: [
    'truffle-plugin-verify'
  ],
  api_keys: {
    etherscan: process.env.BSCSCAN_API_KEY
  }
};