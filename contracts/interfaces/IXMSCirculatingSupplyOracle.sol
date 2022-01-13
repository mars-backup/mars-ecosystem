// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

/// @author USDM Protocol
interface IXMSIncreasedBalanceOracle {
    // ----------- Events -----------

    // ----------- Governor only state changing api -----------

    function addIncreasedBalanceAddress(address addr) external;

    function removeIncreasedBalanceAddress(address addr) external;

    // ----------- Genesis Group only state changing api -----------

    // ----------- Getters -----------

    function getIncreasedBalanceAddressesLength()
        external
        view
        returns (uint256);

    function increasedBalanceAddresses(uint256 idx)
        external
        view
        returns (address);

    function increasedBalanceAddressExisted(address addr)
        external
        view
        returns (bool);

    function getIncreasedBalanceAmount()
        external
        view
        returns (uint256 xmsAmount);
}

interface IXMSReducedBalanceOracle {
    // ----------- Events -----------

    // ----------- Governor only state changing api -----------

    function addReducedBalanceAddress(address addr) external;

    function removeReducedBalanceAddress(address addr) external;

    // ----------- Genesis Group only state changing api -----------

    // ----------- Getters -----------

    function getReducedBalanceAddressesLength() external view returns (uint256);

    function reducedBalanceAddresses(uint256 idx)
        external
        view
        returns (address);

    function reducedBalanceAddressExisted(address addr)
        external
        view
        returns (bool);

    function getReducedBalanceAmount()
        external
        view
        returns (uint256 xmsAmount);
}

interface IXMSIncreasedStakedOracle {
    // ----------- Events -----------

    // ----------- Governor only state changing api -----------

    function addIncreasedStakedAddress(address addr) external;

    function removeIncreasedStakedAddress(address addr) external;

    // ----------- Genesis Group only state changing api -----------

    // ----------- Getters -----------

    function getIncreasedStakedAddressesLength()
        external
        view
        returns (uint256);

    function increasedStakedAddresses(uint256 idx)
        external
        view
        returns (address);

    function increasedStakedAddressExisted(address addr)
        external
        view
        returns (bool);

    function getIncreasedStakedAmount()
        external
        view
        returns (uint256 xmsAmount);
}

interface IXMSCirculatingSupplyOracle {
    // ----------- Governor only state changing api -----------
    function setReducedFixedAmount(uint256 amount) external;

    function setIncreasedFixedAmount(uint256 amount) external;

    // ----------- Getters -----------
    function reducedFixedAmount() external view returns (uint256);

    function increasedFixedAmount() external view returns (uint256);

    function consult() external view returns (uint256);
}
