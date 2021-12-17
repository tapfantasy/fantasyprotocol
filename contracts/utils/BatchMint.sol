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

import "../interfaces/INFTAssets.sol";

contract BatchMint is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function mint(address _token, uint[] memory _itemId, address _to) external onlyOwner {
        for(uint i = 0; i < _itemId.length; i ++) {
            INFTAssets(_token).safeMint(_to, _itemId[i]);
        }
    }
}