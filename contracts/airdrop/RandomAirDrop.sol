// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/utils/Address.sol";
import "../refs/CoreRef.sol";

contract RandomAirDrop is CoreRef {
    mapping(address => uint256) public exist;
    address public devAddress;

    event MultiSend(uint256 amount, uint256 addressAmount);

    constructor(address _core, address _devAddress) CoreRef(_core) {
        devAddress = _devAddress;
    }

    function multiSend(
        address[] calldata _addresses,
        uint256[] calldata _amounts
    ) public onlyGovernor {
        require(
            _addresses.length == _amounts.length,
            "RandomAirDrop::multiSend: Add failed"
        );
        uint256 amount;
        uint256 addressAmount;
        for (uint256 i; i < _addresses.length; i++) {
            require(
                _amounts[i] <= 1e18,
                "RandomAirDrop::multiSend: Add wrong amount"
            );
            if (
                exist[_addresses[i]] == 0 && !Address.isContract(_addresses[i])
            ) {
                exist[_addresses[i]] = _amounts[i];
                xms().transfer(_addresses[i], _amounts[i]);
                addressAmount++;
                amount = amount + _amounts[i];
            }
        }
        emit MultiSend(amount, addressAmount);
    }

    function recover() public onlyGovernor {
        uint256 amount = xmsBalance();
        xms().transfer(devAddress, amount);
        selfdestruct(payable(devAddress));
    }
}
