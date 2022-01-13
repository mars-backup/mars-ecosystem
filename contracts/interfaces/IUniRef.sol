// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IMarsSwapRouter.sol";
import "./IMarsSwapPair.sol";
import "./IMarsSwapFactory.sol";
import "../libs/Decimal.sol";

/// @title UniRef interface
/// @author USDM Protocol
interface IUniRef {
    // ----------- Events -----------

    event PairUpdate(address indexed pair);
    event RouterUpdate(address indexed router);
    event FactoryUpdate(address indexed factory);

    // ----------- Governor only state changing api -----------

    function setPair(address) external;

    function setRouter(address) external;

    function setFactory(address) external;

    function updateAllowance() external;

    // ----------- Getters -----------

    function router() external view returns (IMarsSwapRouter);

    function pair() external view returns (IMarsSwapPair);

    function factory() external view returns (IMarsSwapFactory);

    function token() external view returns (address);

    function getReserves()
        external
        view
        returns (uint256 usdmReserves, uint256 tokenReserves);

    function liquidityOwned() external view returns (uint256);

    function invert(Decimal.D256 calldata price)
        external
        pure
        returns (Decimal.D256 memory);
}
