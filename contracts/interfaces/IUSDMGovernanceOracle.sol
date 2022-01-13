// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

/// @author USDM Protocol
interface IUSDMGovernancePairOracle {
    // ----------- Events -----------

    // ----------- Governor only state changing api -----------

    function addApprovedPairAndContract(address pair, address owner) external;

    function removeApprovedPairAndContract(address pair, address owner)
        external;

    // ----------- Genesis Group only state changing api -----------

    // ----------- Getters -----------

    function getApprovedPairsLength() external view returns (uint256);

    function getApprovedContractsLength(address pair)
        external
        view
        returns (uint256);

    function approvedPairs(uint256 idx) external view returns (address);

    function approvedPairExisted(address pair) external view returns (bool);

    function approvedContracts(address pair, uint256 idx)
        external
        view
        returns (address);

    function approvedContractExisted(address pair, address owner)
        external
        view
        returns (bool);

    function getGovernancePairUSDM() external view returns (uint256 usdmAmount);
}

interface IUSDMGovernanceFarmPairOracle {
    struct Pool {
        address staker;
        address master;
        uint256 pid;
    }

    // ----------- Events -----------

    // ----------- Governor only state changing api -----------

    function addApprovedFarmPairAndContract(
        address pair,
        address staker,
        address master
    ) external;

    function removeApprovedFarmPairAndContract(address pair, address contract_)
        external;

    // ----------- Genesis Group only state changing api -----------

    // ----------- Getters -----------

    function getApprovedFarmPairsLength() external view returns (uint256);

    function getApprovedFarmContractsLength(address pair)
        external
        view
        returns (uint256);

    function approvedFarmPairs(uint256 idx) external view returns (address);

    function approvedFarmPairExisted(address pair) external view returns (bool);

    function approvedFarmContracts(address pair, uint256 idx)
        external
        view
        returns (
            address staker,
            address master,
            uint256 pid
        );

    function approvedFarmContractExisted(address pair, address contract_)
        external
        view
        returns (bool);

    function getGovernanceFarmPairUSDM()
        external
        view
        returns (uint256 usdmAmount);
}

interface IUSDMGovernanceOracle {
    function consult() external view returns (uint256);
}
