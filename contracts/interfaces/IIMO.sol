// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libs/Decimal.sol";

/// @title IMO interface
/// @author USDM Protocol
interface IIMO {
    struct UserInfo {
        uint256 amount; // How many MIMO tokens the user has after launch
        uint256 debt; // Debt
    }
    // ----------- Events -----------

    event Purchase(address indexed to, uint256 value);

    event Claim(address indexed to, uint256 amountIn, uint256 amountXMS);

    event Launch(uint256 timestamp);

    // ----------- Governor only state changing API -----------

    function initIMO() external;

    // ----------- State changing API -----------

    function purchase(address to, uint256 value) external payable;

    function claim(address to) external;

    function launch() external;

    function emergencyExit(address from, address payable to) external;

    // ----------- Getters -----------

    function xmsPrice() external view returns (uint256);

    function userInfo(address user) external view returns (uint256, uint256);

    function getAmountOut(uint256 amountIn, bool inclusive)
        external
        view
        returns (uint256 xmsAmount);

    function getUnClaimableAmount(address to)
        external
        view
        returns (uint256 xmsAmount);

    function getAmountsToClaim(address to)
        external
        view
        returns (uint256 xmsAmount, uint256 busdAmount);

    function totalEffectiveMIMO() external view returns (uint256);

    function supersuper() external view returns (bool);

    function launchBlock() external view returns (uint256);

    function launchTimestamp() external view returns (uint256);

    function totalSnapshotAmount() external view returns (uint256);
}
