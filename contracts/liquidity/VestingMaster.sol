// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/IVestingMaster.sol";
import "../interfaces/ICore.sol";

interface IAccessControl {
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);
}

interface ICoreCopy is ICore, IAccessControl {}

abstract contract CoreRefCopy {
    event CoreUpdate(address indexed core);
    bytes32 public constant FARMS_ROLE = keccak256("FARMS_ROLE");

    ICoreCopy private _core;

    /// @notice CoreRef constructor
    /// @param core_ USDM Core to reference
    constructor(address core_) {
        _core = ICoreCopy(core_);
    }

    modifier onlyGovernor() {
        require(
            _core.isGovernor(msg.sender),
            "CoreRef::onlyGovernor: Caller is not a governor"
        );
        _;
    }

    modifier onlyFarms() {
        require(
            _core.hasRole(FARMS_ROLE, msg.sender),
            "CoreRef::onlyFarms: Caller is not a farms"
        );
        _;
    }

    /// @notice Set new Core reference address
    /// @param core_ The new core address
    function setCore(address core_) external onlyGovernor {
        _core = ICoreCopy(core_);
        emit CoreUpdate(core_);
    }

    /// @notice Address of the Core contract referenced
    /// @return ICore implementation address
    function core() public view returns (ICore) {
        return _core;
    }
}

// VestingMaster,
contract VestingMaster is IVestingMaster, ReentrancyGuard, CoreRefCopy {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // XMS token, or may be other token
    IERC20 public override vestingToken;

    mapping(address => LockedReward[]) public override userLockedRewards;

    uint256 public immutable override period;

    uint256 public immutable override lockedPeriodAmount;

    uint256 public override totalLockedRewards;

    constructor(
        address _core,
        uint256 _period,
        uint256 _lockedPeriodAmount,
        address _vestingToken
    ) CoreRefCopy(_core) {
        require(
            _vestingToken != address(0),
            "VestingMaster::constructor: Zero address"
        );
        require(_period > 0, "VestingMaster::constructor: Period zero");
        require(
            _lockedPeriodAmount > 0,
            "VestingMaster::constructor: Period amount zero"
        );
        vestingToken = IERC20(_vestingToken);
        period = _period;
        lockedPeriodAmount = _lockedPeriodAmount;
    }

    function lock(address account, uint256 amount) public override onlyFarms {
        LockedReward[] memory oldLockedRewards = userLockedRewards[account];
        uint256 currentTimestamp = block.timestamp;
        LockedReward memory lockedReward;
        uint256 claimableAmount;
        for (uint256 i = 0; i < oldLockedRewards.length; i++) {
            lockedReward = oldLockedRewards[i];
            if (currentTimestamp >= lockedReward.timestamp) {
                claimableAmount = claimableAmount.add(lockedReward.locked);
                delete oldLockedRewards[i];
            } else {
                break;
            }
        }

        uint256 newStartTimestamp = (currentTimestamp / period) * period;
        uint256 newTimestamp;
        LockedReward memory newLockedReward;
        uint256 jj = 0;
        delete userLockedRewards[account];
        if (claimableAmount > 0) {
            userLockedRewards[account].push(
                LockedReward({
                    locked: claimableAmount,
                    timestamp: newStartTimestamp
                })
            );
        }
        for (uint256 i = 0; i < lockedPeriodAmount; i++) {
            newTimestamp = newStartTimestamp.add((i + 1) * period);
            uint256 locked;
            if (amount.div(lockedPeriodAmount) == 0) {
                locked = i == 0 ? amount : 0;
            } else if (amount.mod(lockedPeriodAmount) > 0) {
                locked = i == 0
                    ? amount.div(lockedPeriodAmount).add(
                        amount.mod(lockedPeriodAmount)
                    )
                    : amount.div(lockedPeriodAmount);
            } else {
                locked = amount.div(lockedPeriodAmount);
            }
            newLockedReward = LockedReward({
                locked: locked,
                timestamp: newTimestamp
            });
            for (uint256 j = jj; j < oldLockedRewards.length; j++) {
                lockedReward = oldLockedRewards[j];
                if (lockedReward.timestamp == newTimestamp) {
                    newLockedReward.locked = newLockedReward.locked.add(
                        lockedReward.locked
                    );
                    jj = j + 1;
                    break;
                }
            }
            if (newLockedReward.locked > 0) {
                userLockedRewards[account].push(newLockedReward);
            }
        }
        totalLockedRewards = totalLockedRewards.add(amount);
        emit Lock(account, amount);
    }

    function claim() public override {
        LockedReward[] storage lockedRewards = userLockedRewards[msg.sender];
        uint256 currentTimestamp = block.timestamp;
        LockedReward memory lockedReward;
        uint256 claimableAmount;
        for (uint256 i = 0; i < lockedRewards.length; i++) {
            lockedReward = lockedRewards[i];
            if (currentTimestamp >= lockedReward.timestamp) {
                claimableAmount = claimableAmount.add(lockedReward.locked);
                delete lockedRewards[i];
            } else {
                break;
            }
        }
        totalLockedRewards = totalLockedRewards.sub(claimableAmount);
        _safeTransfer(msg.sender, claimableAmount);
        emit Claim(msg.sender, claimableAmount);
    }

    function getVestingAmount()
        public
        view
        override
        returns (uint256 lockedAmount, uint256 claimableAmount)
    {
        LockedReward[] memory lockedRewards = userLockedRewards[msg.sender];
        uint256 currentTimestamp = block.timestamp;
        LockedReward memory lockedReward;
        for (uint256 i = 0; i < lockedRewards.length; i++) {
            lockedReward = lockedRewards[i];
            if (currentTimestamp >= lockedReward.timestamp) {
                claimableAmount = claimableAmount.add(lockedReward.locked);
            } else {
                lockedAmount = lockedAmount.add(lockedReward.locked);
            }
        }
    }

    function _safeTransfer(address _to, uint256 _amount) internal virtual {
        vestingToken.safeTransfer(_to, _amount);
    }
}
