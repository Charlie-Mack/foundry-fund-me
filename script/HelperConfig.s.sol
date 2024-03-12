//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mock/MockV3Aggregator.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    uint8 public constant ETH_DECIMALS = 8;
    int256 public constant ETH_PRICE = 4000e8;
    uint256 public constant SEPOLIA_CHAINID = 11155111;
    uint256 public constant MAINNET_CHAINID = 1;
    uint256 public constant ZKSYNC_CHAINID = 324;

    struct NetworkConfig {
        address priceFeed;
    }

    constructor() {
        if (block.chainid == SEPOLIA_CHAINID) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == MAINNET_CHAINID) {
            activeNetworkConfig = getMainnetEthConfig();
        } else if (block.chainid == ZKSYNC_CHAINID) {
            activeNetworkConfig = getzkSyncEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
            });
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
            });
    }
    function getzkSyncEthConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                priceFeed: 0x6D41d1dc818112880b40e26BD6FD347E41008eDA
            });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();

        MockV3Aggregator mockV3Aggregator = new MockV3Aggregator(
            ETH_DECIMALS,
            ETH_PRICE
        );

        vm.stopBroadcast();

        return NetworkConfig({priceFeed: address(mockV3Aggregator)});
    }
}
