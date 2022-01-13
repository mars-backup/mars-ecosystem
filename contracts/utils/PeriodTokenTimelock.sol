// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// Inspired by OpenZeppelin TokenTimelock contract
// Reference: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/TokenTimelock.sol

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Timed.sol";
import "./LinearTokenTimelock.sol";

contract PeriodTokenTimelock is LinearTokenTimelock {
    using SafeMath for uint256;

    uint256 internal _period;

    constructor(
        address _beneficiary,
        uint256 _startTime,
        uint256 _duration,
        uint256 period_,
        address _lockedToken
    ) LinearTokenTimelock(_beneficiary, _startTime, _duration, _lockedToken) {
        require(period_ > 0, "PeriodTokenTimelock::constructor: Period wrong");
        _period = period_;
    }

    /// @notice Releases `amount` unlocked tokens to address `to`
    function release(address to, uint256 amount)
        external
        override
        onlyBeneficiary
        balanceCheck
    {
        require(amount != 0, "PeriodTokenTimelock::release: No amount desired");

        uint256 available = availableForRelease();
        require(
            amount <= available,
            "PeriodTokenTimelock::release: Not enough released tokens"
        );

        _release(to, amount);
    }

    /// @notice Amount of held tokens unlocked and available for release
    function availableForRelease() public view override returns (uint256) {
        uint256 elapsed = timeSinceStart();
        uint256 totalAvailable;
        if (elapsed >= duration) {
            totalAvailable = initialBalance;
        } else {
            uint256 elapsedPeriod = elapsed.div(_period);
            uint256 periodDuration = duration.div(_period).add(
                duration.mod(_period) > 0 ? 1 : 0
            );

            totalAvailable = initialBalance.mul(elapsedPeriod) / periodDuration;
        }

        uint256 netAvailable = totalAvailable.sub(alreadyReleasedAmount());
        return netAvailable;
    }
}
