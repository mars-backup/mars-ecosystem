// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./PCVController.sol";
import "../interfaces/IPCVUniswapDeposit.sol";

/// @title A PCVController implementation
/// @author USDM Protocol
contract BUSDUniswapPCVController is PCVController {
    using SafeERC20 for IERC20;

    IERC20 public busd;

    /// @notice BUSDUniswapPCVController constructor
    /// @param _core USDM Core for reference
    /// @param _busd BUSD
    /// @param _pcvDeposit PCVDeposit
    /// @param _bondingCurve BondingCurve
    constructor(
        address _core,
        address _busd,
        address _pcvDeposit,
        address _bondingCurve
    ) PCVController(_core, _pcvDeposit, _bondingCurve) {
        require(
            _busd != address(0),
            "BUSDUniswapPCVController::constructor: Zero address"
        );
        busd = IERC20(_busd);
    }

    /// @notice Recycle
    function recycle(uint256 _amount) external override onlyGovernor {
        require(
            busd.transfer(bondingCurve, _amount),
            "BUSDUniswapPCVController::recycle: Transfer failed"
        );
    }

    function depositLpMining(uint256 _liquidity)
        external
        onlyGuardianOrGovernor
    {
        _depositLpMining(_liquidity);
    }

    function harvest() external onlyGuardianOrGovernor {
        _harvest();
    }

    function claim() external onlyGuardianOrGovernor {
        _claim();
    }

    function withdrawLpMining(uint256 _liquidity)
        external
        onlyGuardianOrGovernor
    {
        _withdrawLpMining(_liquidity);
    }

    function removeLiquidity(
        uint256 _amount,
        uint256 _priceMin,
        uint256 _priceMax
    ) external onlyGuardianOrGovernor {
        _removeLiquidity(_amount, _priceMin, _priceMax);
    }

    function _removeLiquidity(
        uint256 _liquidity,
        uint256 _priceMin,
        uint256 _priceMax
    ) internal virtual {
        IPCVUniswapDeposit(address(pcvDeposit)).removeLiquidity(
            _liquidity,
            _priceMin,
            _priceMax
        );
    }

    function _harvest() internal virtual {
        IPCVUniswapDeposit(address(pcvDeposit)).harvest();
    }

    function _claim() internal virtual {
        IPCVUniswapDeposit(address(pcvDeposit)).claim();
    }

    function _depositLpMining(uint256 _liquidity) internal virtual {
        IPCVUniswapDeposit(address(pcvDeposit)).depositLpMining(_liquidity);
    }

    function _withdrawLpMining(uint256 _liquidity) internal virtual {
        IPCVUniswapDeposit(address(pcvDeposit)).withdrawLpMining(_liquidity);
    }

    function _deposit(uint256 _amount) internal virtual override {
        busd.safeIncreaseAllowance(address(pcvDeposit), _amount);
        pcvDeposit.deposit(_amount);
    }
}
