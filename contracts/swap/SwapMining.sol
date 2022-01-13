// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "../libs/MarsSwapLibrary.sol";
import "../interfaces/ISwapMining.sol";
import "../interfaces/ISwapMiningOracle.sol";
import "../interfaces/IVestingMaster.sol";
import "../refs/CoreRef.sol";

contract SwapMining is ISwapMining, CoreRef {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _whitelists;

    // Factory address
    IMarsSwapFactory public override factory;
    ISwapMiningOracle public override swapMiningOracle;

    IVestingMaster public vestingMaster;

    // XMS token, or may be other token
    IERC20 public override rewardToken;

    PoolInfo[] public override poolInfo;

    // The tokens created per block
    uint256 public override tokenPerBlock;
    // The block number when mining starts.
    uint256 public override startBlock;
    // The block number when mining ends.
    uint256 public override endBlock;
    // Total allocation points
    uint256 public override totalAllocPoint = 0;

    // Router address
    address public override router;
    address public override targetToken;

    // Pair corresponding pid
    mapping(address => uint256) public override pair2Pid;
    mapping(address => bool) public override poolExistence;
    mapping(uint256 => mapping(address => UserInfo)) public override userInfo;

    constructor(
        address _core,
        address _vestingMaster,
        address _rewardToken,
        IMarsSwapFactory _factory,
        ISwapMiningOracle _swapMiningOracle,
        address _router,
        address _targetToken,
        uint256 _tokenPerBlock,
        uint256 _startBlock,
        uint256 _endBlock
    ) CoreRef(_core) {
        require(
            _rewardToken != address(0),
            "SwapMining::constructor: Zero address"
        );
        require(
            _startBlock < _endBlock,
            "SwapMining::constructor: End less than start"
        );
        vestingMaster = IVestingMaster(_vestingMaster);
        rewardToken = IERC20(_rewardToken);
        factory = _factory;
        swapMiningOracle = _swapMiningOracle;
        router = _router;
        targetToken = _targetToken;
        tokenPerBlock = _tokenPerBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;
    }

    modifier nonDuplicated(address _lpToken) {
        require(
            !poolExistence[_lpToken],
            "SwapMining::nonDuplicated: Duplicated"
        );
        _;
    }

    function poolLength() public view override returns (uint256) {
        return poolInfo.length;
    }

    function addPool(
        uint256 _allocPoint,
        address _pair,
        bool _withUpdate
    ) public override onlyGuardianOrGovernor nonDuplicated(_pair) {
        require(
            block.number < endBlock,
            "SwapMining::addPool: Exceed endblock"
        );
        require(_pair != address(0), "SwapMining::addPool: Zero address");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_pair] = true;
        poolInfo.push(
            PoolInfo({
                pair: _pair,
                quantity: 0,
                totalQuantity: 0,
                allocPoint: _allocPoint,
                allocTokenAmount: 0,
                lastRewardBlock: lastRewardBlock
            })
        );
        pair2Pid[_pair] = poolLength() - 1;
    }

    // Update the allocPoint of the pool
    function setPool(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public override onlyGuardianOrGovernor {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Only tokens in the whitelists can be mined reward token
    function addWhitelist(address _addToken)
        public
        override
        onlyGuardianOrGovernor
        returns (bool)
    {
        require(
            _addToken != address(0),
            "SwapMining::addWhitelist: Zero address"
        );
        return EnumerableSet.add(_whitelists, _addToken);
    }

    function delWhitelist(address _delToken)
        public
        override
        onlyGuardianOrGovernor
        returns (bool)
    {
        require(
            _delToken != address(0),
            "SwapMining::delWhitelist: Zero address"
        );
        return EnumerableSet.remove(_whitelists, _delToken);
    }

    function getWhitelistsLength() public view override returns (uint256) {
        return EnumerableSet.length(_whitelists);
    }

    function isWhitelist(address _token) public view override returns (bool) {
        return EnumerableSet.contains(_whitelists, _token);
    }

    function getWhitelist(uint256 _index)
        public
        view
        override
        returns (address)
    {
        require(
            _index <= getWhitelistsLength() - 1,
            "SwapMining::getWhitelist: Index out of bounds"
        );
        return EnumerableSet.at(_whitelists, _index);
    }

    function setRouter(address _router) public override onlyGovernor {
        require(_router != address(0), "SwapMining::setRouter: Zero address");
        router = _router;
    }

    function setSwapMiningOracle(ISwapMiningOracle _swapMiningOracle)
        public
        override
        onlyGovernor
    {
        require(
            address(_swapMiningOracle) != address(0),
            "SwapMining::setSwapMiningOracle: Zero address"
        );
        swapMiningOracle = _swapMiningOracle;
    }

    // Rewards for the current block
    function getTokenBlockReward(uint256 _lastRewardBlock)
        public
        view
        override
        returns (uint256)
    {
        require(
            _lastRewardBlock <= block.number,
            "SwapMining::getTokenBlockReward: Must little than the current block number"
        );
        return
            tokenPerBlock.mul(
                (block.number >= endBlock ? endBlock : block.number).sub(
                    _lastRewardBlock
                )
            );
    }

    // Update all pools Called when updating allocPoint and setting new blocks
    function massUpdatePools() public override {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public override {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (pool.lastRewardBlock >= endBlock) {
            return;
        }
        uint256 lastRewardBlock = block.number >= endBlock
            ? endBlock
            : block.number;
        uint256 lpSupply = IERC20(pool.pair).balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = lastRewardBlock;
            return;
        }
        uint256 blockReward = getTokenBlockReward(pool.lastRewardBlock);
        if (blockReward <= 0) {
            return;
        }
        // Calculate the rewards obtained by the pool based on the allocPoint
        uint256 tokenReward;
        if (totalAllocPoint > 0) {
            tokenReward = blockReward.mul(pool.allocPoint).div(totalAllocPoint);
        }
        // Increase the number of tokens in the current pool
        pool.allocTokenAmount = pool.allocTokenAmount.add(tokenReward);
        pool.lastRewardBlock = lastRewardBlock;
    }

    // Swap mining only router
    function swap(
        address _account,
        address _input,
        address _output,
        uint256 _amount
    ) public override onlyRouter returns (bool) {
        require(_account != address(0), "SwapMining::swap: Zero address");
        require(_input != address(0), "SwapMining::swap: Zero address");
        require(_output != address(0), "SwapMining::swap: Zero address");

        if (poolLength() <= 0) {
            return false;
        }

        if (!isWhitelist(_input) || !isWhitelist(_output)) {
            return false;
        }

        address pair = MarsSwapLibrary.pairFor(
            address(factory),
            _input,
            _output
        );

        PoolInfo storage pool = poolInfo[pair2Pid[pair]];
        // If it does not exist or the allocPoint is 0 then return
        if (pool.pair != pair || pool.allocPoint <= 0) {
            return false;
        }

        uint256 quantity = getQuantity(_output, _amount, targetToken);
        if (quantity <= 0) {
            return false;
        }

        updatePool(pair2Pid[pair]);

        pool.quantity = pool.quantity.add(quantity);
        pool.totalQuantity = pool.totalQuantity.add(quantity);
        UserInfo storage user = userInfo[pair2Pid[pair]][_account];
        user.quantity = user.quantity.add(quantity);
        user.blockNumber = block.number;
        return true;
    }

    // The user withdraws all the transaction rewards of the pool
    function withdraw() public override {
        uint256 userSub;
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            UserInfo storage user = userInfo[pid][msg.sender];
            if (user.quantity > 0) {
                updatePool(pid);
                // The reward held by the user in this pool
                uint256 userReward = pool
                    .allocTokenAmount
                    .mul(user.quantity)
                    .div(pool.quantity);
                pool.quantity = pool.quantity.sub(user.quantity);
                pool.allocTokenAmount = pool.allocTokenAmount.sub(userReward);
                user.quantity = 0;
                user.blockNumber = block.number;
                userSub = userSub.add(userReward);
            }
        }
        if (userSub <= 0) {
            return;
        }
        uint256 locked;
        if (address(vestingMaster) != address(0)) {
            locked = userSub.div(vestingMaster.lockedPeriodAmount() + 1).mul(
                vestingMaster.lockedPeriodAmount()
            );
        }
        _safeTokenTransfer(msg.sender, userSub.sub(locked));
        if (locked > 0) {
            uint256 actualAmount = _safeTokenTransfer(
                address(vestingMaster),
                locked
            );
            vestingMaster.lock(msg.sender, actualAmount);
        }
        emit Withdraw(msg.sender, userSub);
    }

    // Get rewards from users in the current pool
    function pendingToken(uint256 _pid, address _user)
        public
        view
        override
        returns (uint256, uint256)
    {
        require(
            _pid <= poolInfo.length - 1,
            "SwapMining::pendingToken: No pool"
        );
        uint256 userSub;
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        if (user.quantity > 0) {
            uint256 blockReward = getTokenBlockReward(pool.lastRewardBlock);
            uint256 tokenReward = blockReward.mul(pool.allocPoint).div(
                totalAllocPoint
            );
            userSub = userSub.add(
                (pool.allocTokenAmount.add(tokenReward)).mul(user.quantity).div(
                    pool.quantity
                )
            );
        }
        // Reward available to users, User transaction amount
        return (userSub, user.quantity);
    }

    // Get details of the pool
    function getPoolInfo(uint256 _pid)
        public
        view
        override
        returns (
            address,
            address,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        require(
            _pid <= poolInfo.length - 1,
            "SwapMining::getPoolInfo: No pool"
        );
        PoolInfo memory pool = poolInfo[_pid];
        address token0 = IMarsSwapPair(pool.pair).token0();
        address token1 = IMarsSwapPair(pool.pair).token1();
        uint256 tokenAmount = pool.allocTokenAmount;
        uint256 blockReward = getTokenBlockReward(pool.lastRewardBlock);
        uint256 tokenReward = blockReward.mul(pool.allocPoint).div(
            totalAllocPoint
        );
        tokenAmount = tokenAmount.add(tokenReward);
        // Current transaction volume of the pool
        return (
            token0,
            token1,
            tokenAmount,
            pool.totalQuantity,
            pool.quantity,
            pool.allocPoint
        );
    }

    modifier onlyRouter() {
        require(
            msg.sender == router,
            "SwapMining::onlyRouter: Caller is not the router"
        );
        _;
    }

    function getQuantity(
        address outputToken,
        uint256 outputAmount,
        address anchorToken
    ) public view override returns (uint256) {
        uint256 quantity = 0;
        if (outputToken == anchorToken) {
            quantity = outputAmount;
        } else if (factory.getPair(outputToken, anchorToken) != address(0)) {
            quantity = swapMiningOracle.consult(
                outputToken,
                outputAmount,
                anchorToken
            );
        } else {
            uint256 length = getWhitelistsLength();
            for (uint256 index = 0; index < length; index++) {
                address intermediate = getWhitelist(index);
                if (
                    factory.getPair(outputToken, intermediate) != address(0) &&
                    factory.getPair(intermediate, anchorToken) != address(0)
                ) {
                    uint256 interQuantity = swapMiningOracle.consult(
                        outputToken,
                        outputAmount,
                        intermediate
                    );
                    quantity = swapMiningOracle.consult(
                        intermediate,
                        interQuantity,
                        anchorToken
                    );
                    break;
                }
            }
        }
        return quantity;
    }

    // Safe token transfer function, just in case if rounding error causes pool to not have enough token.
    function _safeTokenTransfer(address _to, uint256 _amount)
        internal
        returns (uint256)
    {
        uint256 balance = rewardToken.balanceOf(address(this));
        uint256 amount;
        if (_amount > balance) {
            amount = balance;
        } else {
            amount = _amount;
        }
        require(
            rewardToken.transfer(_to, amount),
            "SwapMining::_safeTokenTransfer: Transfer failed"
        );
        return amount;
    }

    function updateTokenPerBlock(uint256 _tokenPerBlock)
        public
        override
        onlyGuardianOrGovernor
    {
        massUpdatePools();
        tokenPerBlock = _tokenPerBlock;
        emit UpdateTokenPerBlock(msg.sender, _tokenPerBlock);
    }

    function updateEndBlock(uint256 _endBlock)
        public
        override
        onlyGuardianOrGovernor
    {
        require(
            _endBlock > startBlock && _endBlock >= block.number,
            "SwapMining::updateEndBlock: Less"
        );
        for (uint256 pid = 0; pid < poolInfo.length; ++pid) {
            require(
                _endBlock > poolInfo[pid].lastRewardBlock,
                "SwapMining::updateEndBlock: Less"
            );
        }
        massUpdatePools();
        endBlock = _endBlock;
        emit UpdateEndBlock(msg.sender, _endBlock);
    }

    function updateVestingMaster(address _vestingMaster)
        public
        override
        onlyGovernor
    {
        vestingMaster = IVestingMaster(_vestingMaster);
        emit UpdateVestingMaster(msg.sender, _vestingMaster);
    }
}
