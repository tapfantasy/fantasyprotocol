// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IOperators.sol";

interface IGoldTreasury is IOperators {
    function getTokens() external view returns (address _tokenCash, address _tokenGold);
    function setTokens(address _tokenCash, address _tokenGold) external;

    function setFeeGather(address _feegather) external;
    function setFeeRate(uint _feerate) external;
    function setInvest(address _invest) external;

    function mint(uint _value, address _to) external returns (uint);
    function burn(uint _value, address _to) external returns (uint);

    function claimRewards(address _user) external returns (uint value);
    function claim(address _user) external returns (uint);
}
