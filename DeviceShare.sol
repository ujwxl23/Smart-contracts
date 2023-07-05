// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DeviceShare {
    uint256 public FIXED_STAKE;
    uint256 private constant SECONDS_IN_YEAR = 31536000; // Number of seconds in a year (365 days)
    address private owner;

    IERC20 private token;

    constructor(address tokenAddress, uint256 _FIXED_STAKE) {
        token = IERC20(tokenAddress);
        owner = msg.sender;
        FIXED_STAKE = _FIXED_STAKE;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }
    struct Provide {
        string[] description;
        uint256[] space;
        uint256[] hrs;
        uint256[] tokenRate;
        uint256[] devid;
        bool[] engage;
        address payable recipient;
        uint256[] stakeids;
        uint256[] reqDetailsPerDevice;
    }

    struct DeviceDetails {
        string description;
        uint256 space;
        uint256 hrs;
        uint256 tokenRate;
        uint256 devid;
        bool engage;
        address payable recipient;
        uint256[] requestIDs;
        uint256[] requestHRs;
        uint256 finalRequestID;
        uint256 timestamp;
        uint256 stakeid;
    }
    mapping(address => Provide) public providers;
    mapping(uint256 => DeviceDetails) public deviceDetails;

    uint256 public deviceID;

    uint256 stake_id;

    struct Stake {
        uint256 stakeId;
        uint256 amt;
        uint256 timeStake;
    }
    mapping(address => uint256) private stakes_count;
    mapping(address => uint256) private rewards_earned;
    mapping(address => mapping(uint256 => Stake)) private stakes_pool;

    string[] allDevices;
    uint256[] spaceDevices;
    uint256[] hrsDevices;
    uint256[] tokenrateDevices;
    uint256[] deviceidDevices;

    event DeviceAdded(uint256 indexed idOfDevice, uint256 indexed idOfStake);

    function addDevice(
        string memory _description,
        uint256 _space,
        uint256 _hrs,
        uint256 _tokenrate
    ) public {
        Provide storage newProvide = providers[msg.sender];
        newProvide.description.push(_description);
        newProvide.space.push(_space);
        newProvide.hrs.push(_hrs);
        newProvide.engage.push(false);
        newProvide.recipient = payable(msg.sender);
        newProvide.tokenRate.push(_tokenrate);

        allDevices.push(_description);
        spaceDevices.push(_space);
        hrsDevices.push(_hrs);
        tokenrateDevices.push(_tokenrate);

        ++deviceID;
        DeviceDetails storage newDevice = deviceDetails[deviceID];
        newDevice.description = _description;
        newDevice.space = _space;
        newDevice.hrs = _hrs;
        newDevice.engage = false;
        newDevice.recipient = payable(msg.sender);
        newDevice.devid = deviceID;
        newDevice.tokenRate = _tokenrate;

        newProvide.devid.push(deviceID);
        deviceidDevices.push(deviceID);

        require(
            token.transferFrom(msg.sender, address(this), FIXED_STAKE),
            "Stake transfer failed"
        );

        stake_id = ++stakes_count[msg.sender];

        stakes_pool[msg.sender][stake_id] = Stake(
            stake_id,
            FIXED_STAKE,
            block.timestamp
        );

        newProvide.stakeids.push(stake_id);
        newDevice.stakeid = stake_id;

        emit DeviceAdded(deviceID, stake_id);
    }

    function getAllDevices()
        public
        view
        returns (
            string[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        return (
            allDevices,
            spaceDevices,
            hrsDevices,
            tokenrateDevices,
            deviceidDevices
        );
    }

    function getDeviceByProvider()
        public
        view
        returns (
            string[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        Provide storage thisProvide = providers[msg.sender];
        return (
            thisProvide.description,
            thisProvide.devid,
            thisProvide.hrs,
            thisProvide.space,
            thisProvide.tokenRate
        );
    }

    function getDeviceByDeviceID(
        uint256 _deviceID
    ) public view returns (string memory, uint256, uint256, uint256, bool) {
        DeviceDetails storage thisDevice = deviceDetails[_deviceID];
        return (
            thisDevice.description,
            thisDevice.hrs,
            thisDevice.space,
            thisDevice.tokenRate,
            thisDevice.engage
        );
    }

    function compare(
        string memory str1,
        string memory str2
    ) public pure returns (bool) {
        if (bytes(str1).length != bytes(str2).length) {
            return false;
        }
        return
            keccak256(abi.encodePacked(str1)) ==
            keccak256(abi.encodePacked(str2));
    }

    function removeDevice(uint256 _deviceID) public {
        DeviceDetails storage thisDevice = deviceDetails[_deviceID];
        Provide storage thisProvide = providers[thisDevice.recipient];
        require(thisDevice.engage == false, "The device is already engaged");
        require(stakes_count[msg.sender] > 0, "No stake found");
        require(
            block.timestamp >
                stakes_pool[msg.sender][thisDevice.stakeid].timeStake,
            "Time period has not elapsed."
        );
        require(
            stakes_pool[msg.sender][thisDevice.stakeid].amt > 0,
            "Reward alredy withdrawn"
        );
        require(
            thisDevice.recipient == msg.sender,
            "You are not the owner of the device."
        );

        for (uint256 j = 0; j < allDevices.length; j++) {
            bool same = compare(thisDevice.description, allDevices[j]);
            if (same == true) {
                delete allDevices[j];
                delete hrsDevices[j];
                delete spaceDevices[j];
                delete tokenrateDevices[j];
                delete deviceidDevices[j];
            }
        }

        for (uint256 i = 0; i < (thisProvide.description).length; i++) {
            bool sameName = compare(
                thisDevice.description,
                thisProvide.description[i]
            );
            if (sameName == true) {
                thisProvide.description[i] = " ";
                thisProvide.hrs[i] = 0;
                thisProvide.recipient = payable(address(0));
                thisProvide.space[i] = 0;
                thisProvide.tokenRate[i] = 0;
            }
        }

        thisDevice.description = " ";
        thisDevice.hrs = 0;
        thisDevice.recipient = payable(address(0));
        thisDevice.space = 0;
        thisDevice.tokenRate = 0;

        require(
            token.transfer(msg.sender, FIXED_STAKE),
            "Stake transfer failed"
        );

        stakes_pool[msg.sender][thisDevice.stakeid] = Stake(
            thisDevice.stakeid,
            0,
            block.timestamp
        );
    }

    struct Request {
        uint256 reqID;
        uint256 devID;
        address deviceOwner;
        uint256 hrsStake;
        bool engage;
        address reqAddress;
        uint256 req_creation_timestamp;
        uint256 req_accept_timestamp;
        uint256[] paid_tokens_array;
        uint256[] paid_token_timestamps;
        bool request_end;
    }
    mapping(uint256 => Request) public requests;
    uint256 public requestID;

    struct Requestor {
        uint256[] reqIDs;
        address requestorAddress;
        uint256 paidTokensTotal;
    }
    mapping(address => Requestor) public requestors;

    event RequestAdded(uint256 indexed idOfRequest);

    function RequestDeviceUse(uint256 _deviceID, uint256 _hrsToStake) public {
        DeviceDetails storage thisDevice = deviceDetails[_deviceID];
        require(thisDevice.engage == false, "The device is already engaged");
        ++requestID;
        Request storage newRequest = requests[requestID];
        newRequest.reqID = requestID;
        newRequest.devID = _deviceID;
        newRequest.deviceOwner = thisDevice.recipient;
        newRequest.hrsStake = _hrsToStake;
        newRequest.engage = false;
        newRequest.reqAddress = msg.sender;
        newRequest.req_creation_timestamp = block.timestamp;
        newRequest.request_end = false;

        Requestor storage newRequestor = requestors[msg.sender];
        newRequestor.reqIDs.push(requestID);
        newRequestor.requestorAddress = msg.sender;
        newRequestor.paidTokensTotal = _hrsToStake * thisDevice.tokenRate;

        thisDevice.requestIDs.push(requestID);
        thisDevice.requestHRs.push(_hrsToStake);

        Provide storage thisProvide = providers[thisDevice.recipient];
        thisProvide.reqDetailsPerDevice.push(_deviceID);
        thisProvide.reqDetailsPerDevice.push(requestID);
        thisProvide.reqDetailsPerDevice.push(_hrsToStake);

        emit RequestAdded(requestID);
    }

    uint256[] viewDetailsForProvider;

    function ViewDeviceRequestByRequestor()
        public
        view
        returns (uint256[] memory)
    {
        Provide storage thisProvide = providers[msg.sender];
        return (thisProvide.reqDetailsPerDevice);
    }

    function AcceptDeviceRequestByProvider(uint256 _reqID) public {
        Provide storage thisProvide = providers[msg.sender];
        Request storage thisRequest = requests[_reqID];
        for (uint256 i = 0; i < (thisProvide.devid).length; i++) {
            if (thisProvide.devid[i] == thisRequest.devID) {
                require(
                    thisProvide.engage[i] == false,
                    "The provider is already busy, no resources available."
                );
                thisProvide.engage[i] = true;
                thisRequest.engage = true;
                thisRequest.paid_tokens_array.push(0);
                thisRequest.paid_token_timestamps.push(block.timestamp);
            }
        }

        DeviceDetails storage thisDevice = deviceDetails[thisRequest.devID];
        thisDevice.finalRequestID = _reqID;
        thisDevice.timestamp = block.timestamp;
        thisDevice.engage = true;

        thisRequest.req_accept_timestamp = block.timestamp;

        token.transferFrom(
            thisRequest.reqAddress,
            address(this),
            thisDevice.tokenRate * thisRequest.hrsStake
        );
    }

    event EarnedRewardByProvider(uint256 indexed Reward);

    function TransferEarnedTokenToProvider(
        uint256 _deviceid,
        uint256 _requestID
    ) public payable {
        Request storage thisRequest = requests[_requestID];
        DeviceDetails storage thisDevice = deviceDetails[_deviceid];
        uint256 lastOfTimestampArry = (thisRequest.paid_token_timestamps)
            .length - 1;
        uint256 timeElapsed = block.timestamp -
            thisRequest.paid_token_timestamps[lastOfTimestampArry];
        uint256 noOfHours = timeElapsed / 3600;
        uint256 reward = noOfHours * thisDevice.tokenRate;

        token.transfer(msg.sender, reward);

        thisRequest.paid_tokens_array.push(reward);
        thisRequest.paid_token_timestamps.push(block.timestamp);

        Requestor storage thisRequestor = requestors[thisRequest.reqAddress];
        thisRequestor.paidTokensTotal = thisRequestor.paidTokensTotal - reward;

        emit EarnedRewardByProvider(reward);
    }

    function TransferTokenToProviderInternal(
        uint256 _deviceid,
        address _provider,
        uint256 _requestid
    ) public payable returns (uint256 Reward) {
        Provide storage thisProvide = providers[_provider];
        DeviceDetails storage thisDevice = deviceDetails[_deviceid];
        Request storage thisRequest = requests[_requestid];
        for (uint256 i = 0; i < (thisProvide.stakeids).length; i++) {
            if (thisProvide.stakeids[i] == thisDevice.stakeid) {
                uint256 amount = stakes_pool[_provider][thisDevice.stakeid].amt;
                uint256 lastOfTimestampArry = (
                    thisRequest.paid_token_timestamps
                ).length - 1;
                uint256 timeElapsed = block.timestamp -
                    thisRequest.paid_token_timestamps[lastOfTimestampArry];
                uint256 noOfHours = timeElapsed / 3600;
                uint256 reward = amount + (noOfHours * thisDevice.tokenRate);

                token.transfer(_provider, reward);

                rewards_earned[_provider] = reward;
                stakes_pool[_provider][thisDevice.stakeid] = Stake(
                    thisDevice.stakeid,
                    0,
                    block.timestamp
                );

                Requestor storage thisRequestor = requestors[
                    thisRequest.reqAddress
                ];
                thisRequestor.paidTokensTotal =
                    thisRequestor.paidTokensTotal -
                    (noOfHours * thisDevice.tokenRate);

                thisRequest.paid_tokens_array.push(
                    noOfHours * thisDevice.tokenRate
                );
                thisRequest.paid_token_timestamps.push(block.timestamp);

                return (reward);
            }
        }
    }

    function TransferTokenFromRequestorInternal(
        uint256 _requestorID
    ) public payable returns (uint256) {
        Request storage thisRequest = requests[_requestorID];
        DeviceDetails storage thisDevice = deviceDetails[thisRequest.devID];
        uint256 timeElapsed = block.timestamp -
            thisRequest.req_accept_timestamp;
        uint256 noOfHours = timeElapsed / 3600;
        uint256 leftHours = thisRequest.hrsStake - noOfHours;
        uint256 refund = leftHours * thisDevice.tokenRate;

        return (refund);
    }

    event RewardEarned(
        uint256 indexed tokensByProvider,
        uint256 indexed tokenByRequestor
    );

    function WithdrawDeviceUsebyRequestor(
        uint256 _deviceID,
        uint256 _reqID
    ) public {
        Request storage thisRequest = requests[_reqID];
        DeviceDetails storage thisDevice = deviceDetails[_deviceID];

        require(
            thisRequest.devID == _deviceID,
            "This device doesn't belong to you."
        );

        uint256 providerToken = TransferTokenToProviderInternal(
            _deviceID,
            thisDevice.recipient,
            _reqID
        );
        uint256 requestorToken = TransferTokenFromRequestorInternal(_reqID);

        thisRequest.engage = false;
        thisRequest.request_end = true;

        emit RewardEarned(providerToken, requestorToken);
    }

    function TransferTokenToRequestor(uint256 _reqID) public payable {
        Requestor storage thisRequestor = requestors[msg.sender];
        Request storage thisRequest = requests[_reqID];
        require(
            thisRequest.request_end == true,
            "The device of the this request has not ended"
        );
        token.transfer(msg.sender, thisRequestor.paidTokensTotal);
        thisRequestor.paidTokensTotal = 0;
    }
}
