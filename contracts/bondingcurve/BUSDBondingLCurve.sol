// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./BondingLCurve.sol";
import "../interfaces/IPCVDeposit.sol";

/// @title Use BUSD mint USDM
/// @author USDM Protocol
contract BUSDBondingLCurve is BondingLCurve {
    using Decimal for Decimal.D256;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @notice Fee
    uint256 public override fee = 10000;
    /// @notice Fee precision
    uint256 public constant override feePrecision = 10000;

    /// @notice The underlying asset
    IERC20 public busd;

    // Chainlink to get underlying asset price
    IChainlinkLastPriceOracle chainlink;

    bool public IGNORE_USDM_SUPPLY_CAP = true;

    constructor(
        address _core,
        address[] memory _oracle,
        address _busd,
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
        busd = IERC20(_busd);
        chainlink = IChainlinkLastPriceOracle(_chainlink);
    }

    function setIgnoreUSDMSupplyCap(bool _ignore) external onlyGovernor {
        IGNORE_USDM_SUPPLY_CAP = _ignore;
    }

    /// @notice Return current price
    /// @return Price reported as USD per BUSD with BUSD being the underlying asset
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
        require(_fee <= feePrecision, "BUSDBondingLCurve::setFee: Fee exceed");
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
        whenNotPaused
        ensure(deadline)
        returns (uint256 amountOut)
    {
        require(
            core().hasGenesisGroupCompleted() ||
                msg.sender == core().genesisGroup(),
            "BUSDBondingLCurve::purchase: Still in genesis period or no allowed"
        );
        require(msg.value == 0, "BUSDBondingLCurve::purchase: No need BNB");
        require(
            busd.transferFrom(msg.sender, address(this), amountIn),
            "BUSDBondingLCurve::purchase: TransferFrom failed"
        );
        amountOut = _purchase(amountIn, to);
        require(
            amountOut >= amountOutMin,
            "BUSDBondingLCurve::purchase: Insufficient amount"
        );
    }

    function getTotalPCVHeld() public view override returns (uint256) {
        return busd.balanceOf(address(this));
    }

    function _allocateSingle(uint256 amount, address pcvDeposit)
        internal
        override
    {
        busd.safeIncreaseAllowance(pcvDeposit, amount);
        IPCVDeposit(pcvDeposit).deposit(amount);
    }

    function _ignoreUSDMSupplyCap() internal view override returns (bool) {
        if (IGNORE_USDM_SUPPLY_CAP || msg.sender == core().genesisGroup())
            return true;
        return false;
    }

    function setChainlink(address _chainlink) external onlyGovernor {
        chainlink = IChainlinkLastPriceOracle(_chainlink);
    }
}
