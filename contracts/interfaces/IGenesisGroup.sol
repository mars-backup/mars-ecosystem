// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libs/Decimal.sol";
import "../interfaces/IBondingCurve.sol";

/// @title Genesis Group interface
/// @author USDM Protocol
interface IGenesisGroup {
    // ----------- Events -----------

    event Purchase(address indexed to, uint256 value);

    event Redeem(address indexed to, uint256 amountIn, uint256 amountUSDM);

    event Launch(uint256 timestamp, uint256 price);

    // ----------- Governor only state changing API -----------

    function initGenesis(uint256 startTime) external;

    function launch() external;

    function complete() external;

    // ----------- State changing API -----------

    function purchase(address to, uint256 value) external payable;

    function redeem(address to) external;

    function emergencyExit(address from, address payable to) external;

    // ----------- Getters -----------

    function getAmountOut(uint256 amountIn, bool inclusive)
        external
        view
        returns (uint256 usdmAmount);

    function getAmountsToRedeem(address to)
        external
        view
        returns (
            uint256 usdmAmount,
            uint256 busdAmount,
            uint256 stakeAmount
        );

    function usdmPerMGEN() external view returns (uint256);

    function supersuper() external view returns (bool);

    function launchBlock() external view returns (uint256);

    function launchTimestamp() external view returns (uint256);

    function bondingCurve() external view returns (IBondingCurve);

    function stakeToken() external view returns (IERC20);

    function stakeTokenAllocPoint() external view returns (uint256);

    function underlyingTokenAllocPoint() external view returns (uint256);

    function stakeInfo(address) external view returns (uint256);

    function durationBlocks() external view returns (uint256);
}
