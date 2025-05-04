require("@nomiclabs/hardhat-waffle")
require("hardhat-gas-reporter")
require("@nomiclabs/hardhat-etherscan")
require("dotenv").config()
require("solidity-coverage")
require("hardhat-deploy")

//to set up https://hardhat.org/config/ to learn more

const PRIVATE_KEY_A = process.env.PRIVATE_KEY_A || ""
const PRIVATE_KEY_AS= process.env.PRIVATE_KEY_AS || ""

const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || ""
const SNOWSCAN_API_KEY = process.env.SNOWSCAN_API_KEY || ""
const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY || ""

module.exports = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            chainId: 31337,
            // gasPrice: 130000000000,
        },
        sepolia: {
            url: process.env.SEPOLIA_RPC_URL,
            accounts: [PRIVATE_KEY_A, PRIVATE_KEY_AS],
            chainId: 11155111,
            blockConfirmations: 2,
        },
        fuji: {
            url: process.env.AVALANCHE_FUJI_RPC_URL,
            accounts: [PRIVATE_KEY_A, PRIVATE_KEY_AS],
            chainId: 43113,
            blockConfirmations: 2,
        }
    },
    solidity: {
        compilers: [
            {
                version: "0.8.20",
            },
            {
                version: "0.8.6",
            },
        ],
    },
    etherscan: {
        apiKey: {
            sepolia: ETHERSCAN_API_KEY,
            avalancheFujiTestnet: SNOWSCAN_API_KEY
        },
        customChains: [
            {
              network: "avalancheFujiTestnet",
              chainId: 43113,
              urls: {
                apiURL: "https://api-testnet.snowtrace.io/api",
                browserURL: "https://testnet.snowtrace.io"
              }
            }
        ]
    },
    gasReporter: {
        enabled: true,
        currency: "USD",
        outputFile: "gas-report.txt",
        noColors: true,
        coinmarketcap: COINMARKETCAP_API_KEY,
    },
    namedAccounts: {
        deployer: {
            default: 0, // here this will by default take the first account as deployer
            1: 0, // similarly on mainnet it will take the first account as deployer. Note though that depending on how hardhat network are configured, the account 0 on one network can be different than on another
        },
        asegurador:{
            default: 1,
            1: 1,
        }
    },
    mocha: {
        timeout: 200000, // 200 seconds max for running tests
    },
}

