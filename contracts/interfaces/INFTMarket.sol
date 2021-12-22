// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface INFTMarket {

    event GoodsCreated(uint _goodsid, address _payToken, address _itemNFT, address _itemToken, uint _feeRate, bool _available);
    event GoodsChanged(uint _goodsid, uint _feeRate, bool _available);
    event SetFeeGather(address _feegather);
    
    event ItemOnSell(uint _orderid, address indexed _user, uint _goodsid, uint _tokenId, uint _amount, uint _price, uint _timestamp);
    event ItemOnBuy(uint _orderid, address indexed _user, uint _goodsid, uint _tokenId, uint _amount, uint _pay, uint _fee, uint _timestamp);
    event ItemOnCancel(uint _orderid, address indexed _user, uint _goodsid, uint _tokenId, uint _amount, uint _timestamp);

    struct MarketGoods {
        address payToken;
        address itemNFT;
        address itemToken;
        uint payDecimals;
        uint tokenDecimals;
        uint feeRate;
        bool available;
    }

    struct OrderItem {
        address owner;
        uint goodsId;
        uint tokenId;
        uint stock;
        uint amount;
        uint price;
        uint timestamp;
        bool available;
    }

    function setFeeGather(address _feegather) external;
    function getFeeGather() external view returns (address);
    function getMarketGoods(uint _goodsid) external view returns (MarketGoods memory);
    function getMarketGoodsLength() external view returns (uint);
    function getOrderItem(uint _orderid) external view returns (OrderItem memory);
    function getOrderItemLength() external view returns (uint);

    function feegather() external view returns (address);

    function addGoods(address _payToken, address _itemNFT, address _itemToken, uint _feeRate) external;
    function setGoods(uint _goodsid, uint _feeRate) external;
    function setGoodsAvailable(uint _goodsid, bool _available) external;

    function onSell(address _user, uint _goodsid, uint _tokenIdOrAmount, uint _price) external;
    function onBuy(uint _orderid, uint _amount, address _user) external;
    function onCancel(uint _orderid, address _user) external;
}
