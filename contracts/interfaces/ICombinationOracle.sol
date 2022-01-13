// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/IChainlinkLastPriceOracle.sol";

// Combination Oracle
interface ICombinationOracle {
    struct Router {
        address[] path;
        IChainlinkLastPriceOracle oracle;
    }

    // ----------- Governor only state changing API -----------

    function setRouter(address oracle, address[] memory path) external;

    // ----------- Getters -----------

    function getRouter() external view returns (Router memory);
}
