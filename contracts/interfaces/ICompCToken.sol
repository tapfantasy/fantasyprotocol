// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.6.0;

interface ICompCToken {
    function comptroller() external view returns(address);
    function underlying() external view returns(address);

    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function liquidateBorrow(address borrower, uint repayAmount, address vTokenCollateral) external returns (uint);

    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
}
