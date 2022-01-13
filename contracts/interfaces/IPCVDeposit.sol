// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

/// @title A PCV Deposit interface
/// @author USDM Protocol
interface IPCVDeposit {
    // ----------- Events -----------

    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(
        address indexed caller,
        address indexed to,
        uint256 amount
    );

    // ----------- State changing api -----------

    function deposit(uint256 amount) external payable;

    // ----------- PCV Controller only state changing api -----------

    function withdraw(uint256 amount) external;

    // ----------- Getters -----------

    function totalValue() external view returns (uint256);
}
