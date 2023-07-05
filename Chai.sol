// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";


contract chai{
    struct Memo{
        string name;
        string message;
        uint timestamp;
        address from;
    }

    Memo[] memos;
    address payable owner; //making owner as payable as we need to send ethers

    constructor(){
        owner=payable(msg.sender); //owner-> person who has made/depoyed the contract
    }

    function buyChai(string memory name,string memory message) public payable{ //first the user will write their name and a message and call buyChai function through a button
        require(msg.value>0,"Please pay greater than 0 ether"); //check for zero ether transfer 
        owner.transfer(msg.value);// transfer ether
        memos.push(Memo(name,message,block.timestamp,msg.sender));//putting these value in an array to show in website (used to display info on screen)
    }

    function getMemos() public view returns(Memo[] memory){ // view the the array of values 
        return memos;
    }
}

















// contract Lock {
//     uint public unlockTime;
//     address payable public owner;

//     event Withdrawal(uint amount, uint when);

//     constructor(uint _unlockTime) payable {
//         require(
//             block.timestamp < _unlockTime,
//             "Unlock time should be in the future"
//         );

//         unlockTime = _unlockTime;
//         owner = payable(msg.sender);
//     }

//     function withdraw() public {
//         // Uncomment this line, and the import of "hardhat/console.sol", to print a log in your terminal
//         // console.log("Unlock time is %o and block timestamp is %o", unlockTime, block.timestamp);

//         require(block.timestamp >= unlockTime, "You can't withdraw yet");
//         require(msg.sender == owner, "You aren't the owner");

//         emit Withdrawal(address(this).balance, block.timestamp);

//         owner.transfer(address(this).balance);
//     }
// }
