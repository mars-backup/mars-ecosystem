// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ISwapMiningOracle.sol";

interface ISwapMining {
    struct UserInfo {
        uint256 quantity; // How many LP tokens the user has provided
        uint256 blockNumber; // Last transaction block
    }

    struct PoolInfo {
        address pair; // Trading pairs that can be mined
        uint256 quantity; // Current amount of LPs
        uint256 totalQuantity; // All quantity
        uint256 allocPoint; // How many allocation points assigned to this pool
        uint256 allocTokenAmount; // How many token
        uint256 lastRewardBlock; // Last transaction block
    }

    // ----------- Events -----------

    event Withdraw(address indexed user, uint256 amount);
    event UpdateTokenPerBlock(address indexed user, uint256 tokenPerBlock);
    event UpdateEndBlock(address indexed user, uint256 endBlock);
    event UpdateVestingMaster(address indexed user, address vestingMaster);

    // ----------- Governor only state changing API -----------

    function addPool(
        uint256 allocPoint,
        address pair,
        bool withUpdate
    ) external;

    function setPool(
        uint256 pid,
        uint256 allocPoint,
        bool withUpdate
    ) external;

    function updateTokenPerBlock(uint256) external;

    function addWhitelist(address token) external returns (bool);

    function delWhitelist(address token) external returns (bool);

    function setRouter(address) external;

    function setSwapMiningOracle(ISwapMiningOracle) external;

    function updateEndBlock(uint256) external;

    function updateVestingMaster(address) external;

    // ----------- Router State changing api -----------

    function swap(
        address account,
        address input,
        address output,
        uint256 amount
    ) external returns (bool);

    // ----------- State changing api -----------

    function massUpdatePools() external;

    function updatePool(uint256 pid) external;

    function withdraw() external;

    // ----------- Getters -----------
    function rewardToken() external view returns (IERC20);

    function tokenPerBlock() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function startBlock() external view returns (uint256);

    function endBlock() external view returns (uint256);

    function router() external view returns (address);

    function swapMiningOracle() external view returns (ISwapMiningOracle);

    function factory() external view returns (IMarsSwapFactory);

    function targetToken() external view returns (address);

    function pair2Pid(address pair) external view returns (uint256);

    function poolInfo(uint256 pid)
        external
        view
        returns (
            address pair,
            uint256 quantity,
            uint256 totalQuantity,
            uint256 allocPoint,
            uint256 allocTokenAmount,
            uint256 lastRewardBlock
        );

    function userInfo(uint256 pid, address user)
        external
        view
        returns (uint256 quantity, uint256 blockNumber);

    function poolExistence(address pair) external view returns (bool);

    function poolLength() external view returns (uint256);

    function getWhitelistsLength() external view returns (uint256);

    function isWhitelist(address token) external view returns (bool);

    function getWhitelist(uint256 index) external view returns (address);

    function getTokenBlockReward(uint256 lastRewardBlock)
        external
        view
        returns (uint256);

    function pendingToken(uint256 pid, address user)
        external
        view
        returns (uint256, uint256);

    function getPoolInfo(uint256 pid)
        external
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getQuantity(
        address outputToken,
        uint256 outputAmount,
        address anchorToken
    ) external view returns (uint256);
}
