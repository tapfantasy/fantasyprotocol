// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./IOperators.sol";

interface INFTAssets is IOperators {

    function safeMint(address to, uint256 tokenId) external;
    function safeMintWithAttr(address to, uint256 tokenId, string[] memory attrname, uint[] memory avalue) external;
    
    function updateAttrs(uint256 tokenId, string[] memory attrname, uint[] memory avalue) external;
    function burn(uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}
