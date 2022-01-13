// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title LinearTokenTimelock interface
/// @author USDM Protocol
interface ILinearTokenTimelock {
    // ----------- Events -----------

    event Release(
        address indexed beneficiary,
        address indexed recipient,
        uint256 amount
    );
    event BeneficiaryUpdate(address indexed beneficiary);
    event PendingBeneficiaryUpdate(address indexed pendingBeneficiary);

    // ----------- State changing api -----------

    function updateBalance() external;

    function release(address to, uint256 amount) external;

    function releaseMax(address to) external;

    function setPendingBeneficiary(address) external;

    function acceptBeneficiary() external;

    // ----------- Getters -----------

    function lockedToken() external view returns (IERC20);

    function beneficiary() external view returns (address);

    function pendingBeneficiary() external view returns (address);

    function initialBalance() external view returns (uint256);

    function availableForRelease() external view returns (uint256);

    function totalToken() external view returns (uint256);

    function alreadyReleasedAmount() external view returns (uint256);
}
