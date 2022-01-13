// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../refs/OracleRef.sol";

contract OracleIncentives is OracleRef {
    /// @notice Amount of USDM paid for updating when incentivize
    uint256 public incentiveAmount;

    /// @notice OracleIncentives constructor
    /// @param _core USDM Core address to reference
    /// @param _oracle Oracle
    /// @param _incentive The amount rewarded to the caller of updating
    constructor(
        address _core,
        address[] memory _oracle,
        uint256 _incentive
    ) CoreRef(_core) OracleRef(_oracle) {
        incentiveAmount = _incentive;
        _pause();
    }

    function updateXMSForUSDMMROracle() public whenNotPaused {
        xmsForUSDMMROracle.update();
        _incentivize();
    }

    function updateXMSForUSDMSupplyCapOracle() public whenNotPaused {
        xmsForUSDMSupplyCapOracle.update();
        _incentivize();
    }

    /// @notice If period has passed, reward caller and reset window
    function _incentivize() internal virtual {
        usdm().mint(msg.sender, incentiveAmount);
    }

    /// @notice Sets the incentive amount
    function setIncentiveAmount(uint256 _incentiveAmount)
        external
        onlyGovernor
    {
        incentiveAmount = _incentiveAmount;
    }
}
