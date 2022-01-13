// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IXMSToken.sol";

/// @title A proxy delegate contract for XMS
/// @author USDM Protocol
contract Delegatee is Ownable {
    IXMSToken public xms;

    /// @notice Delegatee constructor
    /// @param _delegatee The address to delegate XMS to
    /// @param _xms The XMS token address
    constructor(address _delegatee, address _xms) {
        xms = IXMSToken(_xms);
        xms.delegate(_delegatee);
    }

    /// @notice Send XMS back to timelock and selfdestruct
    function withdraw() public onlyOwner {
        IXMSToken _xms = xms;
        uint256 balance = _xms.balanceOf(address(this));
        require(
            _xms.transfer(owner(), balance),
            "Delegatee::withdraw: Transfer failed"
        );
    }
}
