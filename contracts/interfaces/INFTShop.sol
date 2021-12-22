// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelinUpgrade/contracts/token/ERC721/IERC721Upgradeable.sol";

interface INFTShop {

    event ItemOnEdit(uint _itemId, bool _open, uint _itemid, uint _price, uint _stock, uint _timestamp);
    event ItemOnBuy(address indexed _user, uint _itemId, uint _typeid, uint _price, uint _stock, uint _timestamp);
    event ItemOnObtain(address indexed _user, uint flowid, uint _tokenId, uint _timestamp);
    event SetFeeGather(address _feegather);
    event SetTokens(address _payToken, address _obtainToken);
    event EnableItem(uint itemId, bool open);

    struct ShopItem {
        bool open;
        uint typeid;
        uint price;
        uint stock;
    }

    function payToken() external view returns (address);
    function obtainToken() external view returns (address);
    function getItem(uint) external view returns (ShopItem memory);
    function getItemLength() external view returns (uint);

    function addItem(uint typeid, uint price, uint stock) external;
    function enableItem(uint itemId, bool open) external;

    function setFeeGather(address _feegather) external;
    function setTokens(address _payToken, address _obtainToken) external;

    function onBuy(uint _orderid, address _user) external;
    function onObtain(uint flowid, address _user, uint256 _tokenId) external;
}
