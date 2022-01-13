// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../refs/CoreRef.sol";

contract AirDropV2 is CoreRef {
    using SafeMath for uint256;

    mapping(address => uint256) public userReceived;
    address public dev;

    event MultiSend(uint256 amount, uint256 addressAmount);

    constructor(address _core, address _dev) CoreRef(_core) {
        dev = _dev;
    }

    function multiSend(
        address[] calldata _addresses,
        uint256[] calldata _amounts
    ) public onlyGovernor {
        require(
            _addresses.length == _amounts.length,
            "CheckAddress::addBalancers: Add failed"
        );
        uint256 amount;
        uint256 addressAmount;
        for (uint256 i; i < _addresses.length; i++) {
            if (!Address.isContract(_addresses[i])) {
                userReceived[_addresses[i]] = userReceived[_addresses[i]].add(
                    _amounts[i]
                );
                xms().transfer(_addresses[i], _amounts[i]);
                addressAmount++;
                amount = amount + _amounts[i];
            }
        }
        emit MultiSend(amount, addressAmount);
    }

    function multiSend(address[] calldata _addresses, uint256 _amount)
        public
        onlyGovernor
    {
        uint256 amount;
        uint256 addressAmount;
        for (uint256 i; i < _addresses.length; i++) {
            if (!Address.isContract(_addresses[i])) {
                userReceived[_addresses[i]] = userReceived[_addresses[i]].add(
                    _amount
                );
                xms().transfer(_addresses[i], _amount);
                addressAmount++;
                amount = amount + _amount;
            }
        }
        emit MultiSend(amount, addressAmount);
    }

    function recover() public onlyGovernor {
        uint256 amount = xmsBalance();
        xms().transfer(dev, amount);
        selfdestruct(payable(dev));
    }
}
