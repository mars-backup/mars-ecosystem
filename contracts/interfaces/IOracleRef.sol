// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./IMarsSwapPairOracle.sol";
import "./IChainlinkLastPriceOracle.sol";
import {IUSDMGovernanceOracle} from "./IUSDMGovernanceOracle.sol";
import {IXMSCirculatingSupplyOracle} from "./IXMSCirculatingSupplyOracle.sol";
import "../libs/Decimal.sol";

/// @title OracleRef interface
/// @author USDM Protocol
interface IOracleRef {
    // ----------- Governor only state changing API -----------

    function setXMSForUSDMMROracle(address oracle) external;

    function setXMSForUSDMSupplyCapOracle(address oracle) external;

    function setUSDMGovernanceOracle(address oracle) external;

    function setXMSCirculatingSupplyOracle(address oracle) external;

    // ----------- Getters -----------

    function xmsForUSDMMROracle() external view returns (IMarsSwapPairOracle);

    function xmsForUSDMSupplyCapOracle()
        external
        view
        returns (IMarsSwapPairOracle);

    function usdmGovernanceOracle()
        external
        view
        returns (IUSDMGovernanceOracle);

    function xmsCirculatingSupplyOracle()
        external
        view
        returns (IXMSCirculatingSupplyOracle);

    function invert(Decimal.D256 calldata price)
        external
        pure
        returns (Decimal.D256 memory);
}
