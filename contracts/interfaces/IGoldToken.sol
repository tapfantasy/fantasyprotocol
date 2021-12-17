// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOperators.sol";

interface IGoldToken is IERC20, IOperators {
    function mint(uint value) external;
    function burn(uint value) external;
}
