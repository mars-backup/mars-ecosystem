// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IUSDMGovernanceOracle.sol";
import "../refs/CoreRef.sol";

interface IFarmMaster {
    function userInfo(uint256 pid, address user)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);

    function pair2Pid(address pair) external view returns (uint256);

    function poolInfo(uint256 pid)
        external
        view
        returns (
            IERC20 lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accTokenPerShare
        );
}

abstract contract USDMGovernancePairOracle is IUSDMGovernancePairOracle {
    using SafeMath for uint256;

    IUSDMToken private _usdm;

    /// @notice Governance lp
    address[] public override approvedPairs;
    mapping(address => bool) public override approvedPairExisted;
    mapping(address => address[]) public override approvedContracts;
    mapping(address => mapping(address => bool))
        public
        override approvedContractExisted;

    constructor(address usdm_) {
        require(
            usdm_ != address(0),
            "USDMGovernancePairOracle::constructor: Zero address"
        );
        _usdm = IUSDMToken(usdm_);
    }

    function getApprovedPairsLength() public view override returns (uint256) {
        return approvedPairs.length;
    }

    function getApprovedContractsLength(address _pair)
        public
        view
        override
        returns (uint256)
    {
        return approvedContracts[_pair].length;
    }

    function addApprovedPairAndContract(address _pair, address _owner)
        public
        virtual
        override
    {
        require(
            !approvedContractExisted[_pair][_owner],
            "USDMGovernancePairOracle::addApprovedPairAndContract: Exist"
        );
        if (!approvedPairExisted[_pair]) {
            approvedPairs.push(_pair);
            approvedPairExisted[_pair] = true;
        }
        address[] storage contracts = approvedContracts[_pair];
        contracts.push(_owner);
        approvedContractExisted[_pair][_owner] = true;
    }

    function removeApprovedPairAndContract(address _pair, address _owner)
        public
        virtual
        override
    {
        require(
            approvedContractExisted[_pair][_owner],
            "USDMGovernancePairOracle::removeApprovedPairAndContract: Not exist"
        );
        address[] storage contracts = approvedContracts[_pair];
        uint256 idx_i;
        for (uint256 i; i < contracts.length; i++) {
            if (contracts[i] == _owner) {
                idx_i = i;
                break;
            }
        }
        contracts[idx_i] = contracts[contracts.length - 1];
        contracts.pop();
        if (contracts.length == 0) {
            uint256 idx_j;
            for (uint256 j; j < approvedPairs.length; j++) {
                if (approvedPairs[j] == _pair) {
                    idx_j = j;
                    break;
                }
            }
            approvedPairs[idx_j] = approvedPairs[approvedPairs.length - 1];
            approvedPairs.pop();
            delete approvedPairExisted[_pair];
        }
        delete approvedContractExisted[_pair][_owner];
    }

    /// @notice Calculate the usdm amount of governance
    function getGovernancePairUSDM()
        public
        view
        override
        returns (uint256 usdmAmount)
    {
        address pair;
        address owner;
        for (uint256 i; i < getApprovedPairsLength(); i++) {
            pair = approvedPairs[i];
            for (uint256 j; j < getApprovedContractsLength(pair); j++) {
                owner = approvedContracts[pair][j];
                usdmAmount = usdmAmount.add(
                    _usdm
                        .balanceOf(pair)
                        .mul(IERC20(pair).balanceOf(owner))
                        .div(IERC20(pair).totalSupply())
                );
            }
        }
    }
}

abstract contract USDMGovernanceFarmPairOracle is
    IUSDMGovernanceFarmPairOracle
{
    using SafeMath for uint256;
    IUSDMToken private _usdm;

    /// @notice Governance farming lp
    address[] public override approvedFarmPairs;
    mapping(address => bool) public override approvedFarmPairExisted;
    mapping(address => Pool[]) public override approvedFarmContracts;
    mapping(address => mapping(address => bool))
        public
        override approvedFarmContractExisted;

    constructor(address usdm_) {
        require(
            usdm_ != address(0),
            "USDMGovernanceFarmPairOracle::constructor: Zero address"
        );
        _usdm = IUSDMToken(usdm_);
    }

    function getApprovedFarmPairsLength()
        public
        view
        override
        returns (uint256)
    {
        return approvedFarmPairs.length;
    }

    function getApprovedFarmContractsLength(address _pair)
        public
        view
        override
        returns (uint256)
    {
        return approvedFarmContracts[_pair].length;
    }

    function addApprovedFarmPairAndContract(
        address _pair,
        address _staker,
        address _master
    ) public virtual override {
        require(
            !approvedFarmContractExisted[_pair][_staker],
            "USDMGovernanceFarmPairOracle::addApprovedFarmPairAndContract: Exist"
        );
        uint256 pid = IFarmMaster(_master).pair2Pid(_pair);
        (IERC20 lpToken, , , ) = IFarmMaster(_master).poolInfo(pid);
        require(
            _pair == address(lpToken),
            "USDMGovernanceFarmPairOracle::addApprovedFarmPairAndContract: Lp pool not exist"
        );
        if (!approvedFarmPairExisted[_pair]) {
            approvedFarmPairs.push(_pair);
            approvedFarmPairExisted[_pair] = true;
        }
        Pool[] storage pools = approvedFarmContracts[_pair];
        pools.push(Pool({staker: _staker, master: _master, pid: pid}));
        approvedFarmContractExisted[_pair][_staker] = true;
    }

    function removeApprovedFarmPairAndContract(address _pair, address _staker)
        public
        virtual
        override
    {
        require(
            approvedFarmContractExisted[_pair][_staker],
            "USDMGovernanceFarmPairOracle::removeApprovedFarmPairAndContract: Not exist"
        );
        Pool[] storage pools = approvedFarmContracts[_pair];
        uint256 idx_i;
        for (uint256 i; i < pools.length; i++) {
            if (pools[i].staker == _staker) {
                idx_i = i;
                break;
            }
        }
        pools[idx_i] = pools[pools.length - 1];
        pools.pop();
        if (pools.length == 0) {
            uint256 idx_j;
            for (uint256 j; j < approvedFarmPairs.length; j++) {
                if (approvedFarmPairs[j] == _pair) {
                    idx_j = j;
                    break;
                }
            }
            approvedFarmPairs[idx_j] = approvedFarmPairs[
                approvedFarmPairs.length - 1
            ];
            approvedFarmPairs.pop();
            delete approvedFarmPairExisted[_pair];
        }
        delete approvedFarmContractExisted[_pair][_staker];
    }

    /// @notice Calculate the usdm amount of governance
    function getGovernanceFarmPairUSDM()
        public
        view
        override
        returns (uint256 usdmAmount)
    {
        address pair;
        address master;
        for (uint256 i; i < approvedFarmPairs.length; i++) {
            pair = approvedFarmPairs[i];
            for (uint256 j; j < approvedFarmContracts[pair].length; j++) {
                master = approvedFarmContracts[pair][j].master;
                (uint256 stakeAmount, ) = IFarmMaster(master).userInfo(
                    approvedFarmContracts[pair][j].pid,
                    approvedFarmContracts[pair][j].staker
                );
                usdmAmount = usdmAmount.add(
                    _usdm.balanceOf(pair).mul(stakeAmount).div(
                        IERC20(pair).totalSupply()
                    )
                );
            }
        }
    }
}

contract USDMGovernanceOracle is
    IUSDMGovernanceOracle,
    CoreRef,
    USDMGovernancePairOracle,
    USDMGovernanceFarmPairOracle
{
    using SafeMath for uint256;

    constructor(address _core, address _usdm)
        CoreRef(_core)
        USDMGovernancePairOracle(_usdm)
        USDMGovernanceFarmPairOracle(_usdm)
    {}

    function addApprovedPairAndContract(address _pair, address _owner)
        public
        override(USDMGovernancePairOracle)
        onlyGovernor
    {
        USDMGovernancePairOracle.addApprovedPairAndContract(_pair, _owner);
    }

    function removeApprovedPairAndContract(address _pair, address _owner)
        public
        override(USDMGovernancePairOracle)
        onlyGovernor
    {
        USDMGovernancePairOracle.removeApprovedPairAndContract(_pair, _owner);
    }

    function addApprovedFarmPairAndContract(
        address _pair,
        address _staker,
        address _master
    ) public override(USDMGovernanceFarmPairOracle) onlyGovernor {
        USDMGovernanceFarmPairOracle.addApprovedFarmPairAndContract(
            _pair,
            _staker,
            _master
        );
    }

    function removeApprovedFarmPairAndContract(address _pair, address _staker)
        public
        override(USDMGovernanceFarmPairOracle)
        onlyGovernor
    {
        USDMGovernanceFarmPairOracle.removeApprovedFarmPairAndContract(
            _pair,
            _staker
        );
    }

    function consult() public view override returns (uint256) {
        return getGovernancePairUSDM().add(getGovernanceFarmPairUSDM());
    }
}
