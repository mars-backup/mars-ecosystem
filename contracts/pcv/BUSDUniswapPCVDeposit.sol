// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./PCVUniswapDeposit.sol";
import "../interfaces/IChainlinkLastPriceOracle.sol";
import "../interfaces/IPCVController.sol";

/// @title Implementation for an BUSD Uniswap LP PCV Deposit
/// @author USDM Protocol
contract BUSDUniswapPCVDeposit is PCVUniswapDeposit {
    using Decimal for Decimal.D256;
    using SafeMath for uint256;
    using SafeERC20 for IMarsSwapPair;

    IERC20 public busd;
    IChainlinkLastPriceOracle chainlink;
    address public devAddress;

    /// @notice BUSD Uniswap PCV Deposit constructor
    /// @param _core USDM Core for reference
    /// @param _devAddress Project address
    /// @param _chainlink Chainlink
    /// @param _pair Uniswap Pair to deposit to
    /// @param _router Uniswap Router
    /// @param _factory Uniswap Factory
    /// @param _busd BUSD address
    /// @param _lpMiningMaster Liquidity mining master
    /// @param _vestingMaster Vesting master
    /// @param _rewardToken Mining reward token
    constructor(
        address _core,
        address _devAddress,
        address _chainlink,
        address _pair,
        address _router,
        address _factory,
        address _busd,
        address _lpMiningMaster,
        address _vestingMaster,
        address _rewardToken
    )
        PCVUniswapDeposit(
            _core,
            _pair,
            _router,
            _factory,
            _lpMiningMaster,
            _vestingMaster,
            _rewardToken
        )
    {
        require(
            _busd != address(0),
            "BUSDUniswapPCVDeposit::constructor: Zero address"
        );
        require(
            (_busd == pair.token0() || _busd == pair.token1()) &&
                (address(usdm()) == pair.token0() ||
                    address(usdm()) == pair.token1()),
            "BUSDUniswapPCVDeposit::constructor: Bad pair"
        );
        busd = IERC20(_busd);
        require(
            _chainlink != address(0),
            "BUSDUniswapPCVDeposit::constructor: Zero address"
        );
        chainlink = IChainlinkLastPriceOracle(_chainlink);
        require(
            _devAddress != address(0),
            "BUSDUniswapPCVDeposit::constructor: Zero address"
        );
        devAddress = _devAddress;
    }

    /// @notice Deposit tokens into the PCV allocation
    /// @param busdAmount Amount of tokens deposited
    function deposit(uint256 busdAmount)
        external
        payable
        override
        whenNotPaused
    {
        require(msg.value == 0, "BUSDUniswapPCVDeposit::deposit: No need BNB");
        require(
            core().hasGenesisGroupCompleted() ||
                core().isPCVController(msg.sender) ||
                _isGenesisGroupLaunching(),
            "BUSDUniswapPCVDeposit::deposit: Still in genesis period or not allowed"
        );
        (uint256 reserveUSDM, uint256 reserveBUSD) = getReserves();
        require(
            !_isGenesisGroupLaunching() || (reserveUSDM == 0),
            "BUSDUniswapPCVDeposit::deposit: Not first launch"
        );
        require(
            _isGenesisGroupLaunching() ||
                _isValidPriceRange(maxBPForAddLiquidity),
            "BUSDUniswapPCVDeposit::deposit: Price out"
        );
        require(
            busd.transferFrom(msg.sender, address(this), busdAmount),
            "BUSDUniswapPCVDeposit::deposit: TransferFrom failed"
        );
        busdAmount = totalValue(); // Include any BUSD dust from prior LP

        if (reserveUSDM == 0 && reserveBUSD > 0) {
            usdm().mint(
                address(pair),
                getCurrentPrice().mul(reserveBUSD).asUint256()
            );
            pair.sync();
        }
        _addLiquidity(busdAmount);

        _burnUSDMHeld(); // Burn any USDM dust from LP

        emit Deposit(msg.sender, busdAmount);
    }

    /// @notice returns total value of PCV in the Deposit
    function totalValue() public view override returns (uint256) {
        return busd.balanceOf(address(this));
    }

    /// @notice Return current price
    /// @return Price reported as USD per BUSD with BUSD being the underlying asset
    function getCurrentPrice()
        public
        view
        override
        returns (Decimal.D256 memory)
    {
        (uint256 chainlinkPrice, uint8 decimals) = chainlink.getLatestPrice();
        return Decimal.ratio(chainlinkPrice, 10**decimals);
    }

    // Return usdm amount to deposit
    // Price reported as USDM per BUSD with BUSD being the underlying asset
    function _getAmountUSDMToDeposit(uint256 amountBUSD)
        internal
        view
        returns (uint256 amountUSDM)
    {
        (uint256 reserveUSDM, ) = getReserves();
        if (reserveUSDM == 0) {
            uint256 busdBalance = busd.balanceOf(address(pair));
            amountBUSD = amountBUSD.add(busdBalance);
            amountUSDM = getCurrentPrice().mul(amountBUSD).asUint256();
        } else {
            (Decimal.D256 memory uniPrice, , ) = _getUniswapPrice();
            amountUSDM = uniPrice.mul(amountBUSD).asUint256();
        }
    }

    function _isValidPriceRange(uint256 _maxBP)
        internal
        view
        override
        returns (bool)
    {
        (uint256 reserveUSDM, uint256 reserveBUSD) = getReserves();
        Decimal.D256 memory usdmPrice = Decimal.ratio(reserveBUSD, reserveUSDM);
        Decimal.D256 memory usdPrice = invert(getCurrentPrice());
        (Decimal.D256 memory price0, Decimal.D256 memory price1) = usdmPrice
            .greaterThan(usdPrice)
            ? (usdPrice, usdmPrice)
            : (usdmPrice, usdPrice);
        return
            price1.sub(price0).div(usdPrice).lessThan(
                Decimal.ratio(
                    _maxBP.mul(fluctuationRange),
                    fluctuationRangePrecision
                )
            );
    }

    function _addLiquidity(uint256 busdAmount) internal override {
        uint256 usdmAmount = _getAmountUSDMToDeposit(busdAmount);
        _mintUSDM(usdmAmount);

        uint256 endOfTime = uint256(-1);
        router.addLiquidity(
            address(usdm()),
            address(busd),
            usdmAmount,
            busdAmount,
            0,
            0,
            address(this),
            endOfTime
        );
    }

    function _removeLiquidity(uint256 liquidity) internal override {
        uint256 endOfTime = uint256(-1);
        router.removeLiquidity(
            address(usdm()),
            address(busd),
            liquidity,
            0,
            0,
            address(this),
            endOfTime
        );
        _burnUSDMHeld();
        _transferWithdrawn(msg.sender, busd.balanceOf(address(this)));
    }

    function _harvest() internal override {
        uint256 pid = _getLpMiningPid(address(pair));
        lpMiningMaster.deposit(pid, 0);
        require(
            rewardToken.transfer(
                devAddress,
                rewardToken.balanceOf(address(this))
            ),
            "BUSDUniswapPCVDeposit::_harvest: Transfer failed"
        );
    }

    function _claim() internal override {
        vestingMaster.claim();
        IERC20 vestingToken = vestingMaster.vestingToken();
        require(
            vestingToken.transfer(
                devAddress,
                vestingToken.balanceOf(address(this))
            ),
            "BUSDUniswapPCVDeposit::_claim: Transfer failed"
        );
    }

    function _depositLpMining(uint256 _liquidity) internal virtual override {
        require(
            pair.balanceOf(address(this)) >= _liquidity,
            "BUSDUniswapPCVDeposit::_depositLpMining: Not enough token"
        );
        uint256 pid = _getLpMiningPid(address(pair));
        pair.safeIncreaseAllowance(address(lpMiningMaster), _liquidity);
        lpMiningMaster.deposit(pid, _liquidity);
        require(
            rewardToken.transfer(
                devAddress,
                rewardToken.balanceOf(address(this))
            ),
            "BUSDUniswapPCVDeposit::_depositLpMining: Transfer failed"
        );
    }

    function _withdrawLpMining(uint256 _liquidity) internal virtual override {
        uint256 pid = _getLpMiningPid(address(pair));
        (uint256 amount, ) = lpMiningMaster.userInfo(pid, address(this));
        require(
            amount >= _liquidity,
            "BUSDUniswapPCVDeposit::_withdrawLpMining: More than"
        );
        lpMiningMaster.withdraw(pid, _liquidity);
        require(
            rewardToken.transfer(
                devAddress,
                rewardToken.balanceOf(address(this))
            ),
            "BUSDUniswapPCVDeposit::_withdrawLpMining: Transfer failed"
        );
    }

    function _transferWithdrawn(address to, uint256 amount) internal override {
        require(
            busd.transfer(to, amount),
            "BUSDUniswapPCVDeposit::_transferWithdrawn: Transfer failed"
        );
    }

    function _getLpMiningPid(address _pair)
        internal
        view
        override
        returns (uint256)
    {
        uint256 pid = lpMiningMaster.pair2Pid(_pair);
        (IERC20 lpToken, , , ) = lpMiningMaster.poolInfo(pid);
        require(
            _pair == address(lpToken),
            "BUSDUniswapPCVDeposit::_getLpMiningPid: Lp pool not exist"
        );
        return pid;
    }

    function _isGenesisGroupLaunching() internal view returns (bool) {
        return
            IGenesisGroup(core().genesisGroup()).launchBlock() ==
            block.number &&
            (core().isGovernor(tx.origin) || core().isGuardian(tx.origin));
    }

    function setChainlink(address _chainlink) external onlyGovernor {
        require(
            _chainlink != address(0),
            "BUSDUniswapPCVDeposit::setChainlink: Zero address"
        );
        chainlink = IChainlinkLastPriceOracle(_chainlink);
    }

    function setDevAddress(address _devAddress) external onlyGovernor {
        require(
            _devAddress != address(0),
            "BUSDUniswapPCVDeposit::setDevAddress: Zero address"
        );
        devAddress = _devAddress;
    }
}
