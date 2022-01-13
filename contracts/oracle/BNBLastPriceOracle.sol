// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "../interfaces/IChainlinkLastPriceOracle.sol";

contract BNBLastPriceOracle is IChainlinkLastPriceOracle {
    AggregatorV3Interface internal _priceFeed;
    address public override token;

    /**
     * Network: Mainnet
     * Aggregator: BNB/USD
     * Address: 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE(Mainnet)
     * Address: 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526(Testnet)
     */
    constructor(address _address, address _wbnb) {
        _priceFeed = AggregatorV3Interface(_address);
        token = _wbnb;
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
        require(price > 0, "BNBLastPriceOracle::getLatestPrice: Price wrong");
        return (uint256(price), _priceFeed.decimals());
    }
}
