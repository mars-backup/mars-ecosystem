// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/IMarsSwapFactory.sol";

interface ISwapMiningOracle {
    struct Observation {
        uint32 blockTimestampLast;
        uint256 price0CumulativeLast;
        uint256 price1CumulativeLast;
        bool added;
    }

    // ----------- Governor only state changing API -----------

    function setPeriod(uint256 period) external;

    function setFactory(address) external;

    function addPair(address pair) external;

    function removePair(address pair) external;

    // ----------- State changing api -----------

    function update(address pair) external;

    function consult(
        address tokenIn,
        uint256 amountIn,
        address tokenOut
    ) external view returns (uint256 amountOut);

    // ----------- Getters -----------

    function PERIOD() external view returns (uint256);

    function factory() external view returns (IMarsSwapFactory);

    function pairs(uint256 idx) external view returns (address pair);

    function getPairsLength() external view returns (uint256);
}
