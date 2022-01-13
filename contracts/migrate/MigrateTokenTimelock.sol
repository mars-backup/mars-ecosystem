// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/proxy/Initializable.sol";
import "../dao/PeriodTokenTimelockDelegator.sol";
import "../refs/CoreRef.sol";

contract MigrateTokenTimelock is CoreRef, Initializable {
    LinearTokenTimelockDelegator public devLock;
    LinearTokenTimelockDelegator public investorLock;

    constructor(
        address _core,
        address _xms,
        address _dev,
        uint256 _devDuration,
        address _investor,
        uint256 _investorDuration
    ) CoreRef(_core) {
        devLock = new PeriodTokenTimelockDelegator(
            _xms,
            _dev,
            block.timestamp,
            _devDuration,
            3600 * 24 * 30
        );
        investorLock = new PeriodTokenTimelockDelegator(
            _xms,
            _investor,
            block.timestamp,
            _investorDuration,
            3600 * 24 * 30
        );
    }

    function initialize() external initializer onlyGuardianOrGovernor {
        ILinearTokenTimelock(address(devLock)).updateBalance();
        ILinearTokenTimelock(address(investorLock)).updateBalance();
    }

    function getAddress() external view returns (address, address) {
        return (address(devLock), address(investorLock));
    }
}
