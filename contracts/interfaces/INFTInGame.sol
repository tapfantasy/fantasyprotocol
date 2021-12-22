// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IOperators.sol";

interface INFTInGame {
    event TokenInGame(address indexed _user, uint _tokenId, bool _b);
    event TokenOutGame(address indexed _user, uint _tokenId, bool _b);
    event SetBlacklist(uint _id, bool _enable);
    event SetCoolTime(uint _cooltime);
    event SetFeeGather(address _feeGather, uint _feeAmount);
    
    function cooltime() external view returns(uint);
    function nftAssets() external view returns(address);
    function feeGather() external view returns(address payable);
    function feeAmount() external view returns(uint);

    function setBlacklist(uint[] memory _idlist, bool _enable) external;
    function setCoolTime(uint _cooltime) external;
    function setFeeGather(address payable _feeGather, uint _feeAmount) external;

    function lockInGame(uint _tokenId, address _user) external payable returns (bool);
    function unlockFromGame(uint _tokenId, address _user) external returns (bool);
    function unlockFromGameBatch(uint[] memory _tokenId, address[] memory _user) external returns (bool);

    function resetCoolTime(uint _tokenId) external;
    function nftLevelUpBatch(uint[] memory _tokenId, uint[] memory _tokenNewId) external returns (bool);
    function nftLevelUp(uint _tokenId, uint _tokenNewId) external returns (bool);
}
