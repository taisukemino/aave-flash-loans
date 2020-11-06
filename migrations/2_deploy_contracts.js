let FlashLoan = artifacts.require("FlashLoan")

module.exports = async function (deployer, network) {
    try {

        let lendingPoolAddressesProviderAddress;

        switch(network) {
            case "mainnet":
            case "mainnet-fork":
            case "development": // For Ganache mainnet forks
                lendingPoolAddressesProviderAddress = "0x24a42fD28C976A61Df5D00D0599C34c4f90748c8"; break
                throw Error(`Are you deploying to the correct network? (network selected: ${network})`)
        }

        await deployer.deploy(FlashLoan, lendingPoolAddressesProviderAddress)
    } catch (e) {
        console.log(`Error in migration: ${e.message}`)
    }
}