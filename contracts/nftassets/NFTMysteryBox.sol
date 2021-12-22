// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelinUpgrade/contracts/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelinUpgrade/contracts/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelinUpgrade/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelinUpgrade/contracts/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelinUpgrade/contracts/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelinUpgrade/contracts/security/ReentrancyGuardUpgradeable.sol";

import "../access/OperatorsUpgradeable.sol";
import "../interfaces/INFTAssets.sol";
import "../interfaces/INFTShop.sol";

contract NFTMysteryBox is OperatorsUpgradeable, ReentrancyGuardUpgradeable, INFTShop {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    ShopItem[] public items;
    address public override payToken;
    address public override obtainToken;
    mapping(uint=>uint) public flowEnd;

    address public feegather;

    uint256[50] private __gap;

    function initialize(address _payToken, address _obtainToken, address _feegather) external initializer {
        __Operators_init();

        feegather = _feegather;
        setTokens(_payToken, _obtainToken);
    }

    function setFeeGather(address _feegather) external override onlyOwner {
        require(_feegather != address(0), "_feeGather!");
        feegather = _feegather;
        emit SetFeeGather(feegather);
    }

    function setTokens(address _payToken, address _obtainToken) public override onlyOwner {
        require(_payToken != address(0), "_payToken!");
        require(_obtainToken != address(0), "_obtainToken!");
        payToken = _payToken;
        obtainToken = _obtainToken;
        emit SetTokens(payToken, obtainToken);
    }

    function addItem(uint typeid, uint price, uint stock) external override onlyOper {
        items.push(ShopItem(true, typeid, price, stock));
        emit ItemOnEdit(items.length.sub(1), true, typeid, price, stock, block.timestamp);
    }

    function enableItem(uint itemId, bool open) external override onlyOper {
        items[itemId].open = open;
        emit EnableItem(itemId, open);
    }

    function getItem(uint _itemId) external view override returns (ShopItem memory) {
        return items[_itemId];
    }

    function getItemLength() external view override returns (uint) {
        return items.length;
    }

    function onBuy(uint _itemId, address _user) external override nonReentrant {
        ShopItem storage item = items[_itemId];
        item.stock = item.stock.sub(1);
        IERC20Upgradeable(payToken).safeTransferFrom(msg.sender, feegather, item.price);
        emit ItemOnBuy(_user, _itemId, item.typeid, item.price, item.stock, block.timestamp);
    }

    function onObtain(uint flowid, address _user, uint256 _tokenId) external override onlyOper {
        require(flowEnd[flowid] == 0, 'flowEnd!');
        flowEnd[flowid] = _tokenId;
        INFTAssets(obtainToken).safeMint(_user, _tokenId);
        emit ItemOnObtain(_user, flowid, _tokenId, block.timestamp);
    }
}