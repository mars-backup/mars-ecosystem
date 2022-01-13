// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../libs/Decimal.sol";

interface IRedemptionUnit {
    // ----------- Events -----------

    event Purchase(address indexed to, uint256 amountIn, uint256 amountOut);

    // ----------- State changing Api -----------

    function purchase(
        address to,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline
    ) external payable returns (uint256 amountOut);

    // ----------- Governor only state changing API -----------
    function recycle(uint256) external;

    function setFee(uint256) external;

    function setDevAddress(address) external;

    // ----------- Getters -----------

    function devAddress() external view returns (address);

    function fee() external view returns (uint256);

    function feePrecision() external view returns (uint256);

    function getCurrentPrice() external view returns (Decimal.D256 memory);

    function getAmountOut(uint256 amountIn)
        external
        view
        returns (uint256 amountOut);

    function getAmountIn(uint256 amountOut)
        external
        view
        returns (uint256 amountIn);

    function getTotalAssetHeld() external view returns (uint256);
}
