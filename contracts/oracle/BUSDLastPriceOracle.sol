// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "../interfaces/IChainlinkLastPriceOracle.sol";

contract BUSDLastPriceOracle is IChainlinkLastPriceOracle {
    AggregatorV3Interface internal _priceFeed;
    address public override token;

    /**
     * Network: Mainnet
     * Aggregator: BUSD/USD
     * Address: 0xcBb98864Ef56E9042e7d2efef76141f15731B82f(Mainnet)
     * Address: 0x9331b55D9830EF609A2aBCfAc0FBCE050A52fdEa(Testnet)
     */
    constructor(address _address, address _busd) {
        _priceFeed = AggregatorV3Interface(_address);
        token = _busd;
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view override returns (uint256, uint8) {
        (
            ,
            // uint80 roundID
            int256 price, // uint startedAt // uint timeStamp // uint80 answeredInRound
            ,
            ,

        ) = _priceFeed.latestRoundData();
        require(price > 0, "BUSDLastPriceOracle::getLatestPrice: Price wrong");
        return (uint256(price), _priceFeed.decimals());
    }
}
