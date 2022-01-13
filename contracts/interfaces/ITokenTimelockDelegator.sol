// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/IXMSToken.sol";

/// @title TokenTimelockDelegator interface
/// @author USDM Protocol
interface ITokenTimelockDelegator {
    // ----------- Events -----------

    event Delegate(address indexed delegatee, uint256 amount);

    event Undelegate(address indexed delegatee, uint256 amount);

    // ----------- Beneficiary only state changing api -----------

    function delegate(address delegatee, uint256 amount) external;

    function undelegate(address delegatee) external returns (uint256);

    // ----------- Getters -----------

    function delegateContract(address delegatee)
        external
        view
        returns (address);

    function delegateAmount(address delegatee) external view returns (uint256);

    function totalDelegated() external view returns (uint256);

    function xms() external view returns (IXMSToken);
}
