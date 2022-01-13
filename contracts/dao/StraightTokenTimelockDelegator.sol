// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./LinearTokenTimelockDelegator.sol";
import "../utils/StraightTokenTimelock.sol";
import "../utils/Delegatee.sol";

/// @title A timelock for XMS allowing for sub-delegation
/// @author USDM Protocol
/// @notice Allows the timelock XMS to be delegated by the beneficiary while locked
contract StraightTokenTimelockDelegator is
    LinearTokenTimelockDelegator,
    StraightTokenTimelock
{
    using SafeMath for uint256;

    /// @notice StraightTokenTimelockDelegator constructor
    /// @param _xms The XMS token address
    /// @param _beneficiary Default delegate, admin, and timelock beneficiary
    /// @param _startTime Start of the token timelock window
    /// @param _duration Duration of the token timelock window
    constructor(
        address _xms,
        address _beneficiary,
        uint256 _startTime,
        uint256 _duration
    )
        LinearTokenTimelockDelegator(_xms, _beneficiary)
        StraightTokenTimelock(_beneficiary, _startTime, _duration, _xms)
    {}

    /// @notice Delegate locked XMS to a delegatee
    /// @param delegatee The target address to delegate to
    /// @param amount The amount of XMS to delegate. Will increment existing delegated XMS
    function delegate(address delegatee, uint256 amount)
        public
        override
        onlyBeneficiary
    {
        _delegate(delegatee, amount);
    }

    /// @notice Return delegated XMS to the timelock
    /// @param delegatee The target address to undelegate from
    /// @return The amount of XMS returned
    function undelegate(address delegatee)
        public
        override
        onlyBeneficiary
        returns (uint256)
    {
        return _undelegate(delegatee);
    }

    /// @notice Calculate total XMS held plus delegated
    /// @dev Used by LinearTokenTimelock to determine the released amount
    function totalToken()
        public
        view
        override(LinearTokenTimelockDelegator, LinearTokenTimelock)
        returns (uint256)
    {
        return LinearTokenTimelockDelegator.totalToken();
    }

    /// @notice Accept beneficiary role over timelock XMS. Delegates all held (non-subdelegated) xms to beneficiary
    function acceptBeneficiary()
        public
        override(LinearTokenTimelockDelegator, LinearTokenTimelock)
    {
        _setBeneficiary(msg.sender);
        xms.delegate(msg.sender);
    }
}
