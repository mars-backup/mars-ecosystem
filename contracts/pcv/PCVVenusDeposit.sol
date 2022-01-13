// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/IPCVVenusDeposit.sol";
import "../refs/CoreRef.sol";

/// @title Abstract implementation for Venus PCV Deposit
/// @author USDM Protocol
abstract contract PCVVenusDeposit is IPCVVenusDeposit, CoreRef {
    /// @notice Uniswap PCV Deposit constructor
    /// @param _core USDM Core for reference
    constructor(address _core) CoreRef(_core) {}

    /// @notice Withdraw tokens from the PCV allocation
    /// @param _amount Amount of tokens withdrawn
    function withdraw(uint256 _amount) external override onlyPCVController {
        _transferWithdrawn(msg.sender, _amount);
        emit Withdrawal(msg.sender, msg.sender, _amount);
    }

    function leaveSupply(uint256 liquidity)
        external
        override
        onlyPCVController
    {
        _leaveSupply(liquidity);
        emit LeaveSupply(msg.sender, liquidity);
    }

    function harvest() external override onlyPCVController {
        uint256 amountOut = _harvest();
        emit Harvest(msg.sender, amountOut);
    }

    function _supply(uint256 amount) internal virtual;

    function _leaveSupply(uint256 liquidity) internal virtual;

    function _harvest() internal virtual returns (uint256);

    function _transferWithdrawn(address to, uint256 amount) internal virtual;
}
