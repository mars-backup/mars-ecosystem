// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/SafeCast.sol";

/// @title An abstract contract for timed events
/// @author USDM Protocol
abstract contract Timed {
    using SafeCast for uint256;

    /// @notice The start timestamp of the timed period
    uint256 public startTime;

    /// @notice The duration of the timed period
    uint256 public duration;

    event DurationUpdate(uint256 _duration);

    event TimerReset(uint256 _startTime);

    constructor(uint256 _duration) {
        _setDuration(_duration);
    }

    modifier duringTime() {
        require(isTimeStarted(), "Timed::duringTime: Time not started");
        require(!isTimeEnded(), "Timed::duringTime: Time ended");
        _;
    }

    modifier afterTime() {
        require(isTimeEnded(), "Timed::afterTime: Time not ended");
        _;
    }

    /// @notice Return true if time period has ended
    function isTimeEnded() public view returns (bool) {
        return remainingTime() == 0;
    }

    /// @notice Number of seconds remaining until time is up
    /// @return Remaining
    function remainingTime() public view returns (uint256) {
        return duration - timeSinceStart(); // Duration always >= timeSinceStart which is on [0,d]
    }

    /// @notice Number of seconds since contract was initialized
    /// @return Timestamp
    /// @dev Will be less than or equal to duration
    function timeSinceStart() public view returns (uint256) {
        if (!isTimeStarted()) {
            return 0; // Uninitialized
        }
        uint256 _duration = duration;
        // solhint-disable-next-line not-rely-on-time
        uint256 timePassed = block.timestamp - startTime; // Block timestamp always >= startTime
        return timePassed > _duration ? _duration : timePassed;
    }

    function isTimeStarted() public view returns (bool) {
        return startTime > 0 && block.timestamp >= startTime;
    }

    function _initTimed(uint256 _startTime) internal {
        // solhint-disable-next-line not-rely-on-time
        startTime = _startTime > 0 ? _startTime : block.timestamp;

        // solhint-disable-next-line not-rely-on-time
        emit TimerReset(startTime);
    }

    function _setDuration(uint256 _duration) internal {
        duration = _duration;
        emit DurationUpdate(_duration);
    }
}
