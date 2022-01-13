var XMSToken = artifacts.require("XMSToken");

var MarsStake = artifacts.require("MarsStake");
module.exports = function (deployer, network, accounts) {
    deployer.then(async () => {
        var xmsToken;
        if (network == 'mainnet') {
            xmsToken = await XMSToken.at(process.env.MAIN_DEPLOYED_XMS);
        } else if (network == 'testnet') {
            xmsToken = await XMSToken.at(process.env.TEST_DEPLOYED_XMS);
        } else {
            xmsToken = await XMSToken.at(process.env.DEV_DEPLOYED_XMS);
        }

        return deployer.deploy(MarsStake, xmsToken.address);
    });
}