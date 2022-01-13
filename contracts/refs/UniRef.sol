// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";
import "../interfaces/IUniRef.sol";
import "../refs/CoreRef.sol";
import "../libs/Babylonian.sol";

/// @title A Reference to Uniswap
/// @author USDM Protocol
/// @notice Defines some modifiers and utilities around interacting with Uniswap
/// @dev The uniswap pair should be USDM and another asset
abstract contract UniRef is IUniRef, CoreRef {
    using Decimal for Decimal.D256;

    /// @notice The Uniswap router contract
    IMarsSwapRouter public override router;

    /// @notice The referenced Uniswap pair contract
    IMarsSwapPair public override pair;

    /// @notice The referenced Uniswap factory contract
    IMarsSwapFactory public override factory;

    /// @notice UniRef constructor
    /// @param _pair Uniswap pair to reference
    /// @param _router Uniswap Router to reference
    /// @param _factory Uniswap Factory to reference
    constructor(
        address _pair,
        address _router,
        address _factory
    ) {
        _setupPair(_pair);

        router = IMarsSwapRouter(_router);
        factory = IMarsSwapFactory(_factory);

        _approveToken(address(usdm()));
        _approveToken(token());
        _approveToken(_pair);
    }

    /// @notice Set the new pair contract
    /// @param _pair The new pair
    /// @dev Also approves the router for the new pair token and underlying token
    function setPair(address _pair) external override onlyGovernor {
        _setupPair(_pair);

        _approveToken(address(usdm()));
        _approveToken(token());
        _approveToken(_pair);
    }

    /// @notice Update tokens allowance
    function updateAllowance() external override onlyGuardianOrGovernor {
        _approveToken(address(usdm()));
        _approveToken(token());
        _approveToken(address(pair));
    }

    /// @notice Set the new router contract
    /// @param _router The new router
    function setRouter(address _router) external override onlyGovernor {
        _setupRouter(_router);
    }

    /// @notice Set the new factory contract
    /// @param _factory The new factory
    function setFactory(address _factory) external override onlyGovernor {
        _setupFactory(_factory);
    }

    /// @notice The address of the non-usdm underlying token
    function token() public view override returns (address) {
        address token0 = pair.token0();
        if (address(usdm()) == token0) {
            return pair.token1();
        }
        return token0;
    }

    /// @notice Pair reserves with usdm listed first
    /// @dev Uses the max of pair usdm balance and usdm reserves. Mitigates attack vectors which manipulate the pair balance
    function getReserves()
        public
        view
        override
        returns (uint256 usdmReserves, uint256 tokenReserves)
    {
        address token0 = pair.token0();
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        (usdmReserves, tokenReserves) = address(usdm()) == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
        return (usdmReserves, tokenReserves);
    }

    /// @notice Amount of pair liquidity owned by this contract
    /// @return Amount of LP tokens
    function liquidityOwned() public view override returns (uint256) {
        return pair.balanceOf(address(this));
    }

    /// @notice Invert a price
    /// @param price The price to invert
    /// @return The inverted price as a Decimal
    function invert(Decimal.D256 memory price)
        public
        pure
        virtual
        override
        returns (Decimal.D256 memory)
    {
        return Decimal.one().div(price);
    }

    /// @notice Approves a token for the router
    function _approveToken(address _token) internal {
        uint256 maxTokens = uint256(-1);
        IERC20(_token).approve(address(router), maxTokens);
    }

    function _setupPair(address _pair) internal {
        pair = IMarsSwapPair(_pair);
        emit PairUpdate(_pair);
    }

    function _setupRouter(address _router) internal {
        router = IMarsSwapRouter(_router);
        emit RouterUpdate(_router);
    }

    function _setupFactory(address _factory) internal {
        factory = IMarsSwapFactory(_factory);
        emit FactoryUpdate(_factory);
    }

    function _isPair(address account) internal view returns (bool) {
        return address(pair) == account;
    }

    /// @notice Get uniswap price and reserves
    /// @return Price reported as USDM per X
    /// @return reserveUSDM USDM reserves
    /// @return reserveOther NON-USDM reserves
    function _getUniswapPrice()
        internal
        view
        returns (
            Decimal.D256 memory,
            uint256 reserveUSDM,
            uint256 reserveOther
        )
    {
        (reserveUSDM, reserveOther) = getReserves();
        return (
            Decimal.ratio(reserveUSDM, reserveOther),
            reserveUSDM,
            reserveOther
        );
    }
}
