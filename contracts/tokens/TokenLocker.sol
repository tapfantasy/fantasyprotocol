// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelinUpgrade/contracts/security/ReentrancyGuardUpgradeable.sol";

import "../access/OperatorsUpgradeable.sol";
import "../interfaces/ITokenLocker.sol";

contract TokenLocker is OperatorsUpgradeable, ReentrancyGuardUpgradeable, ITokenLocker {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    ITokenMinter public override token;

    LockedItem[] public items;

    uint public feeRate;
    uint public feeLockTime;

    uint256[50] private __gap;

    constructor() {
    }

    function initialize(address _token) external initializer {
        __Operators_init();
        token = ITokenMinter(_token);
        feeLockTime = 7 days;
        feeRate = 3e8;
    }

    function setLockTimeRate(uint _feeLockTime, uint _feeRate) external override onlyOwner {
        feeLockTime = _feeLockTime;
        feeRate = _feeRate;
        require(feeRate < 1e9, '!feeRate');
    }

    function getLockTimeRate() external view override returns (uint, uint) {
        return (feeLockTime, feeRate);
    }

    function getItem(uint lid) external view override returns (LockedItem memory) {
        return items[lid];
    }

    function pending(uint lid) public view override returns (uint, uint) {
        LockedItem memory item = items[lid];
        if(item.unlocked) {
            return (0, 0);
        }
        uint unlocktime = item.timestamp.add(feeLockTime);
        if(unlocktime <= block.timestamp) {
            return (item.amount, 0);
        }
        uint fee = item.amount.mul(feeRate).mul(unlocktime.sub(block.timestamp)).div(feeLockTime).div(1e9);
        return (item.amount.sub(fee), fee);
    }

    function claimBatch(uint[] memory lid, address _touser) external override onlyOper {
        uint amount = 0;
        for(uint i = 0; i < lid.length; i ++) {
            require(!items[i].unlocked, 'released');
            require(items[i].user == _touser, 'user');
            (uint itemamount,) = pending(i);
            amount = amount.add(itemamount);
            items[i].unlocked = true;
            emit ClaimToken(items[i].sid, items[i].user, itemamount);
        }
        if(amount > 0) {
            token.mint(amount);
            token.transfer(_touser, amount);
        }
    }

    function gameOut(uint _serialid, address _user, uint _timestamp, uint _value) public override onlyOper {
        items.push(LockedItem(_serialid, _user, _value, _timestamp, false));
    }

    function gameOutBatch(uint[] memory _serialid, address[] memory _user, uint[] memory _timestamp, uint[] memory _value) external override onlyOper {
        require(_serialid.length == _user.length, 'length1!');
        require(_timestamp.length == _value.length, 'length2!');
        require(_user.length == _timestamp.length, 'length3!');
        for(uint i = 0; i < _serialid.length; i ++) {
            gameOut(_serialid[i], _user[i], _timestamp[i], _value[i]);
        }
    }
}
