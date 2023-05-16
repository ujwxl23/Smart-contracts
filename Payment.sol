error NotOwner();

contract Payment{

    mapping (address => uint256) public addressToAmtFunded;
    address[] public funders;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function firstPayment() external payable {
    require(msg.value >= 1 ether, 'Need to send more than or equal to 1 ETH');
    addressToAmtFunded[msg.sender] += msg.value;
    funders.push(msg.sender);
    }

    modifier onlyOwner {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function refundAmt(uint256 amtReq) public returns(bool success) {
    require(amtReq > 0,"Enter the amount greater than 0");
    require(amtReq*10**18 == addressToAmtFunded[msg.sender], "Amount requested is not equal to the deposit");
    addressToAmtFunded[msg.sender] -= amtReq*10** 18;
    payable(msg.sender).transfer(amtReq);
    return true;
    }

    function checkBalance (address balance) public view returns (uint256){
        return (addressToAmtFunded[balance]);
    }

}
