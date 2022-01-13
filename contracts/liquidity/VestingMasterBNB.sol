// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../libs/TransferHelper.sol";
import "./VestingMaster.sol";

// VestingMaster,
contract VestingMasterBNB is VestingMaster {
    using SafeMath for uint256;

    constructor(
        address _core,
        uint256 _period,
        uint256 _lockedPeriodAmount,
        address _WBNB
    ) VestingMaster(_core, _period, _lockedPeriodAmount, _WBNB) {}

    receive() external payable {}

    function _safeTransfer(address _to, uint256 _amount) internal override {
        TransferHelper.safeTransferETH(_to, _amount);
    }
}
