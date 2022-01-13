// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MarsStake is ERC20 {
    using SafeMath for uint256;
    IERC20 public xms;

    constructor(IERC20 _xms) ERC20("Staking XMS", "sXMS") {
        xms = _xms;
    }

    function enter(uint256 _amount) public {
        uint256 totalXMS = xms.balanceOf(address(this));

        uint256 totalsXMS = totalSupply();

        if (totalsXMS == 0 || totalXMS == 0) {
            _mint(msg.sender, _amount);
        }
        // Calculate and mint the amount of sXMS the XMS is worth. The ratio will change overtime, as sXMS is burned/minted and XMS deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalsXMS).div(totalXMS);
            _mint(msg.sender, what);
        }
        // Lock the XMS in the contract
        require(
            xms.transferFrom(msg.sender, address(this), _amount),
            "MarsStake::enter: TransferFrom failed"
        );
    }

    // Leave the bar. Claim back your XMS.
    // Unlocks the staked + gained XMS and burns sXMS
    function leave(uint256 _share) public {
        // Gets the amount of sXMS in existence
        uint256 totalsXMS = totalSupply();
        // Calculates the amount of XMS the sXMS is worth
        uint256 what = _share.mul(xms.balanceOf(address(this))).div(totalsXMS);
        _burn(msg.sender, _share);
        require(
            xms.transfer(msg.sender, what),
            "MarsStake::leave: Transfer failed"
        );
    }
}
