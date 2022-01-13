// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./PCVVenusDeposit.sol";
import "../interfaces/IMarsSwapRouter.sol";
import "../interfaces/IVBNB.sol";
import "../interfaces/IWETH.sol";

/// @title Implementation for an BNB venus PCV Deposit
/// @author USDM Protocol
contract BNBVenusPCVDeposit is PCVVenusDeposit {
    /// @notice The Uniswap router contract
    IMarsSwapRouter public router;

    IVBNB public vbnb;
    IERC20 public xvs;
    IWETH public weth;

    /// @notice BNB venus PCV Deposit constructor
    /// @param _core USDM Core for reference
    /// @param _router Uniswap Router
    /// @param _vbnb Venus vbnb
    /// @param _xvx Venus xvs
    /// @param _weth WETH
    constructor(
        address _core,
        address _router,
        address _vbnb,
        address _xvx,
        address _weth
    ) PCVVenusDeposit(_core) {
        router = IMarsSwapRouter(_router);

        vbnb = IVBNB(_vbnb);
        xvs = IERC20(_xvx);
        weth = IWETH(_weth);
    }

    /// @notice Deposit tokens into the PCV allocation
    /// @param bnbAmount Amount of tokens deposited
    function deposit(uint256 bnbAmount)
        external
        payable
        override
        postGenesis
        whenNotPaused
    {
        require(
            bnbAmount == msg.value,
            "BNBVenusPCVDeposit::deposit: Sent value does not equal input"
        );

        bnbAmount = totalValue(); // Include any BNB dust from prior LP

        _supply(bnbAmount);

        emit Deposit(msg.sender, bnbAmount);
    }

    /// @notice returns total value of PCV in the Deposit
    function totalValue() public view override returns (uint256) {
        return address(this).balance;
    }

    function _supply(uint256 bnbAmount) internal override {
        vbnb.mint{value: bnbAmount}();
    }

    function _leaveSupply(uint256 bnbAmount) internal override {
        require(
            vbnb.redeemUnderlying(bnbAmount) == 0,
            "BNBVenusPCVDeposit::_leaveSupply: RedeemUnderlying failed"
        );
    }

    function _harvest() internal virtual override returns (uint256) {
        uint256 amount = xvs.balanceOf(address(this));
        uint256 endOfTime = uint256(-1);
        address[] memory path = new address[](2);
        path[0] = address(xvs);
        path[1] = address(weth);
        uint256[] memory amounts = router.swapExactTokensForETH(
            amount,
            0,
            path,
            address(this),
            endOfTime
        );
        return amounts[amounts.length - 1];
    }

    function _transferWithdrawn(address to, uint256 amount) internal override {
        (bool success, ) = to.call{value: amount}("");
        require(
            success,
            "BNBVenusPCVDeposit::_transferWithdrawn: Transfer failed"
        );
    }
}
