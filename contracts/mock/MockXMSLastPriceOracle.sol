// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/IMarsSwapFactory.sol";
import "../interfaces/IMarsSwapPairOracle.sol";
import "../libs/Decimal.sol";

contract MockXMSLastPriceOracle is IMarsSwapPairOracle {
    IMarsSwapFactory public factory_;

    // ----------- Governor only state changing API -----------

    function setPeriod(uint256 _period) external override {}

    function setOverrun(uint256 _overrun) external override {}

    function setFactory(address _factory) external override {
        factory_ = IMarsSwapFactory(_factory);
    }

    // ----------- State changing api -----------

    function update() external override {}

    function consult(uint256 _amountIn)
        external
        view
        override
        returns (Decimal.D256 memory amountOut)
    {
        return Decimal.ratio(200000, 10**6);
    }

    // ----------- Getters -----------

    function PERIOD() external pure override returns (uint256) {
        return 0;
    }

    function OVERRUN() external pure override returns (uint256) {
        return 0;
    }

    function factory() external view override returns (IMarsSwapFactory) {
        return factory_;
    }
}
