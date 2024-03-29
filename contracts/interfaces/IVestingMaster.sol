// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVestingMaster {
    struct LockedReward {
        uint256 locked;
        uint256 timestamp;
    }
    // ----------- Events -----------

    event Lock(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);

    // ----------- Farms only State changing api -----------

    function lock(address, uint256) external;

    // ----------- state changing API -----------

    function claim() external;

    // ----------- Getters -----------

    function period() external view returns (uint256);

    function lockedPeriodAmount() external view returns (uint256);

    function vestingToken() external view returns (IERC20);

    function userLockedRewards(address account, uint256 idx)
        external
        view
        returns (uint256, uint256);

    function totalLockedRewards() external view returns (uint256);

    function getVestingAmount() external view returns (uint256, uint256);
}
