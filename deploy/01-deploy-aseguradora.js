const { network } = require("hardhat")
const { networkConfig, developmentChains } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")
require("dotenv").config()

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { asegurador } = await getNamedAccounts()
    const chainId = network.config.chainId

    /*let ethUsdPriceFeedAddress
    if (chainId == 31337) {
        const ethUsdAggregator = await deployments.get("MockV3Aggregator")
        ethUsdPriceFeedAddress = ethUsdAggregator.address
    } else {
        ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"]
    }*/

    log("----------------------------------------------------")
    log("Deploying Aseguradora and waiting for confirmations...")
    const Aseguradora = await deploy("Microcredit_Aseguradora", {
        from: asegurador,
        args: [],
        log: true,
        // we need to wait if on a live network so we can verify properly
        waitConfirmations: network.config.blockConfirmations || 1,
    })
    log(`Aseguradora deployed at ${Aseguradora.address}`)

    if (!developmentChains.includes(network.name) && process.env.SNOWSCAN_API_KEY) {
        await verify(Aseguradora.address, [])
    }
}

module.exports.tags = ["all", "aseguradora"]