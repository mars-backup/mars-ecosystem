// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IGenesisEvent.sol";
import "../utils/Timed.sol";
import "../refs/CoreRef.sol";

/// @title Genesis Event
/// @author USDM Protocol
abstract contract GenesisEvent is IGenesisEvent, CoreRef, ERC20, Timed {
    using Decimal for Decimal.D256;
    using SafeMath for uint256;

    IERC20 public override stakeToken;
    uint256 public override stakeTokenAllocPoint;
    uint256 public override underlyingTokenAllocPoint;

    /// @notice Issue USDM cap;
    uint256 public immutable override cap;

    uint256 public override usdmPerMGEN;

    bool public override supersuper;

    /// @notice The block number of the genesis event launch
    uint256 public override launchBlock;

    /// @notice The timestamp of the genesis event launch
    uint256 public override launchTimestamp;

    /// @notice The block amount to release stake and refund
    uint256 public override durationBlocks;

    mapping(address => uint256) public override stakeInfo;

    /// @notice GenesisEvent constructor
    /// @param _core USDM Core address to reference
    /// @param _duration Duration of the genesis event period
    /// @param _hours Duration of the release stake and refund
    /// @param _cap Upper limit amount of USDM to mint
    /// @param _stakeToken Stake token
    /// @param _stakeTokenAllocPoint Stake token allocation point
    /// @param _underlyingTokenAllocPoint Underlying token allocation point
    constructor(
        address _core,
        uint256 _duration,
        uint256 _hours,
        uint256 _cap,
        address _stakeToken,
        uint256 _stakeTokenAllocPoint,
        uint256 _underlyingTokenAllocPoint
    ) CoreRef(_core) ERC20("USDM Genesis EVENT", "MGENE") Timed(_duration) {
        durationBlocks = (_hours * 3600) / 3;
        stakeToken = IERC20(_stakeToken);
        cap = _cap;
        require(
            _stakeToken == address(0) ||
                (_stakeTokenAllocPoint > 0 && _underlyingTokenAllocPoint > 0),
            "GenesisEvent::constructor: AllocPoint zero"
        );
        stakeTokenAllocPoint = _stakeTokenAllocPoint;
        underlyingTokenAllocPoint = _underlyingTokenAllocPoint;
    }

    function initGenesisEvent(uint256 _startTime)
        public
        virtual
        override
        onlyGuardianOrGovernor
    {
        require(
            launchBlock == 0,
            "GenesisEvent::initGenesisEvent: Launch already happened"
        );
        _initTimed(_startTime);
    }

    modifier afterLaunch() {
        require(
            launchBlock > 0 && block.number > launchBlock,
            "GenesisEvent::afterLaunch: Not launch"
        );
        _;
    }

    /// @notice Allows for entry into the genesis event via X. Only callable during genesis event period.
    /// @param to Address to send MGENE tokens to
    /// @param value Amount of X to deposit
    function purchase(address to, uint256 value)
        external
        payable
        virtual
        override;

    // Add a backdoor out of genesis event in case of brick
    function emergencyExit(address from, address payable to)
        external
        virtual
        override;

    /// @notice Launch USDM Protocol. Callable once genesis event period has ended
    function launch() external virtual override;

    /// @notice Claim MGENE tokens for USDM. Only callable post launch
    /// @param to Address to send claimed USDM to.
    function claim(address to) external virtual override;

    /// @notice Calculate amount of USDM, X claimable by an account
    /// @return usdmAmount The amount of USDM received by the user per MGENE
    /// @return underlyingAmount The amount of underlying refunded by genesis event
    /// @return stakeAmount The amount of X received for stake
    /// @dev this function is only callable post launch
    function getAmountsToClaim(address to)
        public
        view
        virtual
        override
        returns (
            uint256 usdmAmount,
            uint256 underlyingAmount,
            uint256 stakeAmount
        );

    /// @notice Calculate amount of USDM received if the genesis event ended now.
    /// @param amountIn Amount of MGENE held or equivalently amount of X purchasing with
    /// @param inclusive If true, assumes the `amountIn` is part of the existing MGENE supply. Set to false to simulate a new purchase.
    /// @return usdmAmount The amount of USDM received by the user
    function getAmountOut(uint256 amountIn, bool inclusive)
        public
        view
        override
        returns (uint256 usdmAmount)
    {
        uint256 totalIn = totalSupply();
        if (!inclusive) {
            // Exclusive from current supply, so we add it in
            totalIn = totalIn.add(amountIn);
        }
        require(
            amountIn <= totalIn,
            "GenesisEvent::getAmountOut: Not enough supply"
        );
        (uint256 _totalEffectiveMGENE, ) = _getEffectiveMGENE(totalIn);
        (Decimal.D256 memory price, , ) = underlyingPrice();
        uint256 totalUSDM = price.mul(_totalEffectiveMGENE).asUint256();
        if (totalIn > 0) {
            usdmAmount = totalUSDM.mul(amountIn).div(totalIn);
        }
    }

    /// @notice Return price
    /// @return Price reported as USDM per X with X being the underlying asset
    function underlyingPrice()
        public
        view
        virtual
        override
        returns (
            Decimal.D256 memory,
            uint256,
            uint256
        );

    function _burnFrom(address account, uint256 amount) internal {
        if (msg.sender != account) {
            uint256 decreasedAllowance = allowance(account, _msgSender()).sub(
                amount,
                "GenesisEvent::_burnFrom: Burn amount exceeds allowance"
            );
            _approve(account, _msgSender(), decreasedAllowance);
        }
        _burn(account, amount);
    }

    function _getEffectiveMGENE(uint256 totalIn)
        internal
        view
        returns (uint256 _totalEffectiveMGENE, bool _supersuper)
    {
        (Decimal.D256 memory price, , ) = underlyingPrice();
        uint256 limitMGENE = cap == 0
            ? 0
            : Decimal.one().div(price).mul(cap).asUint256();
        if (limitMGENE > 0 && totalIn > limitMGENE) {
            _totalEffectiveMGENE = limitMGENE;
            _supersuper = true;
        } else {
            _totalEffectiveMGENE = totalIn;
            _supersuper = false;
        }
    }
}
