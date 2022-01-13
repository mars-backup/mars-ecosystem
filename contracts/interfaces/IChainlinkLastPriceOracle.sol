// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IChainlinkLastPriceOracle {
    function token() external view returns (address);

    function getLatestPrice() external view returns (uint256, uint8);
}
