// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./IPCVDeposit.sol";

/// @title A Venus PCV Deposit interface
/// @author USDM Protocol
interface IPCVVenusDeposit is IPCVDeposit {
    // ----------- Events -----------

    event LeaveSupply(address indexed caller, uint256 liquidity);

    event Harvest(address indexed caller, uint256 amount);

    // ----------- PCV Controller only state changing api -----------

    function leaveSupply(uint256 liquidity) external;

    function harvest() external;
}
