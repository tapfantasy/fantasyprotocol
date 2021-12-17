// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../access/Operators.sol";

contract TapToken is ERC20, Operators {

    constructor() ERC20("TAP Coin", "TAP") {
    }

    function mint(uint value) external onlyOper {
        _mint(msg.sender, value);
        require(totalSupply() <= 1e27, 'total!');
    }

    function burn(uint value) external onlyOper {
        _burn(msg.sender, value);
    }
}

