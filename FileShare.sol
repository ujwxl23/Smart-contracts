// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FileShare is ERC20, Ownable {

    constructor () ERC20("shareToken", "STK" ) {
         _mint(msg.sender, 50 * 10 ** decimals());
    }

    struct Request{
        string description;
        address payable reqProvider;
        uint256 needId;
    }
    mapping (uint=>Request) public requests;
    uint256 public ReqId;

    struct Provide{
        string description;
        string deviceName;
        address payable recipient;
        uint256 space;
        uint256 timestamp;
        bool engage;
    }
    mapping (uint256=>Provide) public providers;
    uint256 public ProId;

    function createProvide(string memory _description, string memory _deviceName, uint256 _space) public {
        Provide storage newProvide = providers[ProId];
        ProId++;
        newProvide.description=_description;
        newProvide.deviceName=_deviceName;
        newProvide.recipient=payable(msg.sender);
        newProvide.space=_space;
        newProvide.engage=false;
    }

    function makeRequestToProvider(uint256 _proId, uint256 _spaceReq, string  memory _description)public {
        // require(raisedAmt>=targetprice);
        Provide storage thisProvide=providers[_proId];
        require(thisProvide.space >= _spaceReq ,"The provider does not have enoungh space left.");
        require(thisProvide.engage==false,"The provider is already busy, no resources available.");
        thisProvide.engage=true;
        thisProvide.timestamp=block.timestamp;
        Request storage newRequest = requests[ReqId];
        ReqId++;
        newRequest.description=_description;
        newRequest.reqProvider=thisProvide.recipient;
        newRequest.needId=_proId;
    }

    // function finishUse();
    // function getAllAvailableDevice();
    // function approveRequestorUse();
    // function proStop();


}
