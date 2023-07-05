 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
 import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

 contract APYToken is ERC20{
    constructor() ERC20("APY", "Stacking Testing ") {
 // Create an initial value for the runner of the contract
        _mint(msg.sender, 50 * 10 ** decimals());
    }
 }