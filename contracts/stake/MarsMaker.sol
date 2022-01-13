// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../interfaces/IMarsSwapPair.sol";
import "../interfaces/IMarsSwapFactory.sol";
import "../refs/CoreRef.sol";

contract MarsMaker is CoreRef {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IXMSToken;

    // V1 - V5: OK
    IMarsSwapFactory public immutable factory;

    // V1 - V5: OK
    address public immutable bar;

    // V1 - V5: OK
    address private immutable _weth;

    // V1 - V5: OK
    mapping(address => address) internal _bridges;

    // E1: OK
    event LogBridgeSet(address indexed token, address indexed bridge);
    // E1: OK
    event LogConvert(
        address indexed server,
        address indexed token0,
        address indexed token1,
        uint256 amount0,
        uint256 amount1,
        uint256 amountXMS
    );

    constructor(
        address _core,
        address _factory,
        address _bar,
        address weth_
    ) CoreRef(_core) {
        factory = IMarsSwapFactory(_factory);
        require(_bar != address(0), "MarsMaker::constructor: Zero address");
        require(weth_ != address(0), "MarsMaker::constructor: Zero address");
        bar = _bar;
        _weth = weth_;
    }

    // F1 - F10: OK
    // C1 - C24: OK
    function bridgeFor(address token) public view returns (address bridge) {
        bridge = _bridges[token];
        if (bridge == address(0)) {
            bridge = _weth;
        }
    }

    // F1 - F10: OK
    // C1 - C24: OK
    function setBridge(address token, address bridge) external onlyGovernor {
        // Checks
        require(
            token != address(xms()) && token != _weth && token != bridge,
            "MarsMaker::setBridge: Invalid bridge"
        );

        // Effects
        _bridges[token] = bridge;
        emit LogBridgeSet(token, bridge);
    }

    // M1 - M5: OK
    // C1 - C24: OK
    // C6: It's not a fool proof solution, but it prevents flash loans, so here it's ok to use tx.origin
    modifier onlyEOA() {
        // Try to make flash-loan exploit harder to do by only allowing externally owned addresses.
        require(msg.sender == tx.origin, "MarsMaker::onlyEOA: Must use EOA");
        _;
    }

    // F1 - F10: OK
    // F3: _convert is separate to save gas by only checking the 'onlyEOA' modifier once in case of convertMultiple
    // F6: There is an exploit to add lots of XMS to the bar, run convert, then remove the XMS again.
    //     As the size of the MarsBar has grown, this requires large amounts of funds and isn't super profitable anymore
    //     The onlyEOA modifier prevents this being done with a flash loan.
    // C1 - C24: OK
    function convert(address token0, address token1) external onlyEOA {
        _convert(token0, token1);
    }

    // F1 - F10: OK, see convert
    // C1 - C24: OK
    // C3: Loop is under control of the caller
    function convertMultiple(
        address[] calldata token0,
        address[] calldata token1
    ) external onlyEOA {
        // TODO: This can be optimized a fair bit, but this is safer and simpler for now
        uint256 len = token0.length;
        for (uint256 i = 0; i < len; i++) {
            _convert(token0[i], token1[i]);
        }
    }

    // F1 - F10: OK
    // C1- C24: OK
    function _convert(address token0, address token1) internal {
        // Interactions
        // S1 - S4: OK
        IMarsSwapPair pair = IMarsSwapPair(factory.getPair(token0, token1));
        require(
            address(pair) != address(0),
            "MarsMaker::_convert: Invalid pair"
        );
        // balanceOf: S1 - S4: OK
        // transfer: X1 - X5: OK
        IERC20(address(pair)).safeTransfer(
            address(pair),
            pair.balanceOf(address(this))
        );
        // X1 - X5: OK
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));
        if (token0 != pair.token0()) {
            (amount0, amount1) = (amount1, amount0);
        }
        emit LogConvert(
            msg.sender,
            token0,
            token1,
            amount0,
            amount1,
            _convertStep(token0, token1, amount0, amount1)
        );
    }

    // F1 - F10: OK
    // C1 - C24: OK
    // All safeTransfer, _swap, _toXMS, _convertStep: X1 - X5: OK
    function _convertStep(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1
    ) internal returns (uint256 xmsOut) {
        // Interactions
        if (token0 == token1) {
            uint256 amount = amount0.add(amount1);
            if (token0 == address(xms())) {
                xms().safeTransfer(bar, amount);
                xmsOut = amount;
            } else if (token0 == _weth) {
                xmsOut = _toXMS(_weth, amount);
            } else {
                address bridge = bridgeFor(token0);
                amount = _swap(token0, bridge, amount, address(this));
                xmsOut = _convertStep(bridge, bridge, amount, 0);
            }
        } else if (token0 == address(xms())) {
            // eg. XMS - ETH
            xms().safeTransfer(bar, amount0);
            xmsOut = _toXMS(token1, amount1).add(amount0);
        } else if (token1 == address(xms())) {
            // eg. USDT - XMS
            xms().safeTransfer(bar, amount1);
            xmsOut = _toXMS(token0, amount0).add(amount1);
        } else if (token0 == _weth) {
            // eg. ETH - USDC
            xmsOut = _toXMS(
                _weth,
                _swap(token1, _weth, amount1, address(this)).add(amount0)
            );
        } else if (token1 == _weth) {
            // eg. USDT - ETH
            xmsOut = _toXMS(
                _weth,
                _swap(token0, _weth, amount0, address(this)).add(amount1)
            );
        } else {
            // eg. MIC - USDT
            address bridge0 = bridgeFor(token0);
            address bridge1 = bridgeFor(token1);
            if (bridge0 == token1) {
                // eg. MIC - USDT - and bridgeFor(MIC) = USDT
                xmsOut = _convertStep(
                    bridge0,
                    token1,
                    _swap(token0, bridge0, amount0, address(this)),
                    amount1
                );
            } else if (bridge1 == token0) {
                // eg. WBTC - DSD - and bridgeFor(DSD) = WBTC
                xmsOut = _convertStep(
                    token0,
                    bridge1,
                    amount0,
                    _swap(token1, bridge1, amount1, address(this))
                );
            } else {
                xmsOut = _convertStep(
                    bridge0,
                    bridge1, // eg. USDT - DSD - and bridgeFor(DSD) = WBTC
                    _swap(token0, bridge0, amount0, address(this)),
                    _swap(token1, bridge1, amount1, address(this))
                );
            }
        }
    }

    // F1 - F10: OK
    // C1 - C24: OK
    // All safeTransfer, swap: X1 - X5: OK
    function _swap(
        address fromToken,
        address toToken,
        uint256 amountIn,
        address to
    ) internal returns (uint256 amountOut) {
        // Checks
        // X1 - X5: OK
        IMarsSwapPair pair = IMarsSwapPair(factory.getPair(fromToken, toToken));
        require(
            address(pair) != address(0),
            "MarsMaker::_swap: Cannot convert"
        );
        (, , uint256 feeScale) = factory.fee(address(pair));

        // Interactions
        // X1 - X5: OK
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 amountInWithFee = amountIn.mul(feeScale);
        if (fromToken == pair.token0()) {
            amountOut =
                amountIn.mul(feeScale).mul(reserve1) /
                reserve0.mul(1000).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(0, amountOut, to);
            // TODO: Add maximum slippage?
        } else {
            amountOut =
                amountIn.mul(feeScale).mul(reserve0) /
                reserve1.mul(1000).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(amountOut, 0, to);
            // TODO: Add maximum slippage?
        }
    }

    // F1 - F10: OK
    // C1 - C24: OK
    function _toXMS(address token, uint256 amountIn)
        internal
        returns (uint256 amountOut)
    {
        // X1 - X5: OK
        amountOut = _swap(token, address(xms()), amountIn, bar);
    }
}
