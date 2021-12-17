// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../access/Operators.sol";

contract MCToken is ERC20, Operators {

    constructor() ERC20("Magic Crystal Coin", "MC") {
    }

    function mint(uint value) external onlyOper {
        _mint(msg.sender, value);
    }
    
    function burn(uint value) external onlyOper {
        _burn(msg.sender, value);
    }
}
