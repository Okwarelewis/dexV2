// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Staking is ReentrancyGuard {
    IERC20 public lpToken;          // LP token to be staked
    IERC20 public rewardToken;      // Reward token (custom ERC-20)

    uint256 public totalStaked;     // Total LP tokens staked
    uint256 public rewardRate;      // Rewards per second
    uint256 public lastUpdateTime;  // Last time rewards were calculated
    uint256 public rewardPerTokenStored; // Accumulated rewards per token

    mapping(address => uint256) public stakedBalances; // Staked balances of users
    mapping(address => uint256) public userRewardPerTokenPaid; // Rewards paid per token
    mapping(address => uint256) public rewards;        // User rewards

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);

    constructor(address _lpToken, address _rewardToken) {
        lpToken = IERC20(_lpToken);
        rewardToken = IERC20(_rewardToken);
    }

    // Update rewards for a user
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    // Calculate rewards per token
    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + (
            (block.timestamp - lastUpdateTime) * rewardRate * 1e18 / totalStaked
        );
    }

    // Calculate earned rewards for a user
    function earned(address account) public view returns (uint256) {
        return (
            stakedBalances[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18
        ) + rewards[account];
    }

    // Stake LP tokens
    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        totalStaked += amount;
        stakedBalances[msg.sender] += amount;
        lpToken.transferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    // Unstake LP tokens
    function unstake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot unstake 0");
        require(stakedBalances[msg.sender] >= amount, "Insufficient balance");
        totalStaked -= amount;
        stakedBalances[msg.sender] -= amount;
        lpToken.transfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    // Claim rewards
    function claimRewards() external nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards to claim");
        rewards[msg.sender] = 0;
        rewardToken.transfer(msg.sender, reward);
        emit RewardPaid(msg.sender, reward);
    }

    // Set reward rate (only callable by owner or reward distributor)
    function setRewardRate(uint256 _rewardRate) external {
        rewardRate = _rewardRate;
        lastUpdateTime = block.timestamp;
    }
}