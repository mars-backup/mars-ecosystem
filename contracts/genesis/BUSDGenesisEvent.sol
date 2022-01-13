// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./GenesisEvent.sol";
import "../utils/Timed.sol";
import "../refs/CoreRef.sol";
import "../interfaces/IChainlinkLastPriceOracle.sol";
import "../interfaces/IPCVController.sol";

/// @title BUSD Genesis Event
/// @author USDM Protocol
contract BUSDGenesisEvent is GenesisEvent {
    using Decimal for Decimal.D256;
    using SafeMath for uint256;

    // Chainlink to get underlying asset price
    IChainlinkLastPriceOracle chainlink;

    IERC20 public busd;

    address public pcvController;

    uint256 public busdPerMGEN;

    /// @notice BUSDGenesisEvent constructor
    /// @param _core USDM Core address to reference
    /// @param _pcvController PCVController
    /// @param _busd BUSD
    /// @param _duration Duration of the genesis event period
    /// @param _hours Duration of the release stake and refund
    /// @param _cap Upper limit amount of USDM to mint
    /// @param _stakeToken Stake token
    /// @param _stakeTokenAllocPoint Stake token allocation point
    /// @param _busdAllocPoint BUSD allocation point
    /// @param _chainlink Chainlink
    constructor(
        address _core,
        address _pcvController,
        address _busd,
        uint256 _duration,
        uint256 _hours,
        uint256 _cap,
        address _stakeToken,
        uint256 _stakeTokenAllocPoint,
        uint256 _busdAllocPoint,
        address _chainlink
    )
        GenesisEvent(
            _core,
            _duration,
            _hours,
            _cap,
            _stakeToken,
            _stakeTokenAllocPoint,
            _busdAllocPoint
        )
    {
        require(
            _pcvController != address(0),
            "BUSDGenesisEvent::constructor: Zero address"
        );
        pcvController = _pcvController;

        require(
            _busd != address(0),
            "BUSDGenesisEvent::constructor: Zero address"
        );
        busd = IERC20(_busd);
        require(
            _stakeToken != _busd,
            "BUSDGenesisEvent::constructor: Bad address"
        );
        require(
            _chainlink != address(0),
            "BUSDGenesisEvent::constructor: Zero address"
        );
        chainlink = IChainlinkLastPriceOracle(_chainlink);
    }

    function transfer(address to, uint256 amount)
        public
        pure
        override
        returns (bool)
    {
        revert("BUSDGenesisEvent::transfer: Not support transfer");
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public pure override returns (bool) {
        revert("BUSDGenesisEvent::transferFrom: Not support transferFrom");
    }

    /// @notice Allows for entry into the genesis event via BUSD. Only callable during genesis event period.
    /// @param to Address to send MGENE tokens to
    /// @param value Amount of BUSD to deposit
    function purchase(address to, uint256 value)
        external
        payable
        override
        duringTime
        whenNotPaused
    {
        require(msg.value == 0, "BUSDGenesisEvent::purchase: No need BNB");
        require(value != 0, "BUSDGenesisEvent::purchase: No value sent");
        require(
            busd.transferFrom(msg.sender, address(this), value),
            "BUSDGenesisEvent::purchase: TransferFrom failed"
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
            "BUSDGenesisEvent::emergencyExit: Not in exit window"
        );
        require(
            launchBlock == 0,
            "BUSDGenesisEvent::emergencyExit: Launch already happened"
        );

        uint256 heldMGENE = balanceOf(from);

        require(
            heldMGENE != 0,
            "BUSDGenesisEvent::emergencyExit: No MGENE balance"
        );
        require(
            msg.sender == from || allowance(from, msg.sender) >= heldMGENE,
            "BUSDGenesisEvent::emergencyExit: Not approved for emergency withdrawal"
        );

        _burnFrom(from, heldMGENE);

        require(
            busd.transfer(to, heldMGENE),
            "BUSDGenesisEvent::emergencyExit: Transfer failed"
        );

        if (address(stakeToken) != address(0)) {
            uint256 stakeAmount = stakeInfo[from];
            delete stakeInfo[from];
            require(
                stakeToken.transfer(from, stakeAmount),
                "BUSDGenesisEvent::emergencyExit: Transfer failed"
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
            "BUSDGenesisEvent::launch: Launch already happened"
        );
        // Complete BUSD genesis event
        launchBlock = block.number;
        launchTimestamp = block.timestamp;

        (uint256 totalEffectiveMGENE, bool _supersuper) = _getEffectiveMGENE(
            totalSupply()
        );
        supersuper = _supersuper;
        uint256 refundMGENE = totalSupply().sub(totalEffectiveMGENE);

        (
            Decimal.D256 memory busdPrice,
            uint256 chainlinkPrice,

        ) = underlyingPrice();
        uint256 totalUSDM = busdPrice.mul(totalEffectiveMGENE).asUint256();
        require(
            busd.transfer(
                pcvController,
                busd.balanceOf(address(this)).sub(refundMGENE)
            ),
            "BUSDGenesisEvent::launch: Transfer failed"
        );
        _mintUSDM(totalUSDM);
        if (totalSupply() > 0) {
            busdPerMGEN = refundMGENE.mul(1e12).div(totalSupply());
            usdmPerMGEN = totalUSDM.mul(1e12).div(totalSupply());
        }

        // solhint-disable-next-line not-rely-on-time
        emit Launch(block.timestamp, chainlinkPrice, 0);
    }

    /// @notice Claim MGENE tokens for USDM. Only callable post launch
    /// @param to Address to send claimed USDM to.
    function claim(address to) external override afterLaunch whenNotPaused {
        (
            uint256 usdmAmount,
            uint256 busdAmount,
            uint256 stakeAmount
        ) = getAmountsToClaim(to);

        uint256 amountIn = balanceOf(to);
        if (amountIn > 0) {
            // Burn MGENE
            _burnFrom(to, amountIn);
        }
        // Send USDM and BUSD
        if (usdmAmount != 0) {
            require(
                usdm().transfer(to, usdmAmount),
                "BUSDGenesisEvent::claim: Transfer failed"
            );
        }
        if (busdAmount != 0) {
            require(
                busd.transfer(to, busdAmount),
                "BUSDGenesisEvent::claim: Transfer failed"
            );
        }

        if (
            stakeAmount != 0 && block.number >= launchBlock.add(durationBlocks)
        ) {
            delete stakeInfo[to];
            require(
                stakeToken.transfer(to, stakeAmount),
                "BUSDGenesisEvent::claim: Transfer failed"
            );
        }

        emit Claim(to, amountIn, usdmAmount, busdAmount, stakeAmount);
    }

    /// @notice Calculate amount of USDM, X claimable by an account
    /// @return usdmAmount The amount of USDM received by the user per MGENE
    /// @return busdAmount The amount of BUSD refunded by genesis event
    /// @return stakeAmount The amount of X received for stake
    /// @dev this function is only callable post launch
    function getAmountsToClaim(address to)
        public
        view
        override
        afterLaunch
        returns (
            uint256 usdmAmount,
            uint256 busdAmount,
            uint256 stakeAmount
        )
    {
        uint256 userMGENE = balanceOf(to);

        usdmAmount = usdmPerMGEN.mul(userMGENE).div(1e12);
        busdAmount = busdPerMGEN.mul(userMGENE).div(1e12);
        stakeAmount = stakeInfo[to];
    }

    /// @notice Return price
    /// @return Price reported as USDM per BUSD with BUSD being the underlying asset
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
        (uint256 chainlinkPrice, uint8 decimals) = chainlink.getLatestPrice();
        Decimal.D256 memory busdPrice = Decimal.ratio(
            chainlinkPrice,
            10**decimals
        );
        return (busdPrice, busdPrice.value, 0);
    }
}
