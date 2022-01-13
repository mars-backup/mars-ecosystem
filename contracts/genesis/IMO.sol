// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IIMO.sol";
import "../utils/Timed.sol";
import "../refs/CoreRef.sol";

/// @title IMO
/// @author USDM Protocol
contract IMO is IIMO, CoreRef, ERC20, Timed {
    using Decimal for Decimal.D256;
    using SafeMath for uint256;

    IERC20 public busd;
    /// @notice The price of XMS, BUSD per XMS
    Decimal.D256 public override xmsPrice = Decimal.ratio(45, 1000);

    /// @notice Purchase cap everyone
    uint256 public purchaseCap = 5_000 * 1e18;

    /// @notice Total amount of MIMO cal from cap
    uint256 public override totalEffectiveMIMO;
    bool public override supersuper;

    /// @notice The block number of the IMO launch
    uint256 public override launchBlock;

    /// @notice The timestamp of the IMO launch
    uint256 public override launchTimestamp;

    /// @notice XMS per block
    uint256 public xmsPerBlock;

    /// @notice The block amount to release XMS
    uint256 public durationBlocks;

    mapping(address => UserInfo) public override userInfo;

    /// @notice Total amount of snapshot MIMO after launch
    uint256 public override totalSnapshotAmount;

    address public devAddress;

    /// @notice IMO constructor
    /// @param _core USDM Core address to reference
    /// @param _devAddress Project address
    /// @param _busd BUSD
    /// @param _duration Duration of the IMO period
    /// @param _days Duration of the release
    constructor(
        address _core,
        address _devAddress,
        address _busd,
        uint256 _duration,
        uint256 _days
    ) CoreRef(_core) ERC20("XMS IMO", "MIMO") Timed(_duration) {
        devAddress = _devAddress;
        busd = IERC20(_busd);
        durationBlocks = (_days * 24 * 3600) / 3;
    }

    function initIMO() external override onlyGuardianOrGovernor {
        require(launchBlock == 0, "IMO::initIMO: Launch already happened");
        _initTimed(block.timestamp);
    }

    modifier postIMO() {
        require(launchBlock > 0, "IMO::postIMO: Still in IMO period");
        _;
    }

    /// @notice Allows for entry into the IMO via BUSD. Only callable during IMO period.
    /// @param to Address to send MIMO tokens to
    /// @param value Amount of BUSD to deposit
    function purchase(address to, uint256 value)
        external
        payable
        override
        duringTime
    {
        require(msg.value == 0, "IMO::purchase: No need BNB");
        require(value != 0, "IMO::purchase: No value sent");
        require(
            balanceOf(to).add(value) <= purchaseCap,
            "IMO::purchase: Exceed purchase cap"
        );
        require(
            busd.transferFrom(msg.sender, address(this), value),
            "IMO::purchase: TransferFrom failed"
        );
        _mint(to, value);

        emit Purchase(to, value);
    }

    // Add a backdoor out of IMO in case of brick
    function emergencyExit(address from, address payable to) external override {
        require(
            // solhint-disable-next-line not-rely-on-time
            block.timestamp > (startTime + duration + 3 hours),
            "IMO::emergencyExit: Not in exit window"
        );
        require(
            launchBlock == 0,
            "IMO::emergencyExit: Launch already happened"
        );

        uint256 heldMIMO = balanceOf(from);

        require(heldMIMO != 0, "IMO::emergencyExit: No MIMO balance");
        require(
            msg.sender == from || allowance(from, msg.sender) >= heldMIMO,
            "IMO::emergencyExit: Not approved for emergency withdrawal"
        );

        _burnFrom(from, heldMIMO);

        require(
            busd.transfer(to, heldMIMO),
            "IMO::emergencyExit: Transfer failed"
        );
    }

    /// @notice Launch USDM Protocol. Callable once IMO period has ended
    function launch() external override onlyGuardianOrGovernor afterTime {
        require(launchBlock == 0, "IMO::launch: Launch already happened");
        // Complete IMO
        launchBlock = block.number;
        launchTimestamp = block.timestamp;

        (totalEffectiveMIMO, supersuper) = _getEffectiveMIMO(totalSupply());
        totalSnapshotAmount = totalEffectiveMIMO;

        uint256 totalEffectiveXMS = Decimal
            .one()
            .div(xmsPrice)
            .mul(totalEffectiveMIMO)
            .asUint256();
        xmsPerBlock = totalEffectiveXMS.div(durationBlocks);
        require(
            busd.transfer(devAddress, totalEffectiveMIMO),
            "IMO::launch: Transfer failed"
        );
        require(
            xms().transfer(
                address(devAddress),
                xmsBalance().sub(totalEffectiveXMS)
            ),
            "IMO::launch: Transfer failed"
        );

        // solhint-disable-next-line not-rely-on-time
        emit Launch(block.timestamp);
    }

    /// @notice Claim MIMO tokens for XMS. Only callable post launch
    /// @param to Address to send claimed XMS to.
    function claim(address to) external override {
        require(
            block.number > launchBlock,
            "IMO::claim: No claiming in launch block"
        );
        (uint256 xmsAmount, uint256 busdAmount) = getAmountsToClaim(to);

        uint256 amountIn = balanceOf(to);
        UserInfo storage _userInfo = userInfo[to];
        if (amountIn > 0) {
            // Burn MIMO
            _userInfo.amount = _getUserSnapshotAmount(to);
            totalEffectiveMIMO = totalEffectiveMIMO.sub(
                _getUserEffectiveMIMO(to)
            );
            _burnFrom(to, amountIn);
        }
        // Send XMS and BUSD
        if (xmsAmount != 0) {
            uint256 userDebt = _userInfo.debt;
            userDebt = userDebt + xmsAmount;
            _userInfo.debt = userDebt;
            require(
                xms().transfer(to, xmsAmount),
                "IMO::claim: Transfer failed"
            );
        }
        if (busdAmount != 0) {
            require(
                busd.transfer(to, busdAmount),
                "IMO::claim: Transfer failed"
            );
        }

        emit Claim(to, amountIn, xmsAmount);
    }

    /// @notice Calculate amount of XMS claimable by an account post-imo
    /// @return xmsAmount The amount of XMS received by the user per IMO
    /// @return busdAmount The amount of BUSD refunded by IMO
    /// @dev this function is only callable post launch
    function getAmountsToClaim(address to)
        public
        view
        override
        postIMO
        returns (uint256 xmsAmount, uint256 busdAmount)
    {
        uint256 userMIMO = balanceOf(to);

        uint256 circulatingMIMO = totalSupply();

        if (circulatingMIMO != 0) {
            if (supersuper) {
                busdAmount = userMIMO
                    .mul(circulatingMIMO.sub(totalEffectiveMIMO))
                    .div(circulatingMIMO);
            }
        }
        UserInfo memory _userInfo = userInfo[to];
        uint256 userSnapshotAmount = _getUserSnapshotAmount(to);
        uint256 endBlock = launchBlock.add(durationBlocks);
        uint256 currentBlock = block.number < endBlock
            ? block.number
            : endBlock;
        xmsAmount = currentBlock
            .sub(launchBlock)
            .mul(xmsPerBlock)
            .mul(userSnapshotAmount)
            .div(totalSnapshotAmount)
            .sub(_userInfo.debt);

        return (xmsAmount, busdAmount);
    }

    /// @notice Calculate amount of XMS received if the IMO ended now.
    /// @param amountIn Amount of MIMO held or equivalently amount of BUSD purchasing with
    /// @param inclusive If true, assumes the `amountIn` is part of the existing MIMO supply. Set to false to simulate a new purchase.
    /// @return xmsAmount The amount of XMS received by the user
    function getAmountOut(uint256 amountIn, bool inclusive)
        public
        view
        override
        returns (uint256 xmsAmount)
    {
        uint256 totalIn = totalSupply();
        if (!inclusive) {
            // Exclusive from current supply, so we add it in
            totalIn = totalIn.add(amountIn);
        }
        require(amountIn <= totalIn, "IMO::getAmountOut: Not enough supply");
        (uint256 _totalEffectiveMIMO, bool _supersuper) = _getEffectiveMIMO(
            totalIn
        );
        if (_supersuper) {
            xmsAmount = Decimal
                .one()
                .div(xmsPrice)
                .mul(amountIn.mul(_totalEffectiveMIMO).div(totalIn))
                .asUint256();
        } else {
            xmsAmount = Decimal.one().div(xmsPrice).mul(amountIn).asUint256();
        }
    }

    /// @notice Calculate amount of XMS could be received in the future.
    function getUnClaimableAmount(address to)
        public
        view
        override
        postIMO
        returns (uint256 xmsAmount)
    {
        uint256 userSnapshotAmount = _getUserSnapshotAmount(to);
        uint256 endBlock = launchBlock.add(durationBlocks);
        if (block.number < endBlock) {
            xmsAmount = userSnapshotAmount
                .mul(endBlock.sub(block.number).mul(xmsPerBlock))
                .div(totalSnapshotAmount);
        }
    }

    function _getUserSnapshotAmount(address account)
        internal
        view
        returns (uint256)
    {
        UserInfo memory _userInfo = userInfo[account];
        uint256 amount = _userInfo.amount;
        amount = amount + _getUserEffectiveMIMO(account);
        return amount;
    }

    function _getUserEffectiveMIMO(address account)
        internal
        view
        returns (uint256)
    {
        uint256 userMIMO = balanceOf(account);
        uint256 circulatingMIMO = totalSupply();
        return
            circulatingMIMO > 0
                ? userMIMO.mul(totalEffectiveMIMO).div(circulatingMIMO)
                : 0;
    }

    function _burnFrom(address account, uint256 amount) internal {
        if (msg.sender != account) {
            uint256 decreasedAllowance = allowance(account, _msgSender()).sub(
                amount,
                "IMO::_burnFrom: Burn amount exceeds allowance"
            );
            _approve(account, _msgSender(), decreasedAllowance);
        }
        _burn(account, amount);
    }

    function _getEffectiveMIMO(uint256 totalIn)
        internal
        view
        returns (uint256 _totalEffectiveMIMO, bool _supersuper)
    {
        uint256 limitMIMO = xmsPrice.mul(xmsBalance()).asUint256();
        if (totalIn > limitMIMO) {
            _totalEffectiveMIMO = limitMIMO;
            _supersuper = true;
        } else {
            _totalEffectiveMIMO = totalIn;
            _supersuper = false;
        }
    }
}
