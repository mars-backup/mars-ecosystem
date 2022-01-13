// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IIHO.sol";
import "../utils/Timed.sol";
import "../refs/CoreRef.sol";

/// @title IHO
/// @author USDM Protocol
contract IHO is IIHO, CoreRef, ERC20, Timed {
    using Decimal for Decimal.D256;
    using SafeMath for uint256;

    address public constant DEAD_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    IERC20 public immutable targetToken;
    IERC20 public immutable commitToken;

    /// @notice The price of target token, commit token per target token
    uint256 public override targetTokenPrice;

    /// @notice Purchase cap everyone
    uint256 public immutable purchaseCap;

    /// @notice Issue target token cap;
    uint256 public cap;

    uint256 public commitTokenPerMIHO;
    bool public override supersuper;

    /// @notice The block number of the IHO launch
    uint256 public override launchBlock;

    /// @notice The timestamp of the IHO launch
    uint256 public override launchTimestamp;

    /// @notice Release target token per block and per share
    uint256 public releasePerBlockAndShare;

    uint256 public releaseStartBlock;

    /// @notice The block amount to release target token
    uint256 public durationBlocks;

    mapping(address => UserInfo) public override userInfo;

    address public devAddress;

    /// @notice IHO constructor
    /// @param _core USDM Core address to reference
    /// @param _devAddress Project address
    /// @param _commitToken Commit token
    /// @param _targetToken Target token
    /// @param _purchaseCap Limit amount of commit token
    /// @param _duration Duration of the IHO period
    /// @param _days Duration of the release
    constructor(
        address _core,
        address _devAddress,
        address _commitToken,
        address _targetToken,
        uint256 _purchaseCap,
        uint256 _duration,
        uint256 _days
    ) CoreRef(_core) ERC20("XMS IHO", "MIHO") Timed(_duration) {
        devAddress = _devAddress;
        commitToken = IERC20(_commitToken);
        targetToken = IERC20(_targetToken);
        purchaseCap = _purchaseCap;
        durationBlocks = (_days * 24 * 3600) / 3;
    }

    function transfer(address to, uint256 amount)
        public
        pure
        override
        returns (bool)
    {
        revert("IHO::transfer: Not support transfer");
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public pure override returns (bool) {
        revert("IHO::transferFrom: Not support transferFrom");
    }

    function initIHO(uint256 _startTime, uint256 _targetTokenPrice)
        external
        override
        onlyGuardianOrGovernor
    {
        require(launchBlock == 0, "IHO::initIHO: Launch already happened");
        require(_targetTokenPrice > 0, "IHO::initIHO: Error price");
        _initTimed(_startTime);
        cap = targetToken.balanceOf(address(this));
        targetTokenPrice = _targetTokenPrice;
    }

    function setReleaseStartBlock(uint256 _releaseStartBlock)
        external
        postIHO
        onlyGuardianOrGovernor
    {
        require(releaseStartBlock == 0 || block.number < releaseStartBlock, "IHO:setReleaseStartBlock:: Has sotted");
        require(
            _releaseStartBlock >= launchBlock,
            "IHO:setReleaseStartBlock:: Error block"
        );
        releaseStartBlock = _releaseStartBlock;
    }

    modifier postIHO() {
        require(launchBlock > 0, "IHO::postIHO: Still in IHO period");
        _;
    }

    /// @notice Allows for entry into the IHO via commit token. Only callable during IHO period.
    /// @param _to Address to send MIHO tokens to
    /// @param _value Amount of commit token to deposit
    function purchase(address _to, uint256 _value)
        external
        payable
        override
        duringTime
        whenNotPaused
    {
        require(msg.value == 0, "IHO::purchase: No need BNB");
        require(_value != 0, "IHO::purchase: No value sent");
        require(
            purchaseCap == 0 || balanceOf(_to).add(_value) <= purchaseCap,
            "IHO::purchase: Exceed purchase cap"
        );
        require(
            commitToken.transferFrom(msg.sender, address(this), _value),
            "IHO::purchase: TransferFrom failed"
        );
        _mint(_to, _value);

        emit Purchase(_to, _value);
    }

    // Add a backdoor out of IHO in case of brick
    function emergencyExit(address _from, address payable _to)
        external
        override
    {
        require(
            // solhint-disable-next-line not-rely-on-time
            block.timestamp > (startTime + duration + 3 hours),
            "IHO::emergencyExit: Not in exit window"
        );
        require(
            launchBlock == 0,
            "IHO::emergencyExit: Launch already happened"
        );

        uint256 heldMIHO = balanceOf(_from);

        require(heldMIHO != 0, "IHO::emergencyExit: No MIHO balance");
        require(
            msg.sender == _from || allowance(_from, msg.sender) >= heldMIHO,
            "IHO::emergencyExit: Not approved for emergency withdrawal"
        );

        _burnFrom(_from, heldMIHO);

        require(
            commitToken.transfer(_to, heldMIHO),
            "IHO::emergencyExit: Transfer failed"
        );
    }

    /// @notice Launch USDM Protocol. Callable once IHO period has ended
    function launch()
        external
        override
        onlyGuardianOrGovernor
        afterTime
        whenNotPaused
    {
        require(launchBlock == 0, "IHO::launch: Launch already happened");
        // Complete IHO
        launchBlock = block.number;
        launchTimestamp = block.timestamp;

        (uint256 totalEffectiveMIHO, bool supersuper_) = _getEffectiveMIHO(
            totalSupply()
        );
        supersuper = supersuper_;

        uint256 refundMIHO = totalSupply().sub(totalEffectiveMIHO);

        uint256 totalEffectiveTargetToken = Decimal
            .one()
            .div(_getTargetTokenPrice())
            .mul(totalEffectiveMIHO)
            .asUint256();

        require(
            address(xms()) == address(commitToken)
                ? xms().transfer(DEAD_ADDRESS, xmsBalance().sub(refundMIHO))
                : commitToken.transfer(
                    devAddress,
                    commitToken.balanceOf(address(this)).sub(refundMIHO)
                ),
            "IHO::launch: Transfer failed"
        );
        if (totalSupply() > 0) {
            commitTokenPerMIHO = refundMIHO.mul(1e12).div(totalSupply());
            releasePerBlockAndShare = totalEffectiveTargetToken
                .mul(1e12)
                .div(durationBlocks)
                .div(totalSupply());
        }
        require(
            targetToken.transfer(
                address(devAddress),
                cap.sub(totalEffectiveTargetToken)
            ),
            "IHO::launch: Transfer failed"
        );

        // solhint-disable-next-line not-rely-on-time
        emit Launch(block.timestamp);
    }

    /// @notice Claim MIHO tokens for target token. Only callable post launch
    /// @param to Address to send claimed target token to.
    function claim(address to) external override postIHO whenNotPaused {
        require(
            block.number > launchBlock,
            "IHO::claim: No claiming in launch block"
        );
        (
            uint256 targetTokenAmount,
            uint256 commitTokenAmount
        ) = getAmountsToClaim(to);

        uint256 amountIn = balanceOf(to);
        UserInfo storage _userInfo = userInfo[to];
        if (amountIn > 0) {
            _userInfo.amount = amountIn;
            // Burn MIHO
            _burnFrom(to, amountIn);
        }
        // Send
        if (targetTokenAmount != 0) {
            uint256 userDebt = _userInfo.debt;
            userDebt = userDebt + targetTokenAmount;
            _userInfo.debt = userDebt;
            require(
                targetToken.transfer(to, targetTokenAmount),
                "IHO::claim: Transfer failed"
            );
        }
        if (commitTokenAmount != 0) {
            require(
                commitToken.transfer(to, commitTokenAmount),
                "IHO::claim: Transfer failed"
            );
        }

        emit Claim(to, amountIn, targetTokenAmount, commitTokenAmount);
    }

    /// @notice Calculate amount of target token claimable by an account post-iho
    /// @return targetTokenAmount The amount of target token received by the user per IHO
    /// @return commitTokenAmount The amount of commit token refunded by IHO
    /// @dev this function is only callable post launch
    function getAmountsToClaim(address to)
        public
        view
        override
        postIHO
        returns (uint256 targetTokenAmount, uint256 commitTokenAmount)
    {
        commitTokenAmount = commitTokenPerMIHO.mul(balanceOf(to)).div(1e12);

        if (releaseStartBlock > 0 && block.number > releaseStartBlock) {
            UserInfo memory _userInfo = userInfo[to];
            uint256 endBlock = releaseStartBlock.add(durationBlocks);
            uint256 currentBlock = block.number < endBlock
                ? block.number
                : endBlock;
            targetTokenAmount = currentBlock
                .sub(releaseStartBlock)
                .mul(releasePerBlockAndShare)
                .mul(_getUserAmount(to))
                .div(1e12)
                .sub(_userInfo.debt);
        }
    }

    /// @notice Calculate amount of target token received if the IHO ended now.
    /// @param amountIn Amount of MIHO held or equivalently amount of commit token purchasing with
    /// @param inclusive If true, assumes the `amountIn` is part of the existing MIHO supply. Set to false to simulate a new purchase.
    /// @return targetTokenAmount The amount of target token received by the user
    function getAmountOut(uint256 amountIn, bool inclusive)
        public
        view
        override
        returns (uint256 targetTokenAmount)
    {
        uint256 totalIn = totalSupply();
        if (!inclusive) {
            // Exclusive from current supply, so we add it in
            totalIn = totalIn.add(amountIn);
        }
        require(amountIn <= totalIn, "IHO::getAmountOut: Not enough supply");
        (uint256 totalEffectiveMIHO, ) = _getEffectiveMIHO(totalIn);
        uint256 totalEffectiveTargetToken = Decimal
            .one()
            .div(_getTargetTokenPrice())
            .mul(totalEffectiveMIHO)
            .asUint256();
        if (totalIn > 0) {
            targetTokenAmount = totalEffectiveTargetToken.mul(amountIn).div(
                totalIn
            );
        }
    }

    /// @notice Calculate amount of target token could be received in the future.
    function getUnClaimableAmount(address to)
        public
        view
        override
        postIHO
        returns (uint256 targetTokenAmount)
    {
        uint256 blocks;
        if (releaseStartBlock == 0 || block.number <= releaseStartBlock) {
            blocks = durationBlocks;
        } else if (block.number < releaseStartBlock.add(durationBlocks)) {
            blocks = releaseStartBlock.add(durationBlocks).sub(block.number);
        }
        targetTokenAmount = blocks
            .mul(releasePerBlockAndShare)
            .mul(_getUserAmount(to))
            .div(1e12);
    }

    function _getUserAmount(address account) internal view returns (uint256) {
        UserInfo memory _userInfo = userInfo[account];
        uint256 amount = _userInfo.amount;
        return amount == 0 ? balanceOf(account) : amount;
    }

    function _burnFrom(address account, uint256 amount) internal {
        if (msg.sender != account) {
            uint256 decreasedAllowance = allowance(account, _msgSender()).sub(
                amount,
                "IHO::_burnFrom: Burn amount exceeds allowance"
            );
            _approve(account, _msgSender(), decreasedAllowance);
        }
        _burn(account, amount);
    }

    function _getEffectiveMIHO(uint256 totalIn)
        internal
        view
        returns (uint256 _totalEffectiveMIHO, bool _supersuper)
    {
        uint256 limitMIHO = cap == 0
            ? 0
            : _getTargetTokenPrice().mul(cap).asUint256();
        if (totalIn > limitMIHO) {
            _totalEffectiveMIHO = limitMIHO;
            _supersuper = true;
        } else {
            _totalEffectiveMIHO = totalIn;
            _supersuper = false;
        }
    }

    function _getTargetTokenPrice()
        internal
        view
        returns (Decimal.D256 memory)
    {
        return Decimal.D256({value: targetTokenPrice});
    }
}
