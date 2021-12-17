// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract mockToken is ERC20 {

    constructor(string memory _symbol)
        ERC20(_symbol, _symbol) {
    }

    function mint(uint value) external {
        _mint(msg.sender, value);
    }
    
    function burn(address _acct, uint value) external {
        _burn(_acct, value);
    }
}
