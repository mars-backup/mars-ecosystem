// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/IMarsSwapFactory.sol";
import "../libs/FixedPoint.sol";

import "../libs/MarsSwapOracleLibrary.sol";
import "../libs/MarsSwapLibrary.sol";
import "./CombinationOracle.sol";

// XMS Oracle
// 1, USDM mint and redeem
// 2, USDM supply cap
contract MarsSwapPairCombOracle is CombinationOracle {
    using FixedPoint for *;

    uint256 public override PERIOD = 900; // 15 minutes TWAP (time-weighted average price)
    uint256 public override OVERRUN = 1800; // 30 minutes overrun TWAP
    uint256 public CONSULT_LENIENCY = 1800; // Used for being able to consult past the period end
    bool public ALLOW_STALE_CONSULTS = false; // If false, consult() will fail if the TWAP is stale

    IMarsSwapFactory public override factory;

    constructor(
        address _core,
        address _factory,
        uint256 _period,
        uint256 _consultLeniency,
        uint256 _overrun
    ) CombinationOracle(_core) {
        factory = IMarsSwapFactory(_factory);
        PERIOD = _period;
        CONSULT_LENIENCY = _consultLeniency;
        OVERRUN = _overrun;
    }

    function setFactory(address _factory) external override onlyGovernor {
        require(
            _factory != address(0),
            "MarsSwapPairCombOracle::setFactory: Zero address"
        );
        factory = IMarsSwapFactory(_factory);
    }

    function setPeriod(uint256 _period)
        external
        override
        onlyGuardianOrGovernor
    {
        PERIOD = _period;
    }

    function setOverrun(uint256 _overrun)
        external
        override
        onlyGuardianOrGovernor
    {
        OVERRUN = _overrun;
    }

    function setConsultLeniency(uint256 _consult_leniency)
        external
        onlyGuardianOrGovernor
    {
        CONSULT_LENIENCY = _consult_leniency;
    }

    function setAllowStaleConsults(bool _allow_stale_consults)
        external
        onlyGovernor
    {
        ALLOW_STALE_CONSULTS = _allow_stale_consults;
    }

    function _initialize(address _token0, address _token1) internal override {
        address pair = MarsSwapLibrary.pairFor(
            address(factory),
            _token0,
            _token1
        );
        Observation storage observation = pairObservations[pair];
        (
            uint256 price0Cumulative,
            uint256 price1Cumulative,

        ) = MarsSwapOracleLibrary.currentCumulativePrices(address(pair));
        observation.price0CumulativeLast = price0Cumulative;
        observation.price1CumulativeLast = price1Cumulative;
    }

    // Check if update() can be called instead of wasting gas calling it
    function _canUpdate(
        uint32 blockTimestamp,
        address _token0,
        address _token1
    ) internal view override returns (bool) {
        address pair = MarsSwapLibrary.pairFor(
            address(factory),
            _token0,
            _token1
        );
        Observation storage observation = pairObservations[pair];
        uint32 timeElapsed = blockTimestamp - observation.blockTimestampLast; // Overflow is desired
        return (timeElapsed >= PERIOD);
    }

    function _isStale(
        uint32 blockTimestamp,
        address _token0,
        address _token1
    ) internal view override returns (bool) {
        address pair = MarsSwapLibrary.pairFor(
            address(factory),
            _token0,
            _token1
        );
        Observation storage observation = pairObservations[pair];

        uint32 timeElapsed = blockTimestamp - observation.blockTimestampLast; // Overflow is desired
        if (
            (timeElapsed < (PERIOD + CONSULT_LENIENCY)) || ALLOW_STALE_CONSULTS
        ) {
            return false;
        }
        return true;
    }

    function _update(address _token0, address _token1) internal override {
        address pair = MarsSwapLibrary.pairFor(
            address(factory),
            _token0,
            _token1
        );
        Observation storage observation = pairObservations[pair];
        (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        ) = MarsSwapOracleLibrary.currentCumulativePrices(address(pair));
        uint32 timeElapsed = blockTimestamp - observation.blockTimestampLast; // Overflow is desired

        // Ensure that at least one full period has passed since the last update
        require(
            timeElapsed >= PERIOD,
            "MarsSwapPairCombOracle::_update: Period not elapsed"
        );
        observation.price0Average = FixedPoint.uq112x112(
            uint224(
                (price0Cumulative - observation.price0CumulativeLast) /
                    timeElapsed
            )
        );
        observation.price1Average = FixedPoint.uq112x112(
            uint224(
                (price1Cumulative - observation.price1CumulativeLast) /
                    timeElapsed
            )
        );
        observation.price0CumulativeLast = price0Cumulative;
        observation.price1CumulativeLast = price1Cumulative;
        observation.blockTimestampLast = blockTimestamp;
        observation.timeElapsed = timeElapsed;
    }

    function _consult(
        uint32 _blockTimestamp,
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut
    ) internal view override returns (uint256 amountOut) {
        // Ensure that the price is not stale
        require(
            !_isStale(_blockTimestamp, _tokenIn, _tokenOut),
            "MarsSwapPairCombOracle::_consult: Price is stale need to call update"
        );

        (address token0, ) = MarsSwapLibrary.sortTokens(_tokenIn, _tokenOut);

        address pair = MarsSwapLibrary.pairFor(
            address(factory),
            _tokenIn,
            _tokenOut
        );
        Observation storage observation = pairObservations[pair];
        require(
            observation.timeElapsed < OVERRUN,
            "MarsSwapPairCombOracle::_consult: Overrun"
        );
        if (token0 == _tokenIn) {
            amountOut = observation.price0Average.mul(_amountIn).decode144();
        } else {
            amountOut = observation.price1Average.mul(_amountIn).decode144();
        }
    }
}
