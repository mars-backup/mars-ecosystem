// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/Initializable.sol";
import "../interfaces/IMarsSwapPairOracle.sol";
import "../interfaces/IChainlinkLastPriceOracle.sol";
import "../interfaces/ICombinationOracle.sol";
import "../libs/FixedPoint.sol";

import "../libs/MarsSwapOracleLibrary.sol";
import "../libs/MarsSwapLibrary.sol";
import "../refs/CoreRef.sol";

interface ERC20Interface {
    function decimals() external view returns (uint8);
}

// Combination Oracle
abstract contract CombinationOracle is
    ICombinationOracle,
    IMarsSwapPairOracle,
    CoreRef,
    Initializable
{
    using Decimal for Decimal.D256;
    using SafeMath for uint256;

    // Mapping from pair address to a list of price observations of that pair
    mapping(address => Observation) public pairObservations;

    // The route path to get XMS price
    // genesis: XMS -> USDM -> BUSD
    // launched: XMS -> USDM -> BNB
    Router private _router;

    constructor(address _core) CoreRef(_core) {}

    function initialize(address _oracle, address[] memory _path)
        external
        initializer
        onlyGuardianOrGovernor
    {
        setRouter(_oracle, _path);
    }

    function isStale(uint32 blockTimestamp) public view returns (bool) {
        address[] memory path = _router.path;
        uint256 pathLength = path.length;
        for (uint256 i; i < pathLength - 1; i++) {
            if (!_isStale(blockTimestamp, path[i], path[i + 1])) {
                return false;
            }
        }
        return true;
    }

    // Check if update() can be called instead of wasting gas calling it
    function canUpdate() public view returns (bool) {
        uint32 blockTimestamp = MarsSwapOracleLibrary.currentBlockTimestamp();
        address[] memory path = _router.path;
        uint256 pathLength = path.length;
        for (uint256 i; i < pathLength - 1; i++) {
            if (!_canUpdate(blockTimestamp, path[i], path[i + 1])) {
                return false;
            }
        }
        return true;
    }

    function update() external override {
        address[] memory path = _router.path;
        uint256 pathLength = path.length;
        for (uint256 i; i < pathLength - 1; i++) {
            _update(path[i], path[i + 1]);
        }
    }

    // Note this will always return 0 before update has been called successfully for the first time.
    function consult(uint256 _amountIn)
        public
        view
        override
        returns (Decimal.D256 memory _amountOut)
    {
        uint32 blockTimestamp = MarsSwapOracleLibrary.currentBlockTimestamp();
        uint256 amountOut = _amountIn;
        address[] memory path = _router.path;
        uint256 pathLength = path.length;
        for (uint256 i; i < pathLength - 1; i++) {
            amountOut = _consult(
                blockTimestamp,
                path[i],
                amountOut,
                path[i + 1]
            );
        }

        (uint256 chainlinkPrice, uint8 decimals) = _router
            .oracle
            .getLatestPrice();
        amountOut = amountOut.mul(chainlinkPrice).div(10**decimals);
        _amountOut = Decimal.ratio(
            amountOut,
            10**ERC20Interface(path[pathLength - 1]).decimals()
        );
    }

    function setRouter(address _oracle, address[] memory _path)
        public
        override
        onlyGovernor
    {
        uint256 pathLength = _path.length;
        require(
            pathLength > 1,
            "CombinationOracle::setRouter: Path length zero"
        );
        require(
            _oracle != address(0),
            "CombinationOracle::setRouter: Zero address"
        );
        IChainlinkLastPriceOracle oracle = IChainlinkLastPriceOracle(_oracle);
        require(
            _path[pathLength - 1] == oracle.token(),
            "CombinationOracle::setRouter: Last token not match oracle"
        );
        for (uint256 i; i < pathLength - 1; i++) {
            require(
                ERC20Interface(_path[i]).decimals() > 0 &&
                    ERC20Interface(_path[i + 1]).decimals() > 0,
                "CombinationOracle::setRouter: Path token not IER20"
            );
            _initialize(_path[i], _path[i + 1]);
        }
        _router.path = _path;
        _router.oracle = oracle;
    }

    function getRouter() public view override returns (Router memory) {
        return _router;
    }

    function _initialize(address _token0, address _token1) internal virtual;

    function _canUpdate(
        uint32 blockTimestamp,
        address _token0,
        address _token1
    ) internal view virtual returns (bool);

    function _isStale(
        uint32 blockTimestamp,
        address _token0,
        address _token1
    ) internal view virtual returns (bool);

    function _update(address _token0, address _token1) internal virtual;

    function _consult(
        uint32 _blockTimestamp,
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut
    ) internal view virtual returns (uint256 amountOut);
}
