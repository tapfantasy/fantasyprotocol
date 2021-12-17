// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelinUpgrade/contracts/token/ERC721/IERC721Upgradeable.sol";

import "@openzeppelinUpgrade/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelinUpgrade/contracts/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelinUpgrade/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelinUpgrade/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelinUpgrade/contracts/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelinUpgrade/contracts/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelinUpgrade/contracts/security/ReentrancyGuardUpgradeable.sol";
import "../access/OperatorsUpgradeable.sol";

import "../interfaces/INFTAssets.sol";
import "../interfaces/INFTInGame.sol";
import "../interfaces/INFTMarket.sol";

contract NFTMarket is OperatorsUpgradeable, ERC721HolderUpgradeable, ReentrancyGuardUpgradeable, INFTMarket {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    MarketGoods[] public goods;
    OrderItem[] public items;
    address public feegather;

    uint256[50] private __gap;

    function initialize(address _feegather) external initializer {
        __Operators_init();
        feegather = _feegather;
    }

    function setFeeGather(address _feegather) external override onlyOwner {
        feegather = _feegather;
    }

    function getFeeGather() external view override returns (address) {
        return feegather;
    }

    function getMarketGoods(uint _goodsid) external view override returns (MarketGoods memory) {
        return goods[_goodsid];
    }

    function getMarketGoodsLength() external view override returns (uint) {
        return goods.length;
    }

    function getOrderItem(uint _orderid) external view override returns (OrderItem memory) {
        return items[_orderid];
    }

    function getOrderItemLength() external view override returns (uint) {
        return items.length;
    }

    function addGoods(address _payToken, address _itemNFT, address _itemToken, uint _feeRate) external override onlyOwner {
        require(_feeRate <= 1e9, 'rate!');

        uint tokenDecimals = 18;

        if(_itemNFT == address(0)) {
            require(_itemToken != address(0), 'Token!');
            tokenDecimals = IERC20MetadataUpgradeable(_itemToken).decimals();
        }else if(_itemToken == address(0)) {
            require(_itemNFT != address(0), 'NFT!');
            tokenDecimals = 18;
        }else {
            require(_itemToken != address(0) || _itemNFT != address(0), 'single!');
        }

        require(_payToken != address(0), 'pay!');
        uint payDecimals = IERC20MetadataUpgradeable(_payToken).decimals();

        goods.push(MarketGoods(
                _payToken, 
                _itemNFT,
                _itemToken,
                payDecimals,
                tokenDecimals,
                _feeRate, true));
        emit GoodsCreated(goods.length.sub(1), _payToken, _itemNFT, _itemToken, _feeRate, true);
    }

    function setGoods(uint _goodsid, uint _feeRate) external override onlyOwner {
        MarketGoods storage goodsItem = goods[_goodsid];
        require(goodsItem.feeRate <= 1e9, 'rate!');
        goodsItem.feeRate = _feeRate;
        emit GoodsChanged(_goodsid, _feeRate, goodsItem.available);
    }

    function setGoodsAvailable(uint _goodsid, bool _available) external override onlyOwner {
        MarketGoods storage goodsItem = goods[_goodsid];
        goodsItem.available = _available;
        emit GoodsChanged(_goodsid, goodsItem.feeRate, _available);
    }

    function onSell(address _user, uint _goodsid, uint _tokenIdOrAmount, uint _price) external override nonReentrant {
        require(_price >= 0, 'price!');
        MarketGoods storage goodsItem = goods[_goodsid];
        require(goodsItem.available, 'goods-available!');
        uint tokenId = 0;
        uint amount = 10**goodsItem.tokenDecimals;
        if(goodsItem.itemNFT == address(0)) {
            IERC20MetadataUpgradeable(goodsItem.itemToken).safeTransferFrom(msg.sender, address(this), _tokenIdOrAmount);
            amount = _tokenIdOrAmount;
        } else {
            require(goodsItem.itemToken == address(0), 'token!');
            IERC721Upgradeable(goodsItem.itemNFT).safeTransferFrom(msg.sender, address(this), _tokenIdOrAmount);
            tokenId = _tokenIdOrAmount;
        }
        items.push(OrderItem(
                _user,
                _goodsid,
                tokenId,
                amount,
                amount,
                _price,
                block.timestamp, 
                true));
        emit ItemOnSell(items.length.sub(1), _user, _goodsid, tokenId, amount, _price, block.timestamp);
    }

    function onBuy(uint _orderid, uint _amount, address _user) external override nonReentrant {
        OrderItem storage item = items[_orderid];
        require(item.available, 'available!');
        require(_amount > 0 && _amount <= item.stock, 'amount!');

        MarketGoods storage goodsItem = goods[item.goodsId];
        item.stock = item.stock.sub(_amount);
        if(item.stock <= 0) {
            item.available = false;
        }

        uint earnAmount = item.price.mul(_amount).div(10**goodsItem.tokenDecimals);
        uint feeAmount = earnAmount.mul(goodsItem.feeRate).div(1e9);
        earnAmount = earnAmount.sub(feeAmount);
        IERC20MetadataUpgradeable(goodsItem.payToken).safeTransferFrom(msg.sender, feegather, feeAmount);
        IERC20MetadataUpgradeable(goodsItem.payToken).safeTransferFrom(msg.sender, item.owner, earnAmount);

        if(address(goodsItem.itemNFT) == address(0)) {
            IERC20MetadataUpgradeable(goodsItem.itemToken).safeTransfer(_user, _amount);
        } else {
            IERC721Upgradeable(goodsItem.itemNFT).safeTransferFrom(address(this), _user, item.tokenId);
            require(item.stock == 0, 'stock!');
        }

        emit ItemOnBuy(_orderid, _user, item.goodsId, item.tokenId, _amount, earnAmount, feeAmount, block.timestamp);
    }

    function onCancel(uint _orderid, address _user) external override onlyOper nonReentrant {
        OrderItem storage item = items[_orderid];
        require(item.available, 'available!');
        item.available = false;

        MarketGoods storage goodsItem = goods[item.goodsId];
        require(item.owner == _user, 'user!');

        if(address(goodsItem.itemNFT) == address(0)) {
            IERC20MetadataUpgradeable(goodsItem.itemToken).safeTransfer(item.owner, item.stock);
        } else {
            IERC721Upgradeable(goodsItem.itemNFT).safeTransferFrom(address(this), item.owner, item.tokenId);
        }
        emit ItemOnCancel(_orderid, _user, item.goodsId, item.tokenId, item.stock, block.timestamp);
        item.stock = 0;
    }
}