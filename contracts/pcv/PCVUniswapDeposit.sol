// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/IPCVUniswapDeposit.sol";
import "../interfaces/IGenesisGroup.sol";
import "../refs/UniRef.sol";

/// @title Abstract implementation for Uniswap PCV Deposit
/// @author USDM Protocol
abstract contract PCVUniswapDeposit is IPCVUniswapDeposit, UniRef {
    ILiquidityMiningMaster public override lpMiningMaster;

    IVestingMaster public override vestingMaster;

    IERC20 public override rewardToken;

    /// @notice Max basis point from peg lp for adding liquidity
    uint256 public override maxBPForAddLiquidity = 100;
    /// @notice Max basis point from peg lp for removing liquidity
    uint256 public override maxBPForRemoveLiquidity = 100;

    /// @notice Price fluctuation range for allocation
    uint256 public override fluctuationRange = 1;

    /// @notice Price fluctuation range precision for allocation
    uint256 public override fluctuationRangePrecision = 10_000;

    /// @notice Uniswap PCV Deposit constructor
    /// @param _core USDM Core for reference
    /// @param _pair Uniswap Pair to deposit to
    /// @param _router Uniswap Router
    /// @param _factory Uniswap Factory
    /// @param _lpMiningMaster Liquidity mining master
    /// @param _vestingMaster Vesting master
    /// @param _rewardToken Mining reward token
    constructor(
        address _core,
        address _pair,
        address _router,
        address _factory,
        address _lpMiningMaster,
        address _vestingMaster,
        address _rewardToken
    ) CoreRef(_core) UniRef(_pair, _router, _factory) {
        lpMiningMaster = ILiquidityMiningMaster(_lpMiningMaster);
        rewardToken = IERC20(_rewardToken);
        vestingMaster = IVestingMaster(_vestingMaster);
    }

    modifier miningMasterExist() {
        if (address(lpMiningMaster) != address(0)) {
            _;
        }
    }

    modifier vestingMasterExist() {
        if (address(vestingMaster) != address(0)) {
            _;
        }
    }

    /// @notice Withdraw tokens from the PCV allocation
    /// @param _amount Amount of tokens withdrawn
    function withdraw(uint256 _amount) external override onlyPCVController {
        _transferWithdrawn(msg.sender, _amount);
        emit Withdrawal(msg.sender, msg.sender, _amount);
    }

    function removeLiquidity(
        uint256 liquidity,
        uint256 priceMin,
        uint256 priceMax
    ) external override onlyPCVController {
        require(
            _isValidPriceRange(maxBPForRemoveLiquidity),
            "PCVUniswapDeposit::removeLiquidity: Price out"
        );
        (Decimal.D256 memory uniPrice, , ) = _getUniswapPrice();
        require(
            uniPrice.value >= priceMin && uniPrice.value <= priceMax,
            "PCVUniswapDeposit::removeLiquidity: Price discrepancy"
        );
        _removeLiquidity(liquidity);
    }

    function harvest() external override miningMasterExist onlyPCVController {
        _harvest();
    }

    function claim() external override vestingMasterExist onlyPCVController {
        _claim();
    }

    function depositLpMining(uint256 liquidity)
        external
        override
        miningMasterExist
        onlyPCVController
    {
        _depositLpMining(liquidity);
    }

    function withdrawLpMining(uint256 liquidity)
        external
        override
        miningMasterExist
        onlyPCVController
    {
        _withdrawLpMining(liquidity);
    }

    /// @notice Check price is in valid range
    function _isValidPriceRange(uint256 maxBP)
        internal
        view
        virtual
        returns (bool);

    function _addLiquidity(uint256 amount) internal virtual;

    function _removeLiquidity(uint256 liquidity) internal virtual;

    function _harvest() internal virtual;

    function _claim() internal virtual;

    function _depositLpMining(uint256 liquidity) internal virtual;

    function _withdrawLpMining(uint256 liquidity) internal virtual;

    function _getLpMiningPid(address _pair)
        internal
        view
        virtual
        returns (uint256);

    function _transferWithdrawn(address to, uint256 amount) internal virtual;

    /// @notice Set new liquidity mining master
    function setLpMiningMaster(address _lpMiningMaster, address _rewardToken)
        external
        override
        onlyGovernor
    {
        lpMiningMaster = ILiquidityMiningMaster(_lpMiningMaster);
        rewardToken = IERC20(_rewardToken);
    }

    /// @notice Set new vesting master
    function setVestingMaster(address _vestingMaster)
        external
        override
        onlyGovernor
    {
        vestingMaster = IVestingMaster(_vestingMaster);
    }

    /// @notice Sets max basis point from peg lp for adding liquidity
    function setMaxBPForAddLiquidity(uint256 _maxBPForAddLiquidity)
        external
        override
        onlyGovernor
    {
        maxBPForAddLiquidity = _maxBPForAddLiquidity;
        emit MaxBPForAddLiquidityUpdate(_maxBPForAddLiquidity);
    }

    /// @notice Sets max basis point from peg lp for removing liquidity
    function setMaxBPForRemoveLiquidity(uint256 _maxBPForRemoveLiquidity)
        external
        override
        onlyGovernor
    {
        maxBPForRemoveLiquidity = _maxBPForRemoveLiquidity;
        emit MaxBPForRemoveLiquidityUpdate(_maxBPForRemoveLiquidity);
    }
}
