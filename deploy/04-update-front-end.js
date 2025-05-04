/*const fs = require("fs")
const { network } = require("hardhat")

module.exports = async () => {
    
    await updateContractAddresses("Microcredit_Aseguradora", "./end-points/address/address_aseguradora.json")
    await updateContractAddresses("Microcredit", "./end-points/address/address_microCredit.json")
    await updateAbi("Microcredit_Aseguradora", "./end-points/abis/abi_aseguradora.json")
    await updateAbi("Microcredit", "./end-points/abis/abi_microCredit.json")
    console.log("Front end written!")
    
}


async function updateAbi(nameContract, ruta) {
    const raffle = await ethers.getContractAt(nameContract)
    fs.writeFileSync(ruta, raffle.interface.format(ethers.utils.FormatTypes.json))
}

async function updateContractAddresses(nameContract, ruta) {
    const raffle = await ethers.getContractAt(nameContract)
    const contractAddresses = JSON.parse(fs.readFileSync(ruta, "utf8"))
    if (network.config.chainId.toString() in contractAddresses) {
        if (!contractAddresses[network.config.chainId.toString()].includes(raffle.address)) {
            contractAddresses[network.config.chainId.toString()]=raffle.address
        }
    } else {
        contractAddresses[network.config.chainId.toString()] = [raffle.address]
    }
    fs.writeFileSync(ruta, JSON.stringify(contractAddresses))
}
module.exports.tags = ["all", "frontend"]*/

const fs = require("fs")
const path = require("path")
const { network, deployments, ethers } = require("hardhat")

module.exports = async () => {
    await exportContractData("Microcredit_Aseguradora", "./end-points/address/address_aseguradora.json", "./end-points/abis/abi_aseguradora.json")
    await exportContractData("Microcredit", "./end-points/address/address_microCredit.json", "./end-points/abis/abi_microCredit.json")
    console.log("Front end written!")
}

async function exportContractData(contractName, addressPath, abiPath) {
    const deployment = await deployments.get(contractName)
    const contractInstance = await ethers.getContractAt(contractName, deployment.address)

    // 🗂 Asegúrate de que las carpetas existen
    ensureDirectoryExistence(addressPath)
    ensureDirectoryExistence(abiPath)

    // ✏️ Escribir la dirección
    const chainId = network.config.chainId.toString()
    let addresses = {}
    if (fs.existsSync(addressPath)) {
        addresses = JSON.parse(fs.readFileSync(addressPath, "utf8"))
    }

    addresses[chainId] = deployment.address
    fs.writeFileSync(addressPath, JSON.stringify(addresses, null, 2))

    // ✏️ Escribir la ABI
    fs.writeFileSync(
        abiPath,
        contractInstance.interface.format(ethers.utils.FormatTypes.json)
    )
}

function ensureDirectoryExistence(filePath) {
    const dir = path.dirname(filePath)
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true })
    }
}

module.exports.tags = ["all", "frontend"]
