// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/ITokenTimelockDelegator.sol";
import "../utils/Delegatee.sol";

/// @title A timelock for XMS allowing for sub-delegation
/// @author USDM Protocol
/// @notice Allows the timelock XMS to be delegated by the beneficiary while locked
abstract contract LinearTokenTimelockDelegator is ITokenTimelockDelegator {
    using SafeMath for uint256;

    /// @notice Associated delegate proxy contract for a delegatee
    mapping(address => address) public override delegateContract;

    /// @notice Associated delegated amount of XMS for a delegatee
    /// @dev Using as source of truth to prevent accounting errors by transferring to Delegate contracts
    mapping(address => uint256) public override delegateAmount;

    /// @notice The XMS token contract
    IXMSToken public override xms;

    /// @notice The total delegated amount of XMS
    uint256 public override totalDelegated;

    /// @notice LinearTokenTimelockDelegator constructor
    /// @param _xms The XMS token address
    /// @param _beneficiary Default delegate, admin, and timelock beneficiary
    constructor(address _xms, address _beneficiary) {
        xms = IXMSToken(_xms);
        xms.delegate(_beneficiary);
    }

    /// @notice Delegate locked XMS to a delegatee
    /// @param delegatee The target address to delegate to
    /// @param amount The amount of XMS to delegate. Will increment existing delegated XMS
    function delegate(address delegatee, uint256 amount)
        public
        virtual
        override;

    /// @notice Return delegated XMS to the timelock
    /// @param delegatee The target address to undelegate from
    /// @return The amount of XMS returned
    function undelegate(address delegatee)
        public
        virtual
        override
        returns (uint256);

    function _delegate(address delegatee, uint256 amount) internal {
        require(
            amount <= _xmsBalance(),
            "LinearTokenTimelockDelegator::_delegate: Not enough XMS"
        );

        // Withdraw and include an existing delegation
        if (delegateContract[delegatee] != address(0)) {
            amount = amount.add(undelegate(delegatee));
        }

        IXMSToken _xms = xms;
        address _delegateContract =
            address(new Delegatee(delegatee, address(_xms)));
        delegateContract[delegatee] = _delegateContract;

        delegateAmount[delegatee] = amount;
        totalDelegated = totalDelegated.add(amount);

        require(
            _xms.transfer(_delegateContract, amount),
            "LinearTokenTimelockDelegator::_delegate: Transfer failed"
        );

        emit Delegate(delegatee, amount);
    }

    function _undelegate(address delegatee) internal returns (uint256) {
        address _delegateContract = delegateContract[delegatee];
        require(
            _delegateContract != address(0),
            "LinearTokenTimelockDelegator::_undelegate: Delegate contract nonexistent"
        );

        Delegatee(_delegateContract).withdraw();

        uint256 amount = delegateAmount[delegatee];
        totalDelegated = totalDelegated.sub(amount);

        delete delegateContract[delegatee];
        delete delegateAmount[delegatee];

        emit Undelegate(delegatee, amount);

        return amount;
    }

    /// @notice Calculate total XMS held plus delegated
    /// @dev Used by LinearTokenTimelock to determine the released amount
    function totalToken() public view virtual returns (uint256) {
        return _xmsBalance().add(totalDelegated);
    }

    /// @notice Accept beneficiary role over timelock XMS. Delegates all held (non-subdelegated) xms to beneficiary
    function acceptBeneficiary() public virtual;

    function _xmsBalance() internal view returns (uint256) {
        return xms.balanceOf(address(this));
    }
}
