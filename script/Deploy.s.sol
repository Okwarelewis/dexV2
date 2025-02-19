// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import '@uniswap/v2-core/contracts/UniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/UniswapV2Router02.sol';
import '../src/RewardToken.sol';
import '../src/Staking.sol';

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy Uniswap V2 Factory
        UniswapV2Factory factory = new UniswapV2Factory(msg.sender);

        // Deploy Uniswap V2 Router
        UniswapV2Router02 router = new UniswapV2Router02(address(factory));

        // Deploy Reward Token
        RewardToken rewardToken = new RewardToken();

        // Deploy Staking Contract
        Staking staking = new Staking(address(factory), address(rewardToken));

        vm.stopBroadcast();
    }
}