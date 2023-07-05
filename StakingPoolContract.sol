// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";
contract StakingPoolContract is ReentrancyGuard {
    uint256 private FIXED_APY;
    uint256 private constant SECONDS_IN_YEAR = 31536000; // Number of seconds in a year (365 days)
    uint256 public MINIMUM_STAKING_TIME; // seconds in a month (30 days)
    bool public instant_withdrawl_allowed = false;
    address private owner;

    mapping(address => mapping(uint256 => Stake)) private stakes_pool;
    mapping(address => uint256) private stakes_count;
    mapping(address => uint256) private rewards_ewarned;

    struct Stake {
        uint256 id;
        uint256 amount;
        uint256 timestamp;
    }

    IERC20 private token;

    event StakeDeposited(
        address indexed staker,
        uint256 indexed id,
        uint256 amount,
        uint256 timestamp
    );
    event StakeWithdrawn(
        address indexed staker,
        uint256 indexed id,
        uint256 amount,
        uint256 reward,
        uint256 timestamp
    );
    event RewardsWithdrawn(address indexed staker, uint256 amount);

    constructor(
        address tokenAddress,
        uint256 _FIXED_APY,
        uint256 minmum_staking_time_in_days
    ) {
        token = IERC20(tokenAddress);
        MINIMUM_STAKING_TIME = minmum_staking_time_in_days * 24 * 60 * 60;
        FIXED_APY = _FIXED_APY;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner,"Not the owner");
        _;
    }

    function depositStake(uint256 amount)
        external
        nonReentrant
        returns (uint256)
    {
        require(amount > 0, "Invalid stake amount");

        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Stake transfer failed"
        );

        uint256 stake_id = ++stakes_count[msg.sender];

        stakes_pool[msg.sender][stake_id] = Stake(
            stake_id,
            amount,
            block.timestamp
        );
        emit StakeDeposited(msg.sender, stake_id, amount, block.timestamp);
        return stake_id;
    }

    function withdrawStake(uint256 amount, uint256 stake_id)
        external
        nonReentrant
    {
        require(stakes_count[msg.sender] > 0, "No stake found");
        require(
            amount <= stakes_pool[msg.sender][stake_id].amount,
            "Withdraw amount is more than balance of stake."
        );
        require(
            (block.timestamp - stakes_pool[msg.sender][stake_id].timestamp >=
                MINIMUM_STAKING_TIME) || instant_withdrawl_allowed,
            "MINIMUM STAKING TIME is not passed"
        );

        uint256 reward = calculateRewardPerStake(msg.sender, stake_id);

        rewards_ewarned[msg.sender] += reward;

        uint256 newAmount = stakes_pool[msg.sender][stake_id].amount - amount;
        stakes_pool[msg.sender][stake_id] = Stake(
            stake_id,
            newAmount,
            block.timestamp
        );

        require(token.transfer(msg.sender, amount), "Stake withdrawal failed");

        emit StakeWithdrawn(
            msg.sender,
            stake_id,
            amount,
            reward,
            block.timestamp
        );
    }

    function withdrawReward(uint256 amount) external nonReentrant {
        require(rewards_ewarned[msg.sender] > 0, "No Rewards Earned");
        require(
            amount <= rewards_ewarned[msg.sender],
            "It is more than current reward earned."
        );

        rewards_ewarned[msg.sender] -= amount;

        require(
            token.transfer(msg.sender, amount),
            "Rewards withdrawal failed"
        );

        emit RewardsWithdrawn(msg.sender, amount);
    }

    function calculateRewardPerStake(address staker, uint256 stake_id)
        public
        view
        returns (uint256)
    {
        uint256 amount = stakes_pool[staker][stake_id].amount;
        uint256 timestamp = stakes_pool[staker][stake_id].timestamp;
        uint256 timeElapsed = block.timestamp - timestamp;

        return (amount * FIXED_APY * timeElapsed) / (100 * SECONDS_IN_YEAR);
    }

    function getStakeAmount(address staker, uint256 stake_id)
        external
        view
        returns (uint256)
    {
        return stakes_pool[staker][stake_id].amount;
    }

    function getStakeTimestamp(address staker, uint256 stake_id)
        external
        view
        returns (uint256)
    {
        return stakes_pool[staker][stake_id].timestamp;
    }

    function getRewardsWithdrawable(address staker)
        external
        view
        returns (uint256)
    {
        return rewards_ewarned[staker];
    }

    function updateMinimumStakingTime(uint256 _days) external  {
        require(msg.sender == owner,"Not the owner");
        MINIMUM_STAKING_TIME = _days * 24 * 60 * 60;
    }

    function toggleWithdrawlInstantOrMonthly() external onlyOwner {
        instant_withdrawl_allowed = !instant_withdrawl_allowed;
    }

    function getTotalStakesCount(address staker)
        external
        view
        returns (uint256)
    {
        return stakes_count[staker];
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function set_FIXED_APY(uint256 new_FIXED_APY)  external onlyOwner {
        FIXED_APY = new_FIXED_APY;
    }

    function get_FIXED_APY() external view returns (uint256) {
        return FIXED_APY;
    }

    function changeOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }
    function set_STAKING_TIME(uint256 time,uint256 id)external {
        stakes_pool[msg.sender][id].timestamp = time;
    }
}