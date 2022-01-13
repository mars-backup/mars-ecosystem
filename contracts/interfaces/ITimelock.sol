// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface ITimelock {
    // ----------- State changing api -----------

    function acceptAdmin() external;

    function queueTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external returns (bytes32);

    function cancelTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external;

    function executeTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external payable returns (bytes memory);

    // ----------- Getters -----------

    function delay() external view returns (uint256);

    // solhint-disable-next-line func-name-mixedcase
    function GRACE_PERIOD() external view returns (uint256);

    function queuedTransactions(bytes32 hash) external view returns (bool);
}
