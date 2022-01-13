// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../refs/CoreRef.sol";
import "../interfaces/IVestingMaster.sol";

contract VestingAirDrop is CoreRef {
    using SafeMath for uint256;

    address public devAddress;

    IVestingMaster public vestingMaster;

    event MultiSend(uint256 amount, uint256 addressAmount);

    constructor(
        address _core,
        address _devAddress,
        address _vestingMaster
    ) CoreRef(_core) {
        require(
            _devAddress != address(0),
            "VestingAirDrop::constructor: Zero address"
        );
        devAddress = _devAddress;
        require(
            _vestingMaster != address(0),
            "VestingAirDrop::constructor: Zero address"
        );
        vestingMaster = IVestingMaster(_vestingMaster);
    }

    function multiSend(
        address[] calldata _addresses,
        uint256[] calldata _amounts
    ) public onlyGovernor {
        require(
            _addresses.length == _amounts.length,
            "VestingAirDrop::multiSend: Add failed"
        );
        for (uint256 i; i < _addresses.length; i++) {
            require(
                _amounts[i] > 0 &&
                    _amounts[i].mod(
                        vestingMaster.lockedPeriodAmount().add(1)
                    ) ==
                    0,
                "VestingAirDrop::multiSend: Add wrong amount"
            );
            require(
                !Address.isContract(_addresses[i]),
                "VestingAirDrop::multiSend: Wrong address"
            );
        }
        uint256 totalAmount;
        uint256 addressAmount;
        for (uint256 i; i < _addresses.length; i++) {
            uint256 locked = _amounts[i]
                .div(vestingMaster.lockedPeriodAmount().add(1))
                .mul(vestingMaster.lockedPeriodAmount());
            xms().transfer(_addresses[i], _amounts[i].sub(locked));
            xms().transfer(address(vestingMaster), locked);
            vestingMaster.lock(_addresses[i], locked);

            addressAmount++;
            totalAmount = totalAmount + _amounts[i];
        }
        emit MultiSend(totalAmount, addressAmount);
    }

    function recover() public onlyGovernor {
        uint256 amount = xmsBalance();
        xms().transfer(devAddress, amount);
        selfdestruct(payable(devAddress));
    }
}
