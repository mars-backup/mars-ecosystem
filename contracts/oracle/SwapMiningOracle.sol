// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/ISwapMiningOracle.sol";
import "../libs/FixedPoint.sol";

import "../libs/MarsSwapOracleLibrary.sol";
import "../libs/MarsSwapLibrary.sol";
import "../refs/CoreRef.sol";

contract SwapMiningOracle is ISwapMiningOracle, CoreRef {
    using FixedPoint for *;

    uint256 public override PERIOD = 900; // 15 minutes TWAP (time-weighted average price)

    IMarsSwapFactory public override factory;

    // Mapping from pair address to a list of price observations of that pair
    mapping(address => Observation) public pairObservations;
    address[] public override pairs;

    constructor(address _core, address _factory) CoreRef(_core) {
        factory = IMarsSwapFactory(_factory);
    }

    function getPairsLength() external view override returns (uint256) {
        return pairs.length;
    }

    function setFactory(address _factory) external override onlyGovernor {
        require(
            _factory != address(0),
            "SwapMiningOracle::setFactory: Zero address"
        );
        factory = IMarsSwapFactory(_factory);
    }

    function setPeriod(uint256 _period) external override onlyGovernor {
        PERIOD = _period;
    }

    function addPair(address _pair) external override onlyGovernor {
        require(
            !pairObservations[_pair].added,
            "SwapMiningOracle::addPair: Pair added"
        );
        Observation storage observation = pairObservations[_pair];
        (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        ) = MarsSwapOracleLibrary.currentCumulativePrices(_pair);
        pairs.push(_pair);
        observation.price0CumulativeLast = price0Cumulative;
        observation.price1CumulativeLast = price1Cumulative;
        observation.blockTimestampLast = blockTimestamp;
        observation.added = true;
    }

    function removePair(address _pair) external override onlyGovernor {
        require(
            pairObservations[_pair].added,
            "SwapMiningOracle::removePair: Pair not added"
        );
        delete pairObservations[_pair];
        uint256 idx_i;
        for (uint256 i; i < pairs.length; i++) {
            if (pairs[i] == _pair) {
                idx_i = i;
                break;
            }
        }
        pairs[idx_i] = pairs[pairs.length - 1];
        pairs.pop();
    }

    function update(address _pair) external override {
        Observation storage observation = pairObservations[_pair];
        require(
            observation.added,
            "SwapMiningOracle::update: Pair must added"
        );
        (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        ) = MarsSwapOracleLibrary.currentCumulativePrices(_pair);
        uint32 timeElapsed = blockTimestamp - observation.blockTimestampLast; // Overflow is desired

        // Ensure that at least one full period has passed since the last update
        require(
            timeElapsed >= PERIOD,
            "SwapMiningOracle::update: Period not elapsed"
        );
        observation.price0CumulativeLast = price0Cumulative;
        observation.price1CumulativeLast = price1Cumulative;
        observation.blockTimestampLast = blockTimestamp;
    }

    // Note this will always return 0 before update has been called successfully for the first time.
    function consult(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut
    ) external view override returns (uint256 amountOut) {
        address pair =
            MarsSwapLibrary.pairFor(address(factory), _tokenIn, _tokenOut);
        Observation storage observation = pairObservations[pair];
        require(
            observation.added,
            "SwapMiningOracle::consult: Pair must added"
        );
        (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        ) = MarsSwapOracleLibrary.currentCumulativePrices(pair);
        (address token0, ) = MarsSwapLibrary.sortTokens(_tokenIn, _tokenOut);
        uint32 timeElapsed = blockTimestamp - observation.blockTimestampLast; // Overflow is desired

        if (token0 == _tokenIn) {
            FixedPoint.uq112x112 memory price0Average =
                FixedPoint.uq112x112(
                    uint224(
                        (price0Cumulative - observation.price0CumulativeLast) /
                            timeElapsed
                    )
                );
            amountOut = price0Average.mul(_amountIn).decode144();
        } else {
            FixedPoint.uq112x112 memory price1Average =
                FixedPoint.uq112x112(
                    uint224(
                        (price1Cumulative - observation.price1CumulativeLast) /
                            timeElapsed
                    )
                );
            amountOut = price1Average.mul(_amountIn).decode144();
        }
    }
}
