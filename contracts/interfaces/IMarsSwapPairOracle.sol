// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/IMarsSwapFactory.sol";
import "../libs/Decimal.sol";
import "../libs/FixedPoint.sol";

interface IMarsSwapPairOracle {
    struct Observation {
        uint32 blockTimestampLast;
        uint256 price0CumulativeLast;
        uint256 price1CumulativeLast;
        uint256 timeElapsed;
        FixedPoint.uq112x112 price0Average;
        FixedPoint.uq112x112 price1Average;
    }

    // ----------- Governor only state changing API -----------

    function setPeriod(uint256) external;

    function setOverrun(uint256) external;

    function setFactory(address) external;

    // ----------- State changing api -----------

    function update() external;

    function consult(uint256 amountIn)
        external
        view
        returns (Decimal.D256 memory amountOut);

    // ----------- Getters -----------

    function PERIOD() external view returns (uint256);

    function OVERRUN() external view returns (uint256);

    function factory() external view returns (IMarsSwapFactory);
}
