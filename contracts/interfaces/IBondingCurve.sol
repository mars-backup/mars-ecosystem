// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../libs/Decimal.sol";

interface IBondingCurve {
    // ----------- Events -----------

    event IncentiveAmountUpdate(uint256 incentiveAmount);

    event Purchase(address indexed to, uint256 amountIn, uint256 amountOut);

    event Allocate(address indexed caller, uint256 amount);

    // ----------- State changing Api -----------

    function purchase(
        address to,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline
    ) external payable returns (uint256 amountOut);

    function allocate() external;

    // ----------- Governor only state changing api -----------

    function setAllocation(
        address[] calldata pcvDeposits,
        uint256[] calldata ratios
    ) external;

    function setFee(uint256) external;

    function setIncentiveAmount(uint256) external;

    // ----------- Getters -----------

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

    function getTotalPCVHeld() external view returns (uint256);

    function incentiveAmount() external view returns (uint256);
}
