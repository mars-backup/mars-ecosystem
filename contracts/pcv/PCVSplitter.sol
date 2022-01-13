// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Abstract contract for splitting PCV into different deposits
/// @author USDM Protocol
abstract contract PCVSplitter {
    using SafeMath for uint256;

    /// @notice Total allocation allowed representing 100%
    uint256 public constant ALLOCATION_GRANULARITY = 10_000;

    uint256[] private _ratios;
    address[] private _pcvDeposits;

    event AllocationUpdate(address[] pcvDeposits, uint256[] ratios);

    /// @notice PCVSplitter constructor
    /// @param pcvDeposits_ List of PCV Deposits to split to
    /// @param ratios_ Ratios for splitting PCV Deposit allocations
    constructor(address[] memory pcvDeposits_, uint256[] memory ratios_) {
        _setAllocation(pcvDeposits_, ratios_);
    }

    /// @notice Make sure an allocation has matching lengths and totals the ALLOCATION_GRANULARITY
    /// @param pcvDeposits_ New list of pcv deposits to send to
    /// @param ratios_ New ratios corresponding to the PCV deposits
    /// @return true If it is a valid allocation
    function checkAllocation(
        address[] memory pcvDeposits_,
        uint256[] memory ratios_
    ) public pure returns (bool) {
        require(
            pcvDeposits_.length == ratios_.length,
            "PCVSplitter::checkAllocation: PCV Deposits and ratios are different lengths"
        );

        uint256 total;
        for (uint256 i; i < ratios_.length; i++) {
            total = total.add(ratios_[i]);
        }

        require(
            total == ALLOCATION_GRANULARITY,
            "PCVSplitter::checkAllocation: Ratios do not total 100%"
        );

        return true;
    }

    /// @notice Gets the pcvDeposits and ratios of the splitter
    function getAllocation()
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        return (_pcvDeposits, _ratios);
    }

    /// @notice Distribute funds to single PCV deposit
    /// @param amount Amount of funds to send
    /// @param pcvDeposit The pcv deposit to send funds
    function _allocateSingle(uint256 amount, address pcvDeposit)
        internal
        virtual;

    /// @notice Sets a new allocation for the splitter
    /// @param pcvDeposits_ New list of pcv deposits to send to
    /// @param ratios_ New ratios corresponding to the PCV deposits. Must total ALLOCATION_GRANULARITY
    function _setAllocation(
        address[] memory pcvDeposits_,
        uint256[] memory ratios_
    ) internal {
        checkAllocation(pcvDeposits_, ratios_);

        _pcvDeposits = pcvDeposits_;
        _ratios = ratios_;

        emit AllocationUpdate(pcvDeposits_, ratios_);
    }

    /// @notice Distribute funds to all pcv deposits at specified allocation ratios
    /// @param total Amount of funds to send
    function _allocate(uint256 total) internal {
        uint256 granularity = ALLOCATION_GRANULARITY;
        for (uint256 i; i < _ratios.length; i++) {
            uint256 amount = total.mul(_ratios[i]) / granularity;
            _allocateSingle(amount, _pcvDeposits[i]);
        }
    }
}
