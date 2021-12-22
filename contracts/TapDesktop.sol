// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/INFTMarket.sol";
import "./interfaces/INFTShop.sol";
import "./interfaces/IGoldTreasury.sol";
import "./interfaces/INFTInGame.sol";
import "./interfaces/ITokenInGame.sol";
import "./interfaces/ITokenLocker.sol";
import "./interfaces/IWETH.sol";

contract TapDesktop is Ownable, ERC721Holder {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    INFTShop public box;
    INFTMarket public market;
    INFTShop public shop;
    
    IGoldTreasury public goldPool;
    INFTInGame public nftInGame;
    ITokenInGame public tokenInGame;
    ITokenLocker public tokenLocker;
    IWETH public iweth;
    
    fallback() external payable {
    }

    receive() external payable {
    }

    constructor(address _box, address _shop, address _market, address _goldpool,
        address _nftingame, address _tokeningame, address _tokenLocker, address _iweth) {
        box = INFTShop(_box);
        shop = INFTShop(_shop);
        market = INFTMarket(_market);
        goldPool = IGoldTreasury(_goldpool);
        nftInGame = INFTInGame(_nftingame);
        tokenInGame = ITokenInGame(_tokeningame);
        tokenLocker = ITokenLocker(_tokenLocker);
        iweth = IWETH(_iweth);
    }

    function nftBuy(INFTShop _shop, uint _itemId, bool bETH) internal {
        IERC20 payToken = IERC20(_shop.payToken());
        INFTShop.ShopItem memory item = _shop.getItem(_itemId);
        require(item.price > 0, 'price error');
        if(bETH) {
            require(msg.value >= item.price, 'price!');  
            iweth.deposit{value:msg.value}();
        }else{
            payToken.safeTransferFrom(msg.sender, address(this), item.price);
        }
        payToken.approve(address(_shop), item.price);
        _shop.onBuy(_itemId, msg.sender);
    }

    // for mystery box 
    function mysteryBoxOpen(uint _boxid) external {
        nftBuy(box, _boxid, false);
    }

    function mysteryBoxOpenETH(uint _boxid) external payable {
        nftBuy(box, _boxid, true);
    }

    // for shop
    function shopBuy(uint _itemId) external {
        nftBuy(shop, _itemId, false);
    }

    // for shop
    function shopBuyETH(uint _itemId) external payable {
        nftBuy(shop, _itemId, true);
    }

    // for market place
    function marketSell(uint _goodsid, uint _tokenIdOrAmount, uint _price) external {
        INFTMarket.MarketGoods memory goods = market.getMarketGoods(_goodsid);

        if(goods.itemNFT == address(0)) {
            IERC20(goods.itemToken).safeTransferFrom(msg.sender, address(this), _tokenIdOrAmount);
            IERC20(goods.itemToken).approve(address(market), _tokenIdOrAmount);
        } else {
            IERC721(goods.itemNFT).safeTransferFrom(msg.sender, address(this), _tokenIdOrAmount);
            IERC721(goods.itemNFT).approve(address(market), _tokenIdOrAmount);
        }
        market.onSell(msg.sender, _goodsid, _tokenIdOrAmount, _price);
    }

    function marketBuy(uint _orderId, uint _amount) external {
        INFTMarket.OrderItem memory item = market.getOrderItem(_orderId);
        INFTMarket.MarketGoods memory goods = market.getMarketGoods(item.goodsId);
        require(item.price > 0, 'price!');
        uint payAmount = item.price.mul(_amount).div(10**goods.tokenDecimals);
        IERC20(goods.payToken).safeTransferFrom(msg.sender, address(this), payAmount);
        IERC20(goods.payToken).approve(address(market), payAmount);
        market.onBuy(_orderId, _amount, msg.sender);
    }

    function marketCancel(uint _orderId) external {
        market.onCancel(_orderId, msg.sender);
    }

    // for gold Staking
    function goldMint(uint value, bool toGame) external returns (uint amount) {
        (address t1, address t2) = goldPool.getTokens();
        (IERC20 cashToken, IERC20 goldToken) = (IERC20(t1), IERC20(t2));
        cashToken.safeTransferFrom(msg.sender, address(this), value);
        cashToken.approve(address(goldPool), value);
        if(toGame) {
            amount = goldPool.mint(value, address(this));
            goldToken.approve(address(tokenInGame), amount);
            tokenInGame.gameIn(address(goldToken), msg.sender, amount);
        } else {
            goldPool.mint(value, msg.sender);
        }
    }
    
    function goldBurn(uint value) external returns (uint amount) {
        (address t1, address t2) = goldPool.getTokens();
        (, IERC20 goldToken) = (IERC20(t1), IERC20(t2));
        goldToken.safeTransferFrom(msg.sender, address(this), value);
        goldToken.approve(address(goldPool), value);
        return goldPool.burn(value, msg.sender);
    }

    // nft or token push to game
    function gameNFTIn(uint _tokenId) external payable {
        IERC721 nftToken = IERC721(nftInGame.nftAssets());
        nftToken.safeTransferFrom(msg.sender, address(this), _tokenId);
        nftToken.approve(address(nftInGame), _tokenId);
        nftInGame.lockInGame{value:msg.value}(_tokenId, msg.sender);
    }

    function gameTokenIn(address _token, uint _amount) external {
        require(tokenInGame.isEnabledToken(_token), 'enable!');
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(_token).approve(address(tokenInGame), _amount);
        tokenInGame.gameIn(_token, msg.sender, _amount);
    }

    // MagicCrystal out game
    function gameTokenOut(uint[] memory lid) external {
        tokenLocker.claimBatch(lid, msg.sender);
    }
}