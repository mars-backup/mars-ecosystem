// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "../interfaces/IChainlinkLastPriceOracle.sol";

contract MockBUSDLastPriceOracle is IChainlinkLastPriceOracle {
    address public override token;

    constructor(address _address, address _token) {
        token = _token;
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public pure override returns (uint256, uint8) {
        return (uint256(105000000), uint8(8));
    }
}
