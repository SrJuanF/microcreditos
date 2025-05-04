const { network } = require("hardhat")
const { networkConfig, developmentChains } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")
require("dotenv").config()

module.exports = async ({ getNamedAccounts, deployments, ethers }) => {
    const { deploy, log, get } = deployments
    const { deployer, asegurador } = await getNamedAccounts()
    const chainId = network.config.chainId

    let ethUsdPriceFeedAddress
    if (chainId == 31337) {
        const ethUsdAggregator = await deployments.get("MockV3Aggregator")
        ethUsdPriceFeedAddress = ethUsdAggregator.address
    } else {
        ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"]
    }
    
    // 💡 Obtener el signer correspondiente
    const aseguradorSigner = await ethers.getSigner(asegurador);
    // 💡 Obtener dirección del contrato desplegado
    const aseguradoraDeployment = await get("Microcredit_Aseguradora");
    // 💡 Conectar el contrato con el signer de la cuenta aseguradora
    const aseguradoraInstance = await ethers.getContractAt(
        "Microcredit_Aseguradora",
        aseguradoraDeployment.address,
        aseguradorSigner
    );
    
    log("----------------------------------------------------")
    log("Deploying Microcredit and waiting for confirmations...")

    const Microcreditt = await deploy("Microcredit", {
        from: deployer,
        args: [150000, 15000, 10, 13, 15, 30, aseguradoraInstance.address, 6, ethUsdPriceFeedAddress],
        log: true,
        // we need to wait if on a live network so we can verify properly
        waitConfirmations: network.config.blockConfirmations || 1,
    })
    log(`Microcredit deployed at ${Microcreditt.address}`)

    if (!developmentChains.includes(network.name) && process.env.SNOWSCAN_API_KEY) {
        await verify(Microcreditt.address, [150000, 15000, 10, 13, 15, 30, aseguradoraInstance.address, 6, ethUsdPriceFeedAddress])
    }

    log(`-------------------------------------------------------------`)
    const tx = await aseguradoraInstance.setCustomer_Microcredits(Microcreditt.address);
    await tx.wait(1);
    log("Contrato Microcredit registrado exitosamente en Aseguradora.");

}

module.exports.tags = ["all", "microcredit"]