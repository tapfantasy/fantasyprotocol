// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelinUpgrade/contracts/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelinUpgrade/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelinUpgrade/contracts/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelinUpgrade/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelinUpgrade/contracts/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelinUpgrade/contracts/security/ReentrancyGuardUpgradeable.sol";
import "../access/OperatorsUpgradeable.sol";

import "../interfaces/IGoldTreasury.sol";
import "../interfaces/IGoldToken.sol";
import "../interfaces/ICompCToken.sol";

contract GoldTreasury is OperatorsUpgradeable, ReentrancyGuardUpgradeable {

    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    IERC20Upgradeable public tokenCash;
    IERC20Upgradeable public tokenGold;
    address public invest;

    uint public feerate;
    address public feegather;

    struct LockItem {
        uint unlocktime;
        uint amount;
        bool unlocked;
    }
    uint immutable public exchangeRate = 10;

    uint256[50] private __gap;

    constructor() {
    }

    function initialize(address _tokenCash, address _tokenGold, address _feegather, uint _feerate) external initializer {
        __Operators_init();
        feegather = msg.sender;
        setTokens(_tokenCash, _tokenGold);
        feegather = _feegather;
        feerate = _feerate;
    }

    function setFeeGather(address _feegather) external onlyOwner {
        feegather = _feegather;
    }

    function setFeeRate(uint _feerate) external onlyOwner {
        feerate = _feerate;
    }

    function setInvest(address _invest) external onlyOwner {
        invest = _invest;
    }

    function setTokens(address _tokenCash, address _tokenGold) public onlyOwner {
        tokenCash = IERC20Upgradeable(_tokenCash);
        tokenGold = IERC20Upgradeable(_tokenGold);
    }

    function getTokens() public view returns (address _tokenCash, address _tokenGold) {
        _tokenCash = address(tokenCash);
        _tokenGold = address(tokenGold);
    }

    function mint(uint _value, address _to) external onlyOper nonReentrant returns (uint) {
        tokenCash.safeTransferFrom(msg.sender, address(this), _value);
        uint goldAmount = _value.mul(exchangeRate);
        IGoldToken(address(tokenGold)).mint(goldAmount);
        tokenGold.safeTransfer(_to, goldAmount);
        if(invest != address(0)) {
            tokenCash.approve(address(invest), _value);
            uint code = ICompCToken(invest).mint(_value);
            require(code == 0, 'mint error');
        }
        return goldAmount;
    }
    
    function burn(uint _value, address _to) external onlyOper nonReentrant returns (uint) {
        tokenGold.safeTransferFrom(msg.sender, address(this), _value);
        IGoldToken(address(tokenGold)).burn(_value);
        uint cashAmount = _value.div(exchangeRate);
        
        if(tokenCash.balanceOf(address(this)) < cashAmount && invest != address(0)) {
            uint code = ICompCToken(invest).redeemUnderlying(cashAmount.sub(tokenCash.balanceOf(address(this))));
            require(code == 0, 'redeem error');
        }

        uint feeamount = cashAmount.mul(feerate).div(1e9);
        tokenCash.safeTransfer(feegather, feeamount);
        tokenCash.safeTransfer(_to, cashAmount.sub(feeamount));
        return cashAmount.sub(feeamount);
    }

    function claimRewards(address _user) external onlyOper nonReentrant returns (uint value) {
        uint amount = tokenCash.balanceOf(address(this));
        uint total = tokenGold.totalSupply().div(exchangeRate);
        value = ICompCToken(invest).balanceOfUnderlying(address(this)).add(amount).sub(total);
        if(value > 0) {
            uint goldAmount = value.mul(exchangeRate);
            IGoldToken(address(tokenGold)).mint(goldAmount);
            tokenGold.safeTransfer(_user, goldAmount);
        }
    }
}
