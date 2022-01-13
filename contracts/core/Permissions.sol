// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IPermissions.sol";

/// @title Access control module for Core
/// @author USDM Protocol
contract Permissions is IPermissions, AccessControl {
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PCV_CONTROLLER_ROLE =
        keccak256("PCV_CONTROLLER_ROLE");
    bytes32 public constant GOVERN_ROLE = keccak256("GOVERN_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");

    constructor() {
        // Appointed as a governor so guardian can have indirect access to revoke ability
        _setupGovernor(address(this));

        _setRoleAdmin(MINTER_ROLE, GOVERN_ROLE);
        _setRoleAdmin(BURNER_ROLE, GOVERN_ROLE);
        _setRoleAdmin(PCV_CONTROLLER_ROLE, GOVERN_ROLE);
        _setRoleAdmin(GOVERN_ROLE, GOVERN_ROLE);
        _setRoleAdmin(GUARDIAN_ROLE, GOVERN_ROLE);
    }

    modifier onlyGovernor() {
        require(
            isGovernor(msg.sender),
            "Permissions::onlyGovernor: Caller is not a governor"
        );
        _;
    }

    modifier onlyGuardian() {
        require(
            isGuardian(msg.sender),
            "Permissions::onlyGuardian: Caller is not a guardian"
        );
        _;
    }

    /// @notice Creates a new role to be maintained
    /// @param role The new role id
    /// @param adminRole The admin role id for `role`
    /// @dev Can also be used to update admin of existing role
    function createRole(bytes32 role, bytes32 adminRole)
        external
        override
        onlyGovernor
    {
        _setRoleAdmin(role, adminRole);
    }

    /// @notice Grants minter role to address
    /// @param minter New minter
    function grantMinter(address minter) external override onlyGovernor {
        grantRole(MINTER_ROLE, minter);
    }

    /// @notice Grants burner role to address
    /// @param burner New burner
    function grantBurner(address burner) external override onlyGovernor {
        grantRole(BURNER_ROLE, burner);
    }

    /// @notice Grants controller role to address
    /// @param pcvController New controller
    function grantPCVController(address pcvController)
        external
        override
        onlyGovernor
    {
        grantRole(PCV_CONTROLLER_ROLE, pcvController);
    }

    /// @notice Grants governor role to address
    /// @param governor New governor
    function grantGovernor(address governor) external override onlyGovernor {
        grantRole(GOVERN_ROLE, governor);
    }

    /// @notice Grants guardian role to address
    /// @param guardian New guardian
    function grantGuardian(address guardian) external override onlyGovernor {
        grantRole(GUARDIAN_ROLE, guardian);
    }

    /// @notice Revokes minter role from address
    /// @param minter Ex minter
    function revokeMinter(address minter) external override onlyGovernor {
        revokeRole(MINTER_ROLE, minter);
    }

    /// @notice Revokes burner role from address
    /// @param burner Ex burner
    function revokeBurner(address burner) external override onlyGovernor {
        revokeRole(BURNER_ROLE, burner);
    }

    /// @notice Revokes pcvController role from address
    /// @param pcvController Ex pcvController
    function revokePCVController(address pcvController)
        external
        override
        onlyGovernor
    {
        revokeRole(PCV_CONTROLLER_ROLE, pcvController);
    }

    /// @notice Revokes governor role from address
    /// @param governor Ex governor
    function revokeGovernor(address governor) external override onlyGovernor {
        revokeRole(GOVERN_ROLE, governor);
    }

    /// @notice Revokes guardian role from address
    /// @param guardian Ex guardian
    function revokeGuardian(address guardian) external override onlyGovernor {
        revokeRole(GUARDIAN_ROLE, guardian);
    }

    /// @notice Revokes a role from address
    /// @param role The role to revoke
    /// @param account The address to revoke the role from
    function revokeOverride(bytes32 role, address account)
        external
        override
        onlyGuardian
    {
        require(
            role != GOVERN_ROLE,
            "Permissions::revokeOverride: Guardian cannot revoke governor"
        );

        // External call because this contract is appointed as a governor and has access to revoke
        this.revokeRole(role, account);
    }

    /// @notice Checks if address is a minter
    /// @param _address Address to check
    /// @return true _address is a minter
    function isMinter(address _address) external view override returns (bool) {
        return hasRole(MINTER_ROLE, _address);
    }

    /// @notice Checks if address is a burner
    /// @param _address Address to check
    /// @return true _address is a burner
    function isBurner(address _address) external view override returns (bool) {
        return hasRole(BURNER_ROLE, _address);
    }

    /// @notice Checks if address is a controller
    /// @param _address Address to check
    /// @return true _address is a controller
    function isPCVController(address _address)
        external
        view
        override
        returns (bool)
    {
        return hasRole(PCV_CONTROLLER_ROLE, _address);
    }

    /// @notice Checks if address is a governor
    /// @param _address Address to check
    /// @return true _address is a governor
    function isGovernor(address _address)
        public
        view
        virtual
        override
        returns (bool)
    {
        return hasRole(GOVERN_ROLE, _address);
    }

    /// @notice Checks if address is a guardian
    /// @param _address Address to check
    /// @return true _address is a guardian
    function isGuardian(address _address) public view override returns (bool) {
        return hasRole(GUARDIAN_ROLE, _address);
    }

    function _setupGovernor(address governor) internal {
        _setupRole(GOVERN_ROLE, governor);
    }

    function _setupMinter(address minter) internal {
        _setupRole(MINTER_ROLE, minter);
    }

    function _setupBurner(address burner) internal {
        _setupRole(BURNER_ROLE, burner);
    }
}
