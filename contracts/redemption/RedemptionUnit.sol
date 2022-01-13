// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/IRedemptionUnit.sol";
import "../refs/CoreRef.sol";

/// @title Redeem USDM unit
/// @author USDM Protocol
abstract contract RedemptionUnit is IRedemptionUnit, CoreRef {
    using Decimal for Decimal.D256;

    address public override devAddress;

    constructor(address _core, address _devAddress) CoreRef(_core) {
        require(
            _devAddress != address(0),
            "RedemptionUnit::constructor: Zero address"
        );
        devAddress = _devAddress;
    }

    modifier ensure(uint256 _deadline) {
        require(
            _deadline >= block.timestamp,
            "RedemptionUnit::ensure: Expired"
        );
        _;
    }

    /// @notice Return amount of XMS received after redeem
    /// @param amountIn The amount of underlying used to purchase
    /// @return amountOut The amount of XMS received
    function getAmountOut(uint256 amountIn)
        public
        view
        virtual
        override
        returns (uint256 amountOut);

    /// @notice Send XMS to buyer destination
    function _purchase(uint256 _amountIn, address _to)
        internal
        returns (uint256 amountOut)
    {
        amountOut = getAmountOut(_amountIn);
        require(
            xms().transfer(_to, amountOut),
            "RedemptionUnit::_purchase: Transfer failed"
        );

        emit Purchase(_to, _amountIn, amountOut);

        return amountOut;
    }

    function setDevAddress(address _devAddress) public override onlyGovernor {
        require(
            _devAddress != address(0),
            "RedemptionUnit::setDevAddress: Zero address"
        );
        devAddress = _devAddress;
    }
}
