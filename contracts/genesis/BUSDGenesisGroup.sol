// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IGenesisGroup.sol";
import "../interfaces/IBondingCurve.sol";
import "../utils/Timed.sol";
import "../refs/CoreRef.sol";

/// @title Equal access to the first bonding curve transaction
/// @author USDM Protocol
contract BUSDGenesisGroup is IGenesisGroup, CoreRef, ERC20, Timed {
    using Decimal for Decimal.D256;
    using SafeMath for uint256;

    /// @notice Issue USDM cap;
    uint256 public immutable cap;

    IERC20 public busd;

    IBondingCurve public override bondingCurve;

    uint256 public override usdmPerMGEN;

    uint256 public busdPerMGEN;

    bool public override supersuper;

    /// @notice The block number of the genesis launch
    uint256 public override launchBlock;

    /// @notice The timestamp of the genesis launch
    uint256 public override launchTimestamp;

    IERC20 public override stakeToken;
    uint256 public override stakeTokenAllocPoint;
    uint256 public override underlyingTokenAllocPoint;
    mapping(address => uint256) public override stakeInfo;

    /// @notice The block amount to release stake and refund
    uint256 public override durationBlocks;

    /// @notice BUSDGenesisGroup constructor
    /// @param _core USDM Core address to reference
    /// @param _busd BUSD
    /// @param _bondingCurve BondingCurve address for purchase
    /// @param _duration Duration of the Genesis period
    /// @param _hours Duration of the release stake and refund
    /// @param _cap Upper limit amount of USDM to mint
    /// @param _stakeToken Stake token
    /// @param _stakeTokenAllocPoint Stake token allocation point
    /// @param _busdAllocPoint BUSD allocation point
    constructor(
        address _core,
        address _busd,
        address _bondingCurve,
        uint256 _duration,
        uint256 _hours,
        uint256 _cap,
        address _stakeToken,
        uint256 _stakeTokenAllocPoint,
        uint256 _busdAllocPoint
    ) CoreRef(_core) ERC20("USDM Genesis Group", "MGEN") Timed(_duration) {
        durationBlocks = (_hours * 3600) / 3;
        bondingCurve = IBondingCurve(_bondingCurve);
        busd = IERC20(_busd);
        cap = _cap;
        stakeToken = IERC20(_stakeToken);

        uint256 maxTokens = uint256(-1);
        require(
            busd.approve(address(bondingCurve), maxTokens),
            "BUSDGenesisGroup::constructor: Approve failed"
        );
        require(
            _stakeToken == address(0) ||
                (_stakeTokenAllocPoint > 0 && _busdAllocPoint > 0),
            "GenesisEvent::constructor: AllocPoint zero"
        );
        stakeTokenAllocPoint = _stakeTokenAllocPoint;
        underlyingTokenAllocPoint = _busdAllocPoint;
    }

    modifier afterLaunch() {
        require(
            launchBlock > 0 && block.number > launchBlock,
            "BUSDGenesisGroup::afterLaunch: Not launch"
        );
        _;
    }

    function transfer(address to, uint256 amount)
        public
        pure
        override
        returns (bool)
    {
        revert("BUSDGenesisGroup::transfer: Not support transfer");
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public pure override returns (bool) {
        revert("BUSDGenesisGroup::transferFrom: Not support transferFrom");
    }

    function initGenesis(uint256 _startTime)
        external
        override
        onlyGuardianOrGovernor
    {
        require(
            launchBlock == 0,
            "BUSDGenesisGroup::initGenesis: Launch already happened"
        );
        _initTimed(_startTime);
    }

    /// @notice Allows for entry into the Genesis Group via BUSD. Only callable during Genesis period.
    /// @param to Address to send MGEN Genesis tokens to
    /// @param value Amount of BUSD to deposit
    function purchase(address to, uint256 value)
        external
        payable
        override
        duringTime
        whenNotPaused
    {
        require(msg.value == 0, "BUSDGenesisGroup::purchase: No need BNB");
        require(value != 0, "BUSDGenesisGroup::purchase: No value sent");
        require(
            busd.transferFrom(msg.sender, address(this), value),
            "BUSDGenesisGroup::purchase: TransferFrom failed"
        );
        if (address(stakeToken) != address(0)) {
            uint256 stakeAmount = value.mul(stakeTokenAllocPoint).div(
                underlyingTokenAllocPoint
            );
            require(
                stakeToken.transferFrom(msg.sender, address(this), stakeAmount)
            );
            stakeInfo[to] = stakeInfo[to].add(stakeAmount);
        }
        _mint(to, value);

        emit Purchase(to, value);
    }

    /// @notice Redeem MGEN genesis tokens for USDM. Only callable post launch
    /// @param to Address to send redeemed USDM to.
    function redeem(address to) external override afterLaunch whenNotPaused {
        (
            uint256 usdmAmount,
            uint256 busdAmount,
            uint256 stakeAmount
        ) = getAmountsToRedeem(to);

        // Burn MGEN
        uint256 amountIn = balanceOf(to);
        _burnFrom(to, amountIn);

        // Send USDM and BUSD
        if (usdmAmount != 0) {
            require(
                usdm().transfer(to, usdmAmount),
                "BUSDGenesisGroup::redeem: Transfer failed"
            );
        }
        if (busdAmount != 0) {
            require(
                busd.transfer(to, busdAmount),
                "BUSDGenesisGroup::redeem: Transfer failed"
            );
        }
        if (
            stakeAmount != 0 && block.number >= launchBlock.add(durationBlocks)
        ) {
            delete stakeInfo[to];
            require(
                stakeToken.transfer(to, stakeAmount),
                "BUSDGenesisEvent::claim: Transfer failed"
            );
        }
        emit Redeem(to, amountIn, usdmAmount);
    }

    /// @notice Launch USDM Protocol. Callable once Genesis period has ended
    function launch()
        external
        override
        onlyGuardianOrGovernor
        afterTime
        whenNotPaused
    {
        require(
            launchBlock == 0,
            "BUSDGenesisGroup::launch: Launch already happened"
        );

        launchBlock = block.number;
        launchTimestamp = block.timestamp;

        (uint256 totalEffectiveMGEN, bool _supersuper) = _getEffectiveMGEN(
            totalSupply()
        );
        supersuper = _supersuper;
        uint256 refundMGEN = totalSupply().sub(totalEffectiveMGEN);

        Decimal.D256 memory price = bondingCurve.getCurrentPrice();
        uint256 endOfTime = uint256(-1);
        // BondingCurve purchase and PCV allocation
        bondingCurve.purchase(
            address(this),
            busd.balanceOf(address(this)).sub(refundMGEN),
            0,
            endOfTime
        );
        bondingCurve.allocate();
        if (totalSupply() > 0) {
            busdPerMGEN = refundMGEN.mul(1e12).div(totalSupply());
            usdmPerMGEN = usdmBalance().mul(1e12).div(totalSupply());
        }

        // solhint-disable-next-line not-rely-on-time
        emit Launch(block.timestamp, price.value);
    }

    function complete()
        external
        override
        onlyGovernor
        afterLaunch
        whenNotPaused
    {
        // Complete Genesis
        core().completeGenesisGroup();
    }

    // Add a backdoor out of Genesis in case of brick
    function emergencyExit(address from, address payable to) external override {
        require(
            // solhint-disable-next-line not-rely-on-time
            block.timestamp > (startTime + duration + 3 hours),
            "BUSDGenesisGroup::emergencyExit: Not in exit window"
        );
        require(
            launchBlock == 0,
            "BUSDGenesisGroup::emergencyExit: Launch already happened"
        );

        uint256 heldMGEN = balanceOf(from);

        require(
            heldMGEN != 0,
            "BUSDGenesisGroup::emergencyExit: No MGEN balance"
        );
        require(
            msg.sender == from || allowance(from, msg.sender) >= heldMGEN,
            "BUSDGenesisGroup::emergencyExit: Not approved for emergency withdrawal"
        );

        _burnFrom(from, heldMGEN);
        require(
            busd.transfer(to, heldMGEN),
            "BUSDGenesisGroup::emergencyExit: Transfer failed"
        );

        if (address(stakeToken) != address(0)) {
            uint256 stakeAmount = stakeInfo[from];
            delete stakeInfo[from];
            require(
                stakeToken.transfer(from, stakeAmount),
                "BUSDGenesisEvent::emergencyExit: Transfer failed"
            );
        }
    }

    /// @notice Calculate amount of USDM redeemable by an account post-genesis
    /// @return usdmAmount The amount of USDM received by the user
    /// @return busdAmount The amount of BUSD refunded by GenesisGroup
    /// @dev this function is only callable post launch
    function getAmountsToRedeem(address to)
        public
        view
        override
        afterLaunch
        returns (
            uint256 usdmAmount,
            uint256 busdAmount,
            uint256 stakeAmount
        )
    {
        uint256 userMGEN = balanceOf(to);

        usdmAmount = usdmPerMGEN.mul(userMGEN).div(1e12);
        busdAmount = busdPerMGEN.mul(userMGEN).div(1e12);
        stakeAmount = stakeInfo[to];

        return (usdmAmount, busdAmount, stakeAmount);
    }

    /// @notice Calculate amount of USDM received if the Genesis Group ended now.
    /// @param amountIn Amount of MGEN held or equivalently amount of BUSD purchasing with
    /// @param inclusive If true, assumes the `amountIn` is part of the existing MGEN supply. Set to false to simulate a new purchase.
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
            "BUSDGenesisGroup::getAmountOut: Not enough supply"
        );

        (uint256 _totalEffectiveMGEN, ) = _getEffectiveMGEN(totalIn);
        uint256 totalUSDM = bondingCurve.getAmountOut(_totalEffectiveMGEN);

        // Return portions of total USDM
        if (totalIn > 0) {
            usdmAmount = totalUSDM.mul(amountIn).div(totalIn);
        }
    }

    function _burnFrom(address account, uint256 amount) internal {
        if (msg.sender != account) {
            uint256 decreasedAllowance = allowance(account, _msgSender()).sub(
                amount,
                "BUSDGenesisGroup::_burnFrom: Burn amount exceeds allowance"
            );
            _approve(account, _msgSender(), decreasedAllowance);
        }
        _burn(account, amount);
    }

    function _getEffectiveMGEN(uint256 totalIn)
        internal
        view
        returns (uint256 _totalEffectiveMGEN, bool _supersuper)
    {
        uint256 limitMGEN = bondingCurve.getAmountIn(cap);
        if (totalIn > limitMGEN) {
            _totalEffectiveMGEN = limitMGEN;
            _supersuper = true;
        } else {
            _totalEffectiveMGEN = totalIn;
            _supersuper = false;
        }
    }
}
