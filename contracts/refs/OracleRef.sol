// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/IOracleRef.sol";
import "../interfaces/IMarsSwapPairOracle.sol";
import "./CoreRef.sol";

/// @title Reference to an Oracle
/// @author USDM Protocol
/// @notice Defines some utilities around interacting with the referenced oracle
abstract contract OracleRef is IOracleRef, CoreRef {
    using Decimal for Decimal.D256;

    /// @notice The referenced uniswap oracle price
    IMarsSwapPairOracle public override xmsForUSDMMROracle;

    /// @notice The referenced uniswap oracle price
    IMarsSwapPairOracle public override xmsForUSDMSupplyCapOracle;

    IUSDMGovernanceOracle public override usdmGovernanceOracle;

    IXMSCirculatingSupplyOracle public override xmsCirculatingSupplyOracle;

    /// @notice OracleRef constructor
    /// @param _oracle Oracle to reference
    constructor(address[] memory _oracle) {
        _setXMSForUSDMMROracle(_oracle[0]);
        _setXMSForUSDMSupplyCapOracle(_oracle[1]);
        _setUSDMGovernanceOracle(_oracle[2]);
        _setXMSCirculatingSupplyOracle(_oracle[3]);
    }

    /// @notice Sets the referenced oracle
    /// @param _oracle The new oracle to reference
    function setXMSForUSDMMROracle(address _oracle)
        external
        override
        onlyGovernor
    {
        _setXMSForUSDMMROracle(_oracle);
    }

    /// @notice Sets the referenced oracle
    /// @param _oracle The new oracle to reference
    function setXMSForUSDMSupplyCapOracle(address _oracle)
        external
        override
        onlyGovernor
    {
        _setXMSForUSDMSupplyCapOracle(_oracle);
    }

    function setUSDMGovernanceOracle(address _oracle)
        external
        override
        onlyGovernor
    {
        _setUSDMGovernanceOracle(_oracle);
    }

    function setXMSCirculatingSupplyOracle(address _oracle)
        external
        override
        onlyGovernor
    {
        _setXMSCirculatingSupplyOracle(_oracle);
    }

    /// @notice Invert a price
    /// @param price The price to invert
    /// @return The inverted price as a Decimal
    function invert(Decimal.D256 memory price)
        public
        pure
        virtual
        override
        returns (Decimal.D256 memory)
    {
        return Decimal.one().div(price);
    }

    // USD per XMS
    function getXMSPrice() public view returns (Decimal.D256 memory amountOut) {
        require(
            address(xmsForUSDMMROracle) != address(0),
            "OracleRef::getXMSPrice: No oracle"
        );
        amountOut = xmsForUSDMMROracle.consult(10**xms().decimals());
    }

    function getUSDMSupplyCap() public view returns (uint256 cap) {
        require(
            address(xmsForUSDMSupplyCapOracle) != address(0) &&
                address(xmsCirculatingSupplyOracle) != address(0) &&
                address(usdmGovernanceOracle) != address(0),
            "OracleRef::getUSDMSupplyCap: No oracle"
        );
        Decimal.D256 memory amountOut = xmsForUSDMSupplyCapOracle.consult(
            10**xms().decimals()
        );

        uint256 xmsCirculatingSupply = xmsCirculatingSupplyOracle.consult();
        Decimal.D256 memory xmsFDV = amountOut.mul(xmsCirculatingSupply);
        cap = xmsFDV
            .mul(core().xmsSupportRatioPrecision())
            .div(core().xmsSupportRatio())
            .asUint256();

        cap = cap + usdmGovernanceOracle.consult();
    }

    function _setXMSForUSDMMROracle(address _oracle) internal {
        xmsForUSDMMROracle = IMarsSwapPairOracle(_oracle);
    }

    function _setXMSForUSDMSupplyCapOracle(address _oracle) internal {
        xmsForUSDMSupplyCapOracle = IMarsSwapPairOracle(_oracle);
    }

    function _setUSDMGovernanceOracle(address _oracle) internal {
        usdmGovernanceOracle = IUSDMGovernanceOracle(_oracle);
    }

    function _setXMSCirculatingSupplyOracle(address _oracle) internal {
        xmsCirculatingSupplyOracle = IXMSCirculatingSupplyOracle(_oracle);
    }
}
