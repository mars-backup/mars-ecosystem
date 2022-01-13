// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./RedemptionUnit.sol";
import "../refs/OracleRef.sol";

/// @title Redeem USDM unit
/// @author USDM Protocol
contract XMSRedemptionUnit is RedemptionUnit, OracleRef {
    using Decimal for Decimal.D256;
    using SafeMath for uint256;

    /// @notice Fee
    uint256 public override fee = 9970;
    /// @notice Fee precision
    uint256 public constant override feePrecision = 10000;

    constructor(
        address _core,
        address _devAddress,
        address[] memory _oracle
    ) RedemptionUnit(_core, _devAddress) OracleRef(_oracle) {
        _pause();
    }

    /// @notice Recycle
    function recycle(uint256 _amount) external override onlyGuardianOrGovernor {
        require(
            xms().transfer(devAddress, _amount),
            "XMSRedemptionUnit::recycle: Transfer failed"
        );
    }

    /// @notice Return current instantaneous bonding curve price
    /// @return Price reported as XMS per USDM with USDM being the underlying asset
    function getCurrentPrice()
        public
        view
        override
        returns (Decimal.D256 memory)
    {
        Decimal.D256 memory xmsPrice = getXMSPrice();
        return invert(xmsPrice);
    }

    /// @notice Return amount of XMS received after redeem
    /// @param _amountIn The amount of underlying used to purchase
    /// @return amountOut The amount of XMS received
    function getAmountOut(uint256 _amountIn)
        public
        view
        override
        returns (uint256 amountOut)
    {
        amountOut = getCurrentPrice().mul(_amountIn).asUint256().mul(fee).div(
            feePrecision
        );
    }

    /// @notice Return amount of USDM purchased after redeem
    /// @param _amountOut The amount of XMS received
    /// @return amountIn The amount of underlying used to purchase
    function getAmountIn(uint256 _amountOut)
        public
        view
        override
        returns (uint256 amountIn)
    {
        amountIn = invert(getCurrentPrice())
            .mul(_amountOut)
            .asUint256()
            .mul(feePrecision)
            .div(fee);
    }

    /// @notice Purchase USDM for underlying tokens
    /// @param _to Address to receive XMS
    /// @param _amountIn Amount of underlying tokens input
    /// @param _amountOutMin Min amount of XMS received
    /// @param _deadline Deadline
    /// @return amountOut Amount of XMS received
    function purchase(
        address _to,
        uint256 _amountIn,
        uint256 _amountOutMin,
        uint256 _deadline
    )
        external
        payable
        override
        postGenesis
        whenNotPaused
        ensure(_deadline)
        returns (uint256 amountOut)
    {
        require(msg.value == 0, "XMSRedemptionUnit::purchase: No need BNB");
        require(
            usdm().transferFrom(msg.sender, address(this), _amountIn),
            "XMSRedemptionUnit::purchase: TransferFrom failed"
        );
        amountOut = _purchase(_amountIn, _to);
        require(
            amountOut >= _amountOutMin,
            "XMSRedemptionUnit::purchase: Insufficient amount"
        );
        usdm().burn(_amountIn);
    }

    function getTotalAssetHeld() public view override returns (uint256) {
        return xmsBalance();
    }

    /// @notice Set fee
    /// @param _fee Fee
    function setFee(uint256 _fee) public override onlyGovernor {
        require(_fee <= feePrecision, "XMSRedemptionUnit::setFee: Fee exceed");
        fee = _fee;
    }
}
