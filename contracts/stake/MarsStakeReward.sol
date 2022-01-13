// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../utils/Timed.sol";
import "../refs/CoreRef.sol";

/// @title Reward for MarsStake
/// @author USDM Protocol
contract MarsStakeReward is CoreRef, Timed, Initializable {
    using SafeMath for uint256;

    /// @notice XMS per block
    uint256 public xmsPerBlock;

    /// @notice The block amount to release XMS
    uint256 public durationBlocks;

    uint256 public startBlock;

    uint256 public lastBlock;

    uint256 public lastFeeAmount;

    address public stake;

    address public devAddress;

    event Claim(address indexed _to, uint256 _rewardAmount, uint256 _feeAmount);

    /// @notice IMO constructor
    /// @param _core USDM Core address to reference
    /// @param _devAddress Project address
    /// @param _stake MarsStake
    /// @param _duration Min duration of claim
    /// @param _days Duration of the release
    constructor(
        address _core,
        address _devAddress,
        address _stake,
        uint256 _duration,
        uint256 _days
    ) CoreRef(_core) Timed(_duration) {
        require(
            _duration > 0,
            "MarsStakeReward::constructor: Duration couldn't be zero"
        );
        devAddress = _devAddress;
        stake = _stake;
        durationBlocks = (_days * 24 * 3600) / 3;
    }

    function initialize() external initializer onlyGuardianOrGovernor {
        _initTimed(block.timestamp);
        startBlock = block.number;
        lastBlock = block.number;

        uint256 xmsAmount = xmsBalance();
        xmsPerBlock = xmsAmount.div(durationBlocks);
    }

    modifier postInit() {
        require(startBlock > 0, "MarsStakeReward::postInit: Not initial");
        _;
    }

    /// @notice Claim XMS
    function claim() external postInit {
        require(isTimeEnded(), "MarsStakeReward::claim: Time not end");
        _initTimed(block.timestamp); // reset window
        uint256 rewardAmount = getAmountsToClaim();
        uint256 feeAmount = xmsBalance().sub(
            getUnClaimableAmount().add(rewardAmount)
        );

        uint256 xmsAmount = rewardAmount.add(feeAmount);
        lastFeeAmount = feeAmount;
        lastBlock = block.number;
        // Send XMS
        if (xmsAmount != 0) {
            xms().transfer(stake, xmsAmount);
        }
        emit Claim(stake, rewardAmount, feeAmount);
    }

    /// @notice Calculate amount of XMS claimable by an account post-imo
    /// @return xmsAmount The amount of XMS received by MarsStake
    function getAmountsToClaim() public view postInit returns (uint256) {
        require(
            block.number > lastBlock,
            "MarsStakeReward::getAmountsToClaim: Early than last block"
        );
        uint256 endBlock = startBlock.add(durationBlocks);
        uint256 current = block.number < endBlock ? block.number : endBlock;
        uint256 _lastBlock = lastBlock < endBlock ? lastBlock : endBlock;
        return current.sub(_lastBlock).mul(xmsPerBlock);
    }

    /// @notice Calculate amount of XMS could be received in the future.
    function getUnClaimableAmount()
        public
        view
        postInit
        returns (uint256 xmsAmount)
    {
        uint256 endBlock = startBlock.add(durationBlocks);
        if (block.number < endBlock) {
            xmsAmount = endBlock.sub(block.number).mul(xmsPerBlock);
        }
    }

    function setDuration(uint256 _duration) public onlyGovernor {
        require(
            _duration > 0,
            "MarsStakeReward::setDuration: Duration less then 1"
        );
        _setDuration(_duration);
    }

    function recover() public onlyGovernor {
        uint256 amount = xmsBalance();
        xms().transfer(devAddress, amount);
        selfdestruct(payable(devAddress));
    }
}
