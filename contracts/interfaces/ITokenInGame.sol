// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IOperators.sol";

interface ITokenInGame {

    event PushToGame(address _user, address _token, uint _value, uint _total);
    event PullFromGame(uint __serialid, address _user, address _token, uint _value, uint _total);

    function isEnabledToken(address _token) external view returns (bool);
    function setToken(address _token, bool _enable) external;
    
    function gameIn(address _token, address _user, uint _value) external;
    function gameOut(uint _serialid, address _token, address _user, uint _value) external;
    function gameOutBatch(uint[] memory _serialid, address[] memory _token, address[] memory _user, uint[] memory _value) external;
}
