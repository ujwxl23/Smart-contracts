//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "./SimpleStorage.sol";

// 'is' --> used to make the new contract like the old old one. 
contract ExtraStorage is SimpleStorage{
    // to change existing function in parent contract we use keywords virtual and override.
    function store (uint256 _testnumber) public override{
        testnumber=_testnumber+5;
    }
}
