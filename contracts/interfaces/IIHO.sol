// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libs/Decimal.sol";

/// @title IHO interface
/// @author USDM Protocol
interface IIHO {
    struct UserInfo {
        uint256 amount; // How many MIHO tokens the user has after launch
        uint256 debt; // Debt
    }
    // ----------- Events -----------

    event Purchase(address indexed to, uint256 value);

    event Claim(
        address indexed to,
        uint256 amountIn,
        uint256 targetTokenAmount,
        uint256 commitTokenAmount
    );

    event Launch(uint256 timestamp);

    // ----------- Governor only state changing API -----------

    function initIHO(uint256 startTime, uint256 _targetTokenPrice) external;

    // ----------- State changing API -----------

    function purchase(address to, uint256 value) external payable;

    function claim(address to) external;

    function launch() external;

    function emergencyExit(address from, address payable to) external;

    // ----------- Getters -----------

    function targetTokenPrice() external view returns (uint256);

    function userInfo(address user) external view returns (uint256, uint256);

    function getAmountOut(uint256 amountIn, bool inclusive)
        external
        view
        returns (uint256 targetTokenAmount);

    function getUnClaimableAmount(address to)
        external
        view
        returns (uint256 targetTokenAmount);

    function getAmountsToClaim(address to)
        external
        view
        returns (uint256 targetTokenAmount, uint256 commitTokenAmount);

    function supersuper() external view returns (bool);

    function launchBlock() external view returns (uint256);

    function launchTimestamp() external view returns (uint256);
}
