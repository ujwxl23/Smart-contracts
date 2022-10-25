//SPDX-License-Identifier:MIT

// Get funds from user 
// Withdraw funds
// Set a minimum funding value


pragma solidity ^0.8.0;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe{
    using PriceConverter for uint256;


    address[] public funders;
    mapping(address=>uint256) public addressToAmountFunded;
    uint256 public constant MINIMUM_USD = 50*1e18;

    address public immutable i_owner;

    constructor(){
        i_owner=msg.sender;
    }

    function fund()public payable{        // Want to be able to setaminimum fund amount in USD
        // 1. How do we send ETH to this contract?
        //require(getConversionRate(msg.value)>1e18,"Didn't send enough!"); ............Before using library and all functions in same contract
        require(msg.value.getConversionRate()>=MINIMUM_USD,"Didn't send enough!");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender]=msg.value;
        }// 1e18 ==1*10 ** 18

    function withdraw() public onlyOwner {
        //require(owner==msg.sender,"sender is not owner!";) giving owner the functionality only or use modifier for multiple req.
        for(uint256 funderIndex=0; funderIndex<=funders.length; funderIndex){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder]=0;
        }
        // reset array from 0th element
        funders= new address[](0);

        //actually withdraw funds
        // 3 types- transfer,send,call

        //msg.sender = address type 
        //payable(msg.sender) = payable address type
        /*//transfer
        payable(msg.sender).transfer(address(this).balance);
        //send
        bool sendSuccess=payable(msg.sender).transfer(address(this).balance);
        require(sendSuccess,"send failed");*/
        //call
        (bool callSuccess,) = payable(msg.sender).call{value:address(this).balance}("");
        require (callSuccess,"call failed");
    }
    
    modifier onlyOwner {
        //require (msg.sender==owner,"sender not owner!");
        if (msg.sender!=i_owner){
            revert NotOwner();
        }
        _;
    }


}

