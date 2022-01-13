// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// Inspired by OpenZeppelin TokenTimelock contract
// Reference: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/TokenTimelock.sol

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Timed.sol";
import "../interfaces/ILinearTokenTimelock.sol";

abstract contract LinearTokenTimelock is ILinearTokenTimelock, Timed {
    using SafeMath for uint256;

    /// @notice ERC20 basic token contract being held in timelock
    IERC20 public override lockedToken;

    /// @notice Beneficiary of tokens after they are released
    address public override beneficiary;

    /// @notice Pending beneficiary appointed by current beneficiary
    address public override pendingBeneficiary;

    /// @notice Initial balance of lockedToken
    uint256 public override initialBalance;

    uint256 internal _lastBalance;

    constructor(
        address _beneficiary,
        uint256 _startTime,
        uint256 _duration,
        address _lockedToken
    ) Timed(_duration) {
        require(
            _duration != 0,
            "LinearTokenTimelock::constructor: Duration is 0"
        );
        require(
            _beneficiary != address(0),
            "LinearTokenTimelock::constructor: Beneficiary must not be 0 address"
        );

        beneficiary = _beneficiary;

        _setLockedToken(_lockedToken);
        _initTimed(_startTime);
    }

    function updateBalance() external override balanceCheck {}

    // Prevents incoming LP tokens from messing up calculations
    modifier balanceCheck() {
        if (totalToken() > _lastBalance) {
            uint256 delta = totalToken().sub(_lastBalance);
            initialBalance = initialBalance.add(delta);
        }
        _;
        _lastBalance = totalToken();
    }

    modifier onlyBeneficiary() {
        require(
            msg.sender == beneficiary,
            "LinearTokenTimelock::onlyBeneficiary: Caller is not a beneficiary"
        );
        _;
    }

    /// @notice Releases `amount` unlocked tokens to address `to`
    function release(address to, uint256 amount) external virtual override;

    /// @notice Releases maximum unlocked tokens to address `to`
    function releaseMax(address to)
        external
        override
        onlyBeneficiary
        balanceCheck
    {
        _release(to, availableForRelease());
    }

    /// @notice The total amount of tokens held by timelock
    function totalToken() public view virtual override returns (uint256) {
        return lockedToken.balanceOf(address(this));
    }

    /// @notice Amount of tokens released to beneficiary
    function alreadyReleasedAmount() public view override returns (uint256) {
        return initialBalance.sub(totalToken());
    }

    /// @notice Amount of held tokens unlocked and available for release
    function availableForRelease()
        public
        view
        virtual
        override
        returns (uint256);

    /// @notice Current beneficiary can appoint new beneficiary, which must be accepted
    function setPendingBeneficiary(address _pendingBeneficiary)
        public
        override
        onlyBeneficiary
    {
        pendingBeneficiary = _pendingBeneficiary;
        emit PendingBeneficiaryUpdate(_pendingBeneficiary);
    }

    /// @notice Pending beneficiary accepts new beneficiary
    function acceptBeneficiary() public virtual override {
        _setBeneficiary(msg.sender);
    }

    function _setBeneficiary(address newBeneficiary) internal {
        require(
            newBeneficiary == pendingBeneficiary,
            "LinearTokenTimelock::_setBeneficiary: Caller is not pending beneficiary"
        );
        beneficiary = newBeneficiary;
        emit BeneficiaryUpdate(newBeneficiary);
        pendingBeneficiary = address(0);
    }

    function _setLockedToken(address tokenAddress) internal {
        lockedToken = IERC20(tokenAddress);
    }

    function _release(address to, uint256 amount) internal {
        require(
            lockedToken.transfer(to, amount),
            "LinearTokenTimelock::_release: Transfer failed"
        );
        emit Release(beneficiary, to, amount);
    }
}
