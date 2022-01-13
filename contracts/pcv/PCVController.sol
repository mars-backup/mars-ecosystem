// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/IPCVController.sol";
import "../refs/CoreRef.sol";

/// @title A IPCVController implementation
/// @author USDM Protocol
abstract contract PCVController is IPCVController, CoreRef {
    /// @notice Returns the linked pcv deposit contract
    IPCVDeposit public override pcvDeposit;

    address public immutable override bondingCurve;

    /// @notice PCVController constructor
    /// @param _core USDM Core for reference
    /// @param _pcvDeposit PCV Deposit
    /// @param _bondingCurve BondingCurve
    constructor(
        address _core,
        address _pcvDeposit,
        address _bondingCurve
    ) CoreRef(_core) {
        require(
            _pcvDeposit != address(0),
            "PCVController::constructor: Zero address"
        );
        pcvDeposit = IPCVDeposit(_pcvDeposit);
        require(
            _bondingCurve != address(0),
            "PCVController::constructor: Zero address"
        );
        bondingCurve = _bondingCurve;
    }

    /// @notice Recycle
    function recycle(uint256 _amount) external virtual override;

    /// @notice Withdraw
    function withdraw(uint256 _amount)
        external
        override
        onlyGuardianOrGovernor
    {
        _withdraw(_amount);
    }

    /// @notice Deposit
    function deposit(uint256 _amount) external override onlyGuardianOrGovernor {
        _deposit(_amount);
    }

    /// @notice Sets the target PCV Deposit address
    function setPCVDeposit(address _pcvDeposit) external override onlyGovernor {
        pcvDeposit = IPCVDeposit(_pcvDeposit);
        emit PCVDepositUpdate(_pcvDeposit);
    }

    function _withdraw(uint256 _amount) internal {
        uint256 value = pcvDeposit.totalValue();
        require(_amount <= value, "PCVController::_withdraw: Not enough token");
        pcvDeposit.withdraw(value);
    }

    function _deposit(uint256 _amount) internal virtual;
}
