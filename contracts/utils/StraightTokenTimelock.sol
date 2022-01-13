// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// Inspired by OpenZeppelin TokenTimelock contract
// Reference: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/TokenTimelock.sol

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Timed.sol";
import "./LinearTokenTimelock.sol";

contract StraightTokenTimelock is LinearTokenTimelock {
    using SafeMath for uint256;

    constructor(
        address _beneficiary,
        uint256 _startTime,
        uint256 _duration,
        address _lockedToken
    ) LinearTokenTimelock(_beneficiary, _startTime, _duration, _lockedToken) {}

    /// @notice Releases `amount` unlocked tokens to address `to`
    function release(address to, uint256 amount)
        external
        override
        onlyBeneficiary
        balanceCheck
    {
        require(
            amount != 0,
            "StraightTokenTimelock::release: No amount desired"
        );

        uint256 available = availableForRelease();
        require(
            amount <= available,
            "StraightTokenTimelock::release: Not enough released tokens"
        );

        _release(to, amount);
    }

    /// @notice Amount of held tokens unlocked and available for release
    function availableForRelease() public view override returns (uint256) {
        uint256 elapsed = timeSinceStart();
        uint256 _duration = duration;

        uint256 totalAvailable = initialBalance.mul(elapsed) / _duration;
        uint256 netAvailable = totalAvailable.sub(alreadyReleasedAmount());
        return netAvailable;
    }
}
