// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IOperators.sol";


interface ITokenMinter is IERC20 {
    function mint(uint value) external;
}

interface ITokenLocker {

    event PushToGame(address _user, address _token, uint _value, uint _total);
    event PullFromGame(uint __serialid, address _user, address _token, uint _value, uint _total);
    event ClaimToken(uint __serialid, address _user, uint _value);

    struct LockedItem {
        uint sid;
        address user;
        uint amount;
        uint timestamp;
        bool unlocked;
    }

    function token() external view returns (ITokenMinter);
    function pending(uint lid) external view returns (uint, uint);
    function getItem(uint lid) external view returns (LockedItem memory);
    function getLockTimeRate() external view returns (uint, uint);

    function setLockTimeRate(uint _feeLockTime, uint _feeRate) external;
    function claimBatch(uint[] memory lid, address _touser) external;
    function gameOut(uint _serialid, address _user, uint _timestamp, uint _value) external;
    function gameOutBatch(uint[] memory _serialid, address[] memory _user, uint[] memory _timestamp, uint[] memory _value) external;
}
