// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./GenesisEvent.sol";
import "../libs/MarsSwapOracleLibrary.sol";
import "../libs/MarsSwapLibrary.sol";
import "../libs/FixedPoint.sol";
import "../utils/Timed.sol";
import "../refs/CoreRef.sol";
import "../interfaces/IChainlinkLastPriceOracle.sol";

/// @title XMS Genesis Event
/// @author USDM Protocol
contract XMSGenesisEvent is GenesisEvent {
    using Decimal for Decimal.D256;
    using SafeMath for uint256;
    using FixedPoint for *;

    // Chainlink to get underlying asset price
    IChainlinkLastPriceOracle chainlink;

    address private _lp;
    uint256 private _price0CumulativeLast;
    uint256 private _price1CumulativeLast;
    uint32 private _blockTimestampTWAPLast;
    FixedPoint.uq112x112 private _price0Average;
    FixedPoint.uq112x112 private _price1Average;

    address private _wbnb;

    address public devAddress;

    uint256 public xmsPerMGEN;

    mapping(address => uint256) public delayRefundInfo;

    /// @notice XMSGenesisEvent constructor
    /// @param _core USDM Core address to reference
    /// @param _devAddress Project address
    /// @param _duration Duration of the genesis event period
    /// @param _hours Duration of the release stake and refund
    /// @param _cap Upper limit amount of USDM to mint
    /// @param _stakeToken Stake token
    /// @param _stakeTokenAllocPoint Stake token allocation point
    /// @param _xmsAllocPoint XMS allocation point
    /// @param _chainlink Chainlink
    /// @param wbnb_ WBNB
    /// @param _factory MarsSwapFactory
    constructor(
        address _core,
        address _devAddress,
        uint256 _duration,
        uint256 _hours,
        uint256 _cap,
        address _stakeToken,
        uint256 _stakeTokenAllocPoint,
        uint256 _xmsAllocPoint,
        address _chainlink,
        address wbnb_,
        address _factory
    )
        GenesisEvent(
            _core,
            _duration,
            _hours,
            _cap,
            _stakeToken,
            _stakeTokenAllocPoint,
            _xmsAllocPoint
        )
    {
        require(
            _devAddress != address(0),
            "XMSGenesisEvent::constructor: Zero address"
        );
        devAddress = _devAddress;

        require(
            _stakeToken != address(xms()),
            "XMSGenesisEvent::constructor: Bad address"
        );

        require(
            _factory != address(0),
            "XMSGenesisEvent::constructor: Zero address"
        );
        require(
            wbnb_ != address(0),
            "XMSGenesisEvent::constructor: Zero address"
        );
        _wbnb = wbnb_;
        require(
            _chainlink != address(0) &&
                IChainlinkLastPriceOracle(_chainlink).token() == wbnb_,
            "XMSGenesisEvent::constructor: Bad chainlink"
        );
        chainlink = IChainlinkLastPriceOracle(_chainlink);
        _lp = MarsSwapLibrary.pairFor(_factory, address(xms()), wbnb_);

        require(
            _lp != address(0),
            "XMSGenesisEvent::constructor: LP no liquidity"
        );
    }

    function transfer(address to, uint256 amount)
        public
        pure
        override
        returns (bool)
    {
        revert("XMSGenesisEvent::transfer: Not support transfer");
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public pure override returns (bool) {
        revert("XMSGenesisEvent::transferFrom: Not support transferFrom");
    }

    function initGenesisEvent(uint256 _startTime)
        public
        override
        onlyGuardianOrGovernor
    {
        super.initGenesisEvent(_startTime);
        (
            _price0CumulativeLast,
            _price1CumulativeLast,
            _blockTimestampTWAPLast
        ) = MarsSwapOracleLibrary.currentCumulativePrices(_lp);
    }

    /// @notice Allows for entry into the genesis event via XMS. Only callable during genesis event period.
    /// @param to Address to send MGENE tokens to
    /// @param value Amount of XMS to deposit
    function purchase(address to, uint256 value)
        external
        payable
        override
        duringTime
        whenNotPaused
    {
        require(msg.value == 0, "XMSGenesisEvent::purchase: No need BNB");
        require(value != 0, "XMSGenesisEvent::purchase: No value sent");
        require(
            xms().transferFrom(msg.sender, address(this), value),
            "XMSGenesisEvent::purchase: TransferFrom failed"
        );
        if (address(stakeToken) != address(0)) {
            uint256 stakeAmount = value.mul(stakeTokenAllocPoint).div(
                underlyingTokenAllocPoint
            );
            require(
                stakeToken.transferFrom(msg.sender, address(this), stakeAmount)
            );
            stakeInfo[to] = stakeInfo[to].add(stakeAmount);
        }
        _mint(to, value);

        emit Purchase(to, value);
    }

    // Add a backdoor out of genesis event in case of brick
    function emergencyExit(address from, address payable to) external override {
        require(
            // solhint-disable-next-line not-rely-on-time
            block.timestamp > (startTime + duration + 3 hours),
            "XMSGenesisEvent::emergencyExit: Not in exit window"
        );
        require(
            launchBlock == 0,
            "XMSGenesisEvent::emergencyExit: Launch already happened"
        );

        uint256 heldMGENE = balanceOf(from);

        require(
            heldMGENE != 0,
            "XMSGenesisEvent::emergencyExit: No MGENE balance"
        );
        require(
            msg.sender == from || allowance(from, msg.sender) >= heldMGENE,
            "XMSGenesisEvent::emergencyExit: Not approved for emergency withdrawal"
        );

        _burnFrom(from, heldMGENE);

        require(
            xms().transfer(to, heldMGENE),
            "XMSGenesisEvent::emergencyExit: Transfer failed"
        );

        if (address(stakeToken) != address(0)) {
            uint256 stakeAmount = stakeInfo[from];
            delete stakeInfo[from];
            require(
                stakeToken.transfer(from, stakeAmount),
                "XMSGenesisEvent::emergencyExit: Transfer failed"
            );
        }
    }

    /// @notice Launch USDM Protocol. Callable once genesis event period has ended
    function launch()
        external
        override
        onlyGuardianOrGovernor
        afterTime
        whenNotPaused
    {
        require(
            launchBlock == 0,
            "XMSGenesisEvent::launch: Launch already happened"
        );
        // Complete XMS genesis event
        launchBlock = block.number;
        launchTimestamp = block.timestamp;
        (_price0Average, _price1Average) = _calculateTWAP();

        (uint256 totalEffectiveMGENE, bool _supersuper) = _getEffectiveMGENE(
            totalSupply()
        );
        supersuper = _supersuper;
        uint256 refundMGENE = totalSupply().sub(totalEffectiveMGENE);

        (
            Decimal.D256 memory xmsPrice,
            uint256 bnbPerXMS,
            uint256 bnbPrice
        ) = underlyingPrice();
        uint256 totalUSDM = xmsPrice.mul(totalEffectiveMGENE).asUint256();
        require(
            xms().transfer(devAddress, xmsBalance().sub(refundMGENE)),
            "XMSGenesisEvent::launch: Transfer failed"
        );
        _mintUSDM(totalUSDM);
        if (totalSupply() > 0) {
            xmsPerMGEN = refundMGENE.mul(1e12).div(totalSupply());
            usdmPerMGEN = totalUSDM.mul(1e12).div(totalSupply());
        }

        // solhint-disable-next-line not-rely-on-time
        emit Launch(block.timestamp, bnbPerXMS, bnbPrice);
    }

    /// @notice Claim MGENE tokens for USDM. Only callable post launch
    /// @param to Address to send claimed USDM to.
    function claim(address to) external override afterLaunch whenNotPaused {
        (
            uint256 usdmAmount,
            uint256 xmsAmount,
            uint256 stakeAmount
        ) = getAmountsToClaim(to);

        uint256 amountIn = balanceOf(to);
        if (amountIn > 0) {
            // Burn MGENE
            _burnFrom(to, amountIn);
        }
        // Send USDM and XMS
        if (usdmAmount != 0) {
            require(
                usdm().transfer(to, usdmAmount),
                "XMSGenesisEvent::claim: Transfer failed"
            );
        }

        uint256 recordXMSAmount = delayRefundInfo[to];
        if (
            recordXMSAmount > 0 &&
            block.number >= launchBlock.add(durationBlocks)
        ) {
            xmsAmount = recordXMSAmount;
            delete delayRefundInfo[to];
        } else if (xmsAmount != 0) {
            if (block.number < launchBlock.add(durationBlocks)) {
                delayRefundInfo[to] = xmsAmount;
                xmsAmount = 0;
            }
        }
        if (xmsAmount != 0) {
            require(
                xms().transfer(to, xmsAmount),
                "XMSGenesisEvent::claim: Transfer failed"
            );
        }

        if (
            stakeAmount != 0 && block.number >= launchBlock.add(durationBlocks)
        ) {
            delete stakeInfo[to];
            require(
                stakeToken.transfer(to, stakeAmount),
                "XMSGenesisEvent::claim: Transfer failed"
            );
        }

        emit Claim(to, amountIn, usdmAmount, xmsAmount, stakeAmount);
    }

    /// @notice Calculate amount of USDM, X claimable by an account
    /// @return usdmAmount The amount of USDM received by the user per MGENE
    /// @return xmsAmount The amount of XMS refunded by genesis event
    /// @return stakeAmount The amount of X received for stake
    /// @dev this function is only callable post launch
    function getAmountsToClaim(address to)
        public
        view
        override
        afterLaunch
        returns (
            uint256 usdmAmount,
            uint256 xmsAmount,
            uint256 stakeAmount
        )
    {
        uint256 userMGENE = balanceOf(to);

        usdmAmount = usdmPerMGEN.mul(userMGENE).div(1e12);
        xmsAmount = xmsPerMGEN.mul(userMGENE).div(1e12);
        if (xmsAmount == 0) {
            xmsAmount = delayRefundInfo[to];
        }
        stakeAmount = stakeInfo[to];
    }

    /// @notice Return price
    /// @return Price reported as USDM per XMS with XMS being the underlying asset
    function underlyingPrice()
        public
        view
        override
        returns (
            Decimal.D256 memory,
            uint256,
            uint256
        )
    {
        FixedPoint.uq112x112 memory price0Average_;
        FixedPoint.uq112x112 memory price1Average_;
        if (launchBlock > 0) {
            (price0Average_, price1Average_) = (_price0Average, _price1Average);
        } else {
            (price0Average_, price1Average_) = _calculateTWAP();
        }
        uint256 bnbPerXMS = _consultTWAP(
            price0Average_,
            price1Average_,
            10**xms().decimals()
        );
        (uint256 chainlinkPrice, uint8 decimals) = chainlink.getLatestPrice();
        Decimal.D256 memory bnbPrice = Decimal.ratio(
            chainlinkPrice,
            10**decimals
        );
        return (
            Decimal.D256({value: bnbPerXMS}).mul(bnbPrice),
            bnbPerXMS,
            bnbPrice.value
        );
    }

    function _calculateTWAP()
        internal
        view
        returns (FixedPoint.uq112x112 memory, FixedPoint.uq112x112 memory)
    {
        (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        ) = MarsSwapOracleLibrary.currentCumulativePrices(_lp);
        uint32 timeElapsed = blockTimestamp - _blockTimestampTWAPLast; // Overflow is desired

        return (
            FixedPoint.uq112x112(
                uint224(
                    (price0Cumulative - _price0CumulativeLast) / timeElapsed
                )
            ),
            FixedPoint.uq112x112(
                uint224(
                    (price1Cumulative - _price1CumulativeLast) / timeElapsed
                )
            )
        );
    }

    function _consultTWAP(
        FixedPoint.uq112x112 memory price0Average_,
        FixedPoint.uq112x112 memory price1Average_,
        uint256 _amountIn
    ) internal view returns (uint256 amountOut) {
        (address token0, ) = MarsSwapLibrary.sortTokens(address(xms()), _wbnb);

        if (token0 == address(xms())) {
            amountOut = price0Average_.mul(_amountIn).decode144();
        } else {
            amountOut = price1Average_.mul(_amountIn).decode144();
        }
    }
}
