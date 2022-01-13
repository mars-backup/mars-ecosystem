// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./IPCVDeposit.sol";
import "./IBondingCurve.sol";

/// @title A PCV Controller interface
/// @author USDM Protocol
interface IPCVController {
    // ----------- Events -----------

    event Withdraw(address indexed to, uint256 amount);

    event PCVDepositUpdate(address indexed pcvDeposit);

    // ----------- State changing API -----------

    // ----------- Governor only state changing API -----------

    function recycle(uint256) external;

    function withdraw(uint256) external;

    function deposit(uint256) external;

    function setPCVDeposit(address) external;

    // ----------- Getters -----------

    function pcvDeposit() external view returns (IPCVDeposit);

    function bondingCurve() external view returns (address);
}
