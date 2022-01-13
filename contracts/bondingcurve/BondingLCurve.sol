// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/IBondingCurve.sol";
import "../libs/Roots.sol";
import "../pcv/PCVSplitter.sol";
import "../utils/Timed.sol";
import "../refs/OracleRef.sol";

/// @title An abstract bonding L curve for purchasing USDM
/// @author USDM Protocol
abstract contract BondingLCurve is
    IBondingCurve,
    CoreRef,
    OracleRef,
    PCVSplitter,
    Timed
{
    using SafeMath for uint256;
    /// @notice Amount of USDM paid for allocation when incentivize
    uint256 public override incentiveAmount;

    /// @notice Constructor
    /// @param _core USDM Core address to reference
    /// @param _oracle Oracle
    /// @param _pcvDeposits The PCV Deposits for the PCVSplitter
    /// @param _ratios The ratios for the PCVSplitter
    /// @param _duration The duration between incentivize allocations
    /// @param _incentive The amount rewarded to the caller of an allocation
    constructor(
        address _core,
        address[] memory _oracle,
        address[] memory _pcvDeposits,
        uint256[] memory _ratios,
        uint256 _duration,
        uint256 _incentive
    )
        CoreRef(_core)
        OracleRef(_oracle)
        PCVSplitter(_pcvDeposits, _ratios)
        Timed(_duration)
    {
        incentiveAmount = _incentive;
        _initTimed(block.timestamp);
    }

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "BondingLCurve::ensure: Expired");
        _;
    }

    /// @notice Sets the allocate incentive amount
    function setIncentiveAmount(uint256 _incentiveAmount)
        external
        override
        onlyGovernor
    {
        incentiveAmount = _incentiveAmount;
        emit IncentiveAmountUpdate(_incentiveAmount);
    }

    /// @notice Sets the allocation of incoming PCV
    function setAllocation(
        address[] calldata allocations,
        uint256[] calldata ratios
    ) external override onlyGovernor {
        _setAllocation(allocations, ratios);
    }

    /// @notice Batch allocate held PCV
    function allocate() external override whenNotPaused {
        require(
            (!Address.isContract(msg.sender)) ||
                msg.sender == core().genesisGroup(),
            "BondingLCurve::allocate: Caller is a contract"
        );
        require(
            core().hasGenesisGroupCompleted() ||
                msg.sender == core().genesisGroup(),
            "BondingLCurve::allocate: Still in genesis period or not allowed"
        );
        uint256 amount = getTotalPCVHeld();
        require(amount != 0, "BondingLCurve::allocate: No PCV held");

        _allocate(amount);

        _incentivize();

        emit Allocate(msg.sender, amount);
    }

    /// @notice Return current price
    /// @return Price reported as USDM per X with X being the underlying asset
    function getCurrentPrice()
        public
        view
        virtual
        override
        returns (Decimal.D256 memory);

    /// @notice Return amount of USDM received after a bonding curve purchase
    /// @param amountIn The amount of underlying used to purchase
    /// @return amountOut The amount of USDM received
    function getAmountOut(uint256 amountIn)
        public
        view
        virtual
        override
        returns (uint256 amountOut);

    /// @notice The amount of PCV held in contract and ready to be allocated
    function getTotalPCVHeld() public view virtual override returns (uint256);

    /// @notice Mint USDM and send to buyer destination
    function _purchase(uint256 amountIn, address to)
        internal
        returns (uint256 amountOut)
    {
        amountOut = getAmountOut(amountIn);
        if (!_ignoreUSDMSupplyCap()) {
            uint256 cap = getUSDMSupplyCap();
            require(
                amountOut.add(usdm().totalSupply()) <= cap,
                "BondingLCurve::_purchase: Exceed cap"
            );
        }
        usdm().mint(to, amountOut);

        emit Purchase(to, amountIn, amountOut);

        return amountOut;
    }

    /// @notice If window has passed, reward caller and reset window
    function _incentivize() internal virtual {
        if (isTimeEnded()) {
            _initTimed(block.timestamp); // reset window
            usdm().mint(msg.sender, incentiveAmount);
        }
    }

    /// @notice Ignore supply cap
    function _ignoreUSDMSupplyCap() internal view virtual returns (bool);
}
