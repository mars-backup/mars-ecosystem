// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./IPCVDeposit.sol";
import "./IVestingMaster.sol";
import "../libs/Decimal.sol";

interface ILiquidityMiningMaster {
    function deposit(uint256 pid, uint256 amount) external;

    function withdraw(uint256 pid, uint256 amount) external;

    // ----------- Getters -----------
    function userInfo(uint256 pid, address user)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);

    function pair2Pid(address pair) external view returns (uint256);

    function poolInfo(uint256 pid)
        external
        view
        returns (
            IERC20 lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accTokenPerShare
        );
}

/// @title A Uniswap PCV Deposit interface
/// @author USDM Protocol
interface IPCVUniswapDeposit is IPCVDeposit {
    // ----------- Events -----------

    event MaxBPForAddLiquidityUpdate(uint256 maxBPForAddLiquidity);

    event MaxBPForRemoveLiquidityUpdate(uint256 maxBPForRemoveLiquidity);

    // ----------- PCV Controller only state changing api -----------

    function removeLiquidity(
        uint256 liquidity,
        uint256 priceMin,
        uint256 priceMax
    ) external;

    function depositLpMining(uint256 liquidity) external;

    function withdrawLpMining(uint256 liquidity) external;

    function harvest() external;

    function claim() external;

    function setLpMiningMaster(address lpMiningMaster_, address rewardToken_)
        external;

    function setVestingMaster(address) external;

    function setMaxBPForAddLiquidity(uint256) external;

    function setMaxBPForRemoveLiquidity(uint256) external;

    // ----------- Getters -----------

    function getCurrentPrice() external view returns (Decimal.D256 memory);

    function maxBPForAddLiquidity() external view returns (uint256);

    function maxBPForRemoveLiquidity() external view returns (uint256);

    function fluctuationRange() external view returns (uint256);

    function fluctuationRangePrecision() external view returns (uint256);

    function lpMiningMaster() external view returns (ILiquidityMiningMaster);

    function vestingMaster() external view returns (IVestingMaster);

    function rewardToken() external view returns (IERC20);
}
