// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libs/Decimal.sol";

/// @title Genesis Event interface
/// @author USDM Protocol
interface IGenesisEvent {
    // ----------- Events -----------

    event Purchase(address indexed to, uint256 value);

    event Claim(
        address indexed to,
        uint256 amountIn,
        uint256 amountOut,
        uint256 amountRefund,
        uint256 amountStake
    );

    event Launch(uint256 timestamp, uint256 routeAPrice, uint256 routeBPrice);

    // ----------- Governor only state changing API -----------

    function initGenesisEvent(uint256 startTime) external;

    // ----------- State changing API -----------

    function purchase(address to, uint256 value) external payable;

    function claim(address to) external;

    function launch() external;

    function emergencyExit(address from, address payable to) external;

    // ----------- Getters -----------

    function cap() external view returns (uint256);

    function stakeToken() external view returns (IERC20);

    function stakeTokenAllocPoint() external view returns (uint256);

    function underlyingTokenAllocPoint() external view returns (uint256);

    function durationBlocks() external view returns (uint256);

    function underlyingPrice()
        external
        view
        returns (
            Decimal.D256 memory,
            uint256,
            uint256
        );

    function stakeInfo(address user) external view returns (uint256);

    function getAmountOut(uint256 amountIn, bool inclusive)
        external
        view
        returns (uint256 usdmAmount);

    function getAmountsToClaim(address to)
        external
        view
        returns (
            uint256 usdmAmount,
            uint256 underlyingAmount,
            uint256 stakeAmount
        );

    function usdmPerMGEN() external view returns (uint256);

    function supersuper() external view returns (bool);

    function launchBlock() external view returns (uint256);

    function launchTimestamp() external view returns (uint256);
}
