// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./BondingLCurve.sol";
import "../interfaces/IPCVDeposit.sol";

/// @title Use BNB mint USDM
/// @author USDM Protocol
abstract contract BNBBondingLCurve is BondingLCurve {
    using Decimal for Decimal.D256;
    using SafeMath for uint256;

    /// @notice The underlying asset
    IERC20 public wbnb;

    // Chainlink to get underlying asset price
    IChainlinkLastPriceOracle chainlink;

    /// @notice Fee
    uint256 public override fee = 9990;
    /// @notice Fee precision
    uint256 public constant override feePrecision = 10000;

    constructor(
        address _core,
        address[] memory _oracle,
        address _wbnb,
        address _chainlink,
        address[] memory _pcvDeposits,
        uint256[] memory _ratios,
        uint256 _duration,
        uint256 _incentive
    )
        BondingLCurve(
            _core,
            _oracle,
            _pcvDeposits,
            _ratios,
            _duration,
            _incentive
        )
    {
        wbnb = IERC20(_wbnb);
        chainlink = IChainlinkLastPriceOracle(_chainlink);
    }

    /// @notice Return current chainlink price
    /// @return Price reported as USD per BNB with BNB being the underlying asset
    function getCurrentPrice()
        public
        view
        override
        returns (Decimal.D256 memory)
    {
        (uint256 chainlinkPrice, uint8 decimals) = chainlink.getLatestPrice();
        return Decimal.ratio(chainlinkPrice, 10**decimals);
    }

    /// @notice Return amount of USDM received after a bonding curve purchase
    /// @param amountIn The amount of underlying used to purchase
    /// @return amountOut The amount of USDM received
    function getAmountOut(uint256 amountIn)
        public
        view
        override
        returns (uint256 amountOut)
    {
        amountOut = getCurrentPrice().mul(amountIn).asUint256().mul(fee).div(
            feePrecision
        );
    }

    /// @notice Return amount of X purchased after a bonding curve purchase
    /// @param amountOut The amount of USDM received
    /// @return amountIn The amount of underlying used to purchase
    function getAmountIn(uint256 amountOut)
        public
        view
        override
        returns (uint256 amountIn)
    {
        amountIn = invert(getCurrentPrice())
            .mul(amountOut)
            .asUint256()
            .mul(feePrecision)
            .div(fee);
    }

    /// @notice Set fee
    /// @param _fee Fee
    function setFee(uint256 _fee) public override onlyGovernor {
        require(_fee <= feePrecision, "BNBBondingLCurve::setFee: Fee exceed");
        fee = _fee;
    }

    /// @notice Purchase USDM for underlying tokens
    /// @param to Address to receive USDM
    /// @param amountIn Amount of underlying tokens input
    /// @param amountOutMin Min amount of USDM received
    /// @param deadline Deadline
    /// @return amountOut Amount of USDM received
    function purchase(
        address to,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline
    )
        external
        payable
        override
        postGenesis
        whenNotPaused
        ensure(deadline)
        returns (uint256 amountOut)
    {
        require(
            msg.value == amountIn,
            "BNBBondingLCurve::purchase: Sent value does not equal input"
        );
        amountOut = _purchase(amountIn, to);
        require(
            amountOut >= amountOutMin,
            "BNBBondingLCurve::purchase: Insufficient amount"
        );
    }

    function getTotalPCVHeld() public view override returns (uint256) {
        return address(this).balance;
    }

    function _allocateSingle(uint256 amount, address pcvDeposit)
        internal
        override
    {
        IPCVDeposit(pcvDeposit).deposit{value: amount}(amount);
    }

    function _ignoreUSDMSupplyCap() internal pure override returns (bool) {
        return false;
    }

    function setChainlink(address _chainlink) external onlyGovernor {
        chainlink = IChainlinkLastPriceOracle(_chainlink);
    }
}
