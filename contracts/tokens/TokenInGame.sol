// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelinUpgrade/contracts/security/ReentrancyGuardUpgradeable.sol";

import "../access/OperatorsUpgradeable.sol";
import "../interfaces/ITokenInGame.sol";

contract TokenInGame is OperatorsUpgradeable, ReentrancyGuardUpgradeable, ITokenInGame {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    mapping(address=>bool) public enabled;

    uint256[50] private __gap;

    constructor() {
    }

    function initialize(address[] memory _token) external initializer {
        __Operators_init();
        for(uint u = 0; u < _token.length; u ++) {
            setToken(_token[u], true);
        }
    }

    function setToken(address _token, bool _enable) public override onlyOper {
        enabled[_token] = _enable;
        emit SetToken(_token, _enable);
    }

    function isEnabledToken(address _token) external view override returns (bool) {
        return enabled[_token];
    }

    function gameIn(address _token, address _user, uint _value) external override {
        require(enabled[_token], 'token!');
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _value);
        uint amount = IERC20(_token).balanceOf(address(this));
        emit PushToGame(_user, _token, _value, amount);
    }

    function gameOut(uint _serialid, address _token, address _user, uint _value) public override onlyOper {
        require(enabled[_token], 'token!');
        IERC20(_token).safeTransfer(_user, _value);
        uint amount = IERC20(_token).balanceOf(address(this));
        emit PullFromGame(_serialid, _user, _token, _value, amount);
    }

    function gameOutBatch(uint[] memory _serialid, address[] memory _token, address[] memory _user, uint[] memory _value) external override onlyOper {
        require(_serialid.length == _token.length, 'length1!');
        require(_user.length == _value.length, 'length2!');
        require(_user.length == _token.length, 'length3!');
        for(uint i = 0; i < _serialid.length; i ++) {
            gameOut(_serialid[i], _token[i], _user[i], _value[i]);
        }
    }
}
