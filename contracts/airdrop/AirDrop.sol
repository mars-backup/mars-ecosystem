// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../refs/CoreRef.sol";

contract AirDrop is CoreRef {
    event Claim(address indexed _to, uint256 _amount);
    struct AirDropStatus {
        bool claimed;
        uint256 amount;
    }
    mapping(address => AirDropStatus) public userClaimed;
    address public devAddress;
    uint256 public beginBlock;
    uint256 public endBlock;

    constructor(
        address _core,
        address _devAddress,
        uint256 _beginBlock,
        uint256 _endBlock
    ) CoreRef(_core) {
        require(
            _endBlock > _beginBlock,
            "AirDrop::constructor: End block early"
        );
        beginBlock = _beginBlock;
        endBlock = _endBlock;
        devAddress = _devAddress;
    }

    modifier onlyDuration() {
        require(block.number < endBlock, "AirDrop::onlyDuration: Ended");
        _;
    }

    function claim() public onlyDuration {
        require(block.number >= beginBlock, "AirDrop::claim: Not begin");
        AirDropStatus memory airDropStatus = userClaimed[msg.sender];
        require(!airDropStatus.claimed, "AirDrop::claim: Has claimed");
        userClaimed[msg.sender].claimed = true;
        xms().transfer(msg.sender, airDropStatus.amount);
        emit Claim(msg.sender, airDropStatus.amount);
    }

    function addList(address[] memory _accounts, uint256 _amount)
        public
        onlyGovernor
        onlyDuration
    {
        for (uint256 i; i < _accounts.length; i++) {
            if (!userClaimed[_accounts[i]].claimed) {
                userClaimed[_accounts[i]].amount = _amount;
            }
        }
    }

    function recover() public onlyGovernor {
        require(block.number >= endBlock, "AirDrop::recover: Not end");
        uint256 amount = xmsBalance();
        xms().transfer(devAddress, amount);
        selfdestruct(payable(devAddress));
    }
}
