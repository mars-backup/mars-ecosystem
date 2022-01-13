// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../refs/CoreRef.sol";
import "../interfaces/IXMSCirculatingSupplyOracle.sol";

abstract contract XMSIncreasedBalanceOracle is IXMSIncreasedBalanceOracle {
    using SafeMath for uint256;

    IXMSToken private _xms;

    address[] public override increasedBalanceAddresses;

    mapping(address => bool) public override increasedBalanceAddressExisted;

    constructor(address xms_) {
        require(
            xms_ != address(0),
            "XMSIncreasedBalanceOracle::constructor: Zero address"
        );
        _xms = IXMSToken(xms_);
    }

    function getIncreasedBalanceAddressesLength()
        public
        view
        override
        returns (uint256)
    {
        return increasedBalanceAddresses.length;
    }

    function addIncreasedBalanceAddress(address _addr) public virtual override {
        require(
            !increasedBalanceAddressExisted[_addr],
            "XMSIncreasedBalanceOracle::addIncreasedBalanceAddress: Exist"
        );
        increasedBalanceAddresses.push(_addr);
        increasedBalanceAddressExisted[_addr] = true;
    }

    function removeIncreasedBalanceAddress(address _addr)
        public
        virtual
        override
    {
        require(
            increasedBalanceAddressExisted[_addr],
            "XMSIncreasedBalanceOracle::removeIncreasedBalanceAddress: Not exist"
        );
        uint256 idx_i;
        for (uint256 i; i < increasedBalanceAddresses.length; i++) {
            if (increasedBalanceAddresses[i] == _addr) {
                idx_i = i;
                break;
            }
        }
        increasedBalanceAddresses[idx_i] = increasedBalanceAddresses[
            increasedBalanceAddresses.length - 1
        ];
        increasedBalanceAddresses.pop();
        delete increasedBalanceAddressExisted[_addr];
    }

    /// @notice Calculate the xms amount of vesting
    function getIncreasedBalanceAmount()
        public
        view
        override
        returns (uint256 xmsAmount)
    {
        address addr;
        for (uint256 i; i < getIncreasedBalanceAddressesLength(); i++) {
            addr = increasedBalanceAddresses[i];
            xmsAmount = xmsAmount.add(_xms.balanceOf(addr));
        }
    }
}

abstract contract XMSReducedBalanceOracle is IXMSReducedBalanceOracle {
    using SafeMath for uint256;

    IXMSToken private _xms;

    address[] public override reducedBalanceAddresses;

    mapping(address => bool) public override reducedBalanceAddressExisted;

    constructor(address xms_) {
        require(
            xms_ != address(0),
            "XMSReducedBalanceOracle::constructor: Zero address"
        );
        _xms = IXMSToken(xms_);
    }

    function getReducedBalanceAddressesLength()
        public
        view
        override
        returns (uint256)
    {
        return reducedBalanceAddresses.length;
    }

    function addReducedBalanceAddress(address _addr) public virtual override {
        require(
            !reducedBalanceAddressExisted[_addr],
            "XMSReducedBalanceOracle::addReducedBalanceAddress: Exist"
        );
        reducedBalanceAddresses.push(_addr);
        reducedBalanceAddressExisted[_addr] = true;
    }

    function removeReducedBalanceAddress(address _addr)
        public
        virtual
        override
    {
        require(
            reducedBalanceAddressExisted[_addr],
            "XMSReducedBalanceOracle::removeReducedBalanceAddress: Not exist"
        );
        uint256 idx_i;
        for (uint256 i; i < reducedBalanceAddresses.length; i++) {
            if (reducedBalanceAddresses[i] == _addr) {
                idx_i = i;
                break;
            }
        }
        reducedBalanceAddresses[idx_i] = reducedBalanceAddresses[
            reducedBalanceAddresses.length - 1
        ];
        reducedBalanceAddresses.pop();
        delete reducedBalanceAddressExisted[_addr];
    }

    /// @notice Calculate the xms amount of vesting
    function getReducedBalanceAmount()
        public
        view
        override
        returns (uint256 xmsAmount)
    {
        address addr;
        for (uint256 i; i < getReducedBalanceAddressesLength(); i++) {
            addr = reducedBalanceAddresses[i];
            xmsAmount = xmsAmount.add(_xms.balanceOf(addr));
        }
    }
}

abstract contract XMSIncreasedStakedOracle is IXMSIncreasedStakedOracle {
    using SafeMath for uint256;
    address[] public override increasedStakedAddresses;

    mapping(address => bool) public override increasedStakedAddressExisted;

    function getIncreasedStakedAddressesLength()
        public
        view
        override
        returns (uint256)
    {
        return increasedStakedAddresses.length;
    }

    function addIncreasedStakedAddress(address _addr) public virtual override {
        require(
            !increasedStakedAddressExisted[_addr],
            "XMSIncreasedStakedOracle::addIncreasedStakedAddress: Exist"
        );
        increasedStakedAddresses.push(_addr);
        increasedStakedAddressExisted[_addr] = true;
    }

    function removeIncreasedStakedAddress(address _addr)
        public
        virtual
        override
    {
        require(
            increasedStakedAddressExisted[_addr],
            "XMSIncreasedStakedOracle::removeIncreasedStakedAddress: Not exist"
        );
        uint256 idx_i;
        for (uint256 i; i < increasedStakedAddresses.length; i++) {
            if (increasedStakedAddresses[i] == _addr) {
                idx_i = i;
                break;
            }
        }
        increasedStakedAddresses[idx_i] = increasedStakedAddresses[
            increasedStakedAddresses.length - 1
        ];
        increasedStakedAddresses.pop();
        delete increasedStakedAddressExisted[_addr];
    }

    /// @notice Calculate the xms amount of staking
    function getIncreasedStakedAmount()
        public
        view
        override
        returns (uint256 xmsAmount)
    {
        address addr;
        for (uint256 i; i < getIncreasedStakedAddressesLength(); i++) {
            addr = increasedStakedAddresses[i];
            xmsAmount = xmsAmount.add(IERC20(addr).totalSupply());
        }
    }
}

contract XMSCirculatingSupplyOracle is
    IXMSCirculatingSupplyOracle,
    CoreRef,
    XMSIncreasedBalanceOracle,
    XMSReducedBalanceOracle,
    XMSIncreasedStakedOracle
{
    using SafeMath for uint256;

    uint256 public override reducedFixedAmount;

    uint256 public override increasedFixedAmount;

    constructor(address _core, address _xms)
        CoreRef(_core)
        XMSIncreasedBalanceOracle(_xms)
        XMSReducedBalanceOracle(_xms)
        XMSIncreasedStakedOracle()
    {}

    function setReducedFixedAmount(uint256 _amount)
        external
        override
        onlyGovernor
    {
        require(
            _amount <= xms().totalSupply(),
            "XMSCirculatingSupplyOracle::setReducedFixedAmount: Exceed total supply"
        );
        reducedFixedAmount = _amount;
    }

    function setIncreasedFixedAmount(uint256 _amount)
        external
        override
        onlyGovernor
    {
        increasedFixedAmount = _amount;
    }

    function addIncreasedBalanceAddress(address _addr)
        public
        override(XMSIncreasedBalanceOracle)
        onlyGovernor
    {
        XMSIncreasedBalanceOracle.addIncreasedBalanceAddress(_addr);
    }

    function removeIncreasedBalanceAddress(address _addr)
        public
        override(XMSIncreasedBalanceOracle)
        onlyGovernor
    {
        XMSIncreasedBalanceOracle.removeIncreasedBalanceAddress(_addr);
    }

    function addReducedBalanceAddress(address _addr)
        public
        override(XMSReducedBalanceOracle)
        onlyGovernor
    {
        XMSReducedBalanceOracle.addReducedBalanceAddress(_addr);
    }

    function removeReducedBalanceAddress(address _addr)
        public
        override(XMSReducedBalanceOracle)
        onlyGovernor
    {
        XMSReducedBalanceOracle.removeReducedBalanceAddress(_addr);
    }

    function addIncreasedStakedAddress(address _addr)
        public
        override(XMSIncreasedStakedOracle)
        onlyGovernor
    {
        XMSIncreasedStakedOracle.addIncreasedStakedAddress(_addr);
    }

    function removeIncreasedStakedAddress(address _addr)
        public
        override(XMSIncreasedStakedOracle)
        onlyGovernor
    {
        XMSIncreasedStakedOracle.removeIncreasedStakedAddress(_addr);
    }

    function consult() public view override returns (uint256) {
        return
            xms()
                .totalSupply()
                .add(increasedFixedAmount)
                .add(getIncreasedBalanceAmount())
                .add(getIncreasedStakedAmount())
                .sub(reducedFixedAmount)
                .sub(getReducedBalanceAmount());
    }
}
