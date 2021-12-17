// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelinUpgrade/contracts/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelinUpgrade/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelinUpgrade/contracts/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelinUpgrade/contracts/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelinUpgrade/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelinUpgrade/contracts/security/ReentrancyGuardUpgradeable.sol";

import "../access/OperatorsUpgradeable.sol";
import "../interfaces/INFTAssets.sol";
import "../interfaces/INFTInGame.sol";

contract NFTInGame is OperatorsUpgradeable, ERC721HolderUpgradeable, ReentrancyGuardUpgradeable, INFTInGame {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint public override cooltime;
    address payable public override feeGather;
    uint public override feeAmount;
    address public override nftAssets;

    mapping(uint=>bool) public blacklist;
    
    mapping(uint=>uint) public tokenCoolTime;
    mapping(uint=>address) public tokenOutOwner;

    uint256[50] private __gap;

    function initialize(address _nftAssets) external initializer {
        __Operators_init();
        cooltime = 1 hours;
        nftAssets = _nftAssets;
    }
    
    function setBlacklist(uint[] memory _idlist, bool _enable) external override onlyOwner {
        for(uint i = 0; i < _idlist.length; i ++) {
            blacklist[_idlist[i]] = _enable;
        }
    }

    function setCoolTime(uint _cooltime) external override onlyOwner {
        cooltime = _cooltime;
    }

    function setFeeGather(address payable _feeGather, uint _feeAmount) external override onlyOwner {
        feeGather = _feeGather;
        feeAmount = _feeAmount;
    }

    function lockInGame(uint _tokenId, address _user) external override payable returns (bool) {
        require(msg.value >= feeAmount, 'fee!');
        feeGather.transfer(msg.value);
        IERC721Upgradeable(nftAssets).safeTransferFrom(msg.sender, address(this), _tokenId);
        if(tokenOutOwner[_tokenId] != _user) {
            require(block.timestamp > tokenCoolTime[_tokenId], 'in cool time');
        }
        require(!blacklist[_tokenId], 'in blacklist');

        emit TokenInGame(_user, _tokenId, true);
        return true;
    }

    function unlockFromGame(uint _tokenId, address _user) public override onlyOper returns (bool) {
        address owner = IERC721Upgradeable(nftAssets).ownerOf(_tokenId);
        require(owner == address(this), 'token not in hold');
        tokenCoolTime[_tokenId] = block.timestamp.add(cooltime);
        tokenOutOwner[_tokenId] = _user;
        require(!blacklist[_tokenId], 'in blacklist');
        IERC721Upgradeable(nftAssets).safeTransferFrom(address(this), _user, _tokenId);

        emit TokenOutGame(_user, _tokenId, false);
        return true;
    }

    function unlockFromGameBatch(uint[] memory _tokenId, address[] memory _user) external override onlyOper returns (bool) {
        require(_tokenId.length == _user.length, 'length!');
        for(uint i = 0; i < _tokenId.length; i ++) {
            unlockFromGame(_tokenId[i], _user[i]);
        }
        return true;
    }

    function resetCoolTime(uint _tokenId) external override onlyOper {
        tokenCoolTime[_tokenId] = 0;
    }

    function nftLevelUpBatch(uint[] memory _tokenId, uint[] memory _tokenNewId) external override onlyOper returns (bool) {
        require(_tokenId.length == _tokenNewId.length, 'length error');
        for(uint u = 0; u < _tokenId.length; u ++) {
            nftLevelUp(_tokenId[u], _tokenNewId[u]);
        }
        return true;
    }

    function nftLevelUp(uint _tokenId, uint _tokenNewId) public onlyOper returns (bool) {
        if(_tokenId > 0) {
            require(IERC721Upgradeable(nftAssets).ownerOf(_tokenId) == address(this), 'not hold');
            INFTAssets(nftAssets).burn(_tokenId);
        }
        if(_tokenNewId > 0) {
            INFTAssets(nftAssets).safeMint(address(this), _tokenNewId);
        }
        return true;
    }
}