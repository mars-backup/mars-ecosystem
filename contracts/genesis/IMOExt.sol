// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../refs/CoreRef.sol";

/// @title IMO Ext
/// @author USDM Protocol
contract IMOExt is CoreRef, Initializable {
    using SafeMath for uint256;
    struct UserInfo {
        uint256 amount; // How many MIMO tokens the user has after launch
        uint256 debt; // Debt
    }

    /// @notice XMS per block
    uint256 public xmsPerBlock;

    /// @notice The block amount to release XMS
    uint256 public durationBlocks;

    uint256 public startBlock;

    uint256 public startTime;

    mapping(address => UserInfo) public userInfo;

    uint256 public totalAmount;

    event Claim(address indexed _to, uint256 _amountXMS);

    /// @notice IMO constructor
    /// @param _core USDM Core address to reference
    /// @param _days Duration of the release
    constructor(address _core, uint256 _days) CoreRef(_core) {
        durationBlocks = (_days * 24 * 3600) / 3;
    }

    function initialize(
        address[] calldata _accounts,
        uint256[] calldata _amounts
    ) external initializer onlyGuardianOrGovernor {
        require(
            _accounts.length == _amounts.length,
            "IMOExt::initialize: Init data error"
        );
        uint256 _totalAmount;
        for (uint256 i; i < _accounts.length; i++) {
            userInfo[_accounts[i]].amount = _amounts[i];
            _totalAmount = _totalAmount + _amounts[i];
        }
        totalAmount = _totalAmount;
        startBlock = block.number;
        startTime = block.timestamp;
        uint256 xmsAmount = xmsBalance();
        xmsPerBlock = xmsAmount.div(durationBlocks);
    }

    modifier postInit() {
        require(startBlock > 0, "IMOExt::postInit: Not initial");
        _;
    }

    /// @notice Claim XMS
    /// @param to Address to send claimed XMS to.
    function claim(address to) external postInit {
        require(
            block.number > startBlock,
            "IMOExt::claim: No claiming in start block"
        );
        uint256 xmsAmount = getAmountsToClaim(to);

        // Send XMS
        if (xmsAmount != 0) {
            UserInfo storage _userInfo = userInfo[to];
            uint256 userDebt = _userInfo.debt;
            userDebt = userDebt + xmsAmount;
            _userInfo.debt = userDebt;
            require(
                xms().transfer(to, xmsAmount),
                "IMOExt::claim: Transfer failed"
            );
        }

        emit Claim(to, xmsAmount);
    }

    /// @notice Calculate amount of XMS claimable by an account post-init
    /// @return xmsAmount The amount of XMS received by the user per IMO
    function getAmountsToClaim(address to)
        public
        view
        postInit
        returns (uint256)
    {
        UserInfo memory _userInfo = userInfo[to];
        uint256 endBlock = startBlock.add(durationBlocks);
        endBlock = block.number < endBlock ? block.number : endBlock;
        return
            endBlock
                .sub(startBlock)
                .mul(xmsPerBlock)
                .mul(_userInfo.amount)
                .div(totalAmount)
                .sub(_userInfo.debt);
    }

    /// @notice Calculate amount of XMS could be received in the future.
    function getUnClaimableAmount(address to)
        public
        view
        postInit
        returns (uint256 xmsAmount)
    {
        UserInfo memory _userInfo = userInfo[to];
        uint256 endBlock = startBlock.add(durationBlocks);
        if (block.number < endBlock) {
            xmsAmount = _userInfo
                .amount
                .mul(endBlock.sub(block.number).mul(xmsPerBlock))
                .div(totalAmount);
        }
    }
}
