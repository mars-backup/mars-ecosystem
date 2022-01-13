// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./Permissions.sol";
import "../interfaces/ICore.sol";
import "../base/XMSToken.sol";
import "../base/USDMToken.sol";

/// @title Source of truth for USDM Protocol
/// @author USDM Protocol
/// @notice Maintains roles, access control, usdm, xms, genesisGroup, and the XMS treasury
contract Core is ICore, Permissions {
    /// @notice XMS support ratio
    uint256 public override xmsSupportRatio = 250_000;
    /// @notice XMS support ratio precision
    uint256 public override xmsSupportRatioPrecision = 1e5;

    /// @notice The address of the USDM contract
    IUSDMToken public override usdm;

    /// @notice The address of the XMS contract
    IXMSToken public override xms;

    /// @notice The address of the GenesisGroup contract
    address public override genesisGroup;
    /// @notice Determines whether in genesis period or not
    bool public override hasGenesisGroupCompleted;

    constructor() {
        _setupGovernor(msg.sender);
    }

    /// @notice Sets XMS support ratio, x * 10 ** 5
    /// @param _xmsSupportRatio New XMS support ratio
    function setXMSSupportRatio(uint256 _xmsSupportRatio)
        external
        override
        onlyGovernor
    {
        _setXMSSupportRatio(_xmsSupportRatio);
    }

    /// @notice Sets USDM address to a new address
    /// @param token New usdm address
    function setUSDM(address token) external override onlyGovernor {
        _setUSDM(token);
    }

    /// @notice Sets XMS address to a new address
    /// @param token New xms address
    function setXMS(address token) external override onlyGovernor {
        _setXMS(token);
    }

    /// @notice Sets Genesis Group address
    /// @param _genesisGroup New genesis group address
    function setGenesisGroup(address _genesisGroup)
        external
        override
        onlyGovernor
    {
        genesisGroup = _genesisGroup;
        emit GenesisGroupUpdate(_genesisGroup);
    }

    /// @notice Sends XMS tokens from treasury to an address
    /// @param to The address to send XMS to
    /// @param amount The amount of XMS to send
    function allocateXMS(address to, uint256 amount)
        external
        override
        onlyGovernor
    {
        allocateToken(address(xms), to, amount);
    }

    /// @notice Sends X tokens from treasury to an address
    /// @param _token The X token
    /// @param to The address to send X to
    /// @param amount The amount of X to send
    function allocateToken(
        address _token,
        address to,
        uint256 amount
    ) public override onlyGovernor {
        IERC20 token = IERC20(_token);
        require(
            token.balanceOf(address(this)) >= amount,
            "Core::allocateToken: Not enough token"
        );

        require(
            token.transfer(to, amount),
            "Core::allocateToken: Transfer failed"
        );

        emit TokenAllocation(to, amount);
    }

    /// @notice Approve XMS tokens from treasury to an address
    /// @param to The address to approve XMS to
    /// @param amount The amount of XMS to approve
    function approveXMS(address to, uint256 amount)
        public
        override
        onlyGovernor
    {
        approveToken(address(xms), to, amount);
    }

    /// @notice Approve X tokens from treasury to an address
    /// @param _token The X token
    /// @param to The address to approve X to
    /// @param amount The amount of X to approve
    function approveToken(
        address _token,
        address to,
        uint256 amount
    ) public override onlyGovernor {
        IERC20 token = IERC20(_token);

        require(
            token.approve(to, amount),
            "Core::approveToken: Approve failed"
        );

        emit TokenApprove(to, amount);
    }

    /// @notice Marks the end of the genesis period
    /// @dev Can only be called once
    function completeGenesisGroup() external override {
        require(
            !hasGenesisGroupCompleted,
            "Core::completeGenesisGroup: Genesis Group already complete"
        );
        require(
            msg.sender == genesisGroup,
            "Core::completeGenesisGroup: Caller is not Genesis Group"
        );

        hasGenesisGroupCompleted = true;

        // solhint-disable-next-line not-rely-on-time
        emit GenesisPeriodComplete(block.timestamp);
    }

    function _setXMSSupportRatio(uint256 _xmsSupportRatio) internal {
        xmsSupportRatio = _xmsSupportRatio;
        emit XMSSupportRatioUpdate(_xmsSupportRatio);
    }

    function _setUSDM(address token) internal {
        usdm = IUSDMToken(token);
        emit USDMUpdate(token);
    }

    function _setXMS(address token) internal {
        xms = IXMSToken(token);
        emit XMSUpdate(token);
    }
}
