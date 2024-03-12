// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant SEND_HIGH_AMOUNT = 1 ether;
    uint256 constant SEND_LOW_AMOUNT = 1 gwei;
    uint256 constant GAS_PRICE = 1;

    modifier funded() {
        console.log("pranking user: ", USER);
        console.log("sender before prank: ", msg.sender);
        vm.prank(USER);
        console.log("sender after: ", msg.sender);
        fundMe.fund{value: SEND_HIGH_AMOUNT}();
        _;
    }

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }
    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        console.log("version: ", version);
        assertEq(fundMe.getVersion(), 4);
    }

    function testWithdrawAsNotOwner() public {
        fundMe.fund{value: 1e18}();
        assertEq(fundMe.getAddressToAmountFunded(address(this)), 1e18);
        bytes memory encodedSignature = abi.encodeWithSignature(
            "FundMe__NotOwner()"
        );
        vm.expectRevert(encodedSignature);
        fundMe.withdraw();
        //expecting revert
    }

    function testWithdrawAsOwner() public {
        fundMe.fund{value: 1e18}();
        assertEq(fundMe.getAddressToAmountFunded(address(this)), 1e18);
        vm.prank(msg.sender);
        fundMe.withdraw();
        assertEq(fundMe.getAddressToAmountFunded(address(this)), 0);
    }

    function testFunding() public funded {
        assertEq(fundMe.getAddressToAmountFunded(USER), 1e18);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();
        fundMe.fund{value: SEND_LOW_AMOUNT}();
    }

    function testAddsFunderToArrayOfFundersFromArray() public funded {
        address[] memory funders = fundMe.getFunders();
        assertEq(funders.length, 1);
        assertEq(funders[0], USER);
    }

    function testAddsFunderToArrayOfFundersFromIndex() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOwnerCanWithdrawWithSingleFunder() public funded {
        uint256 ownerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        console.log("starting owner balance: ", ownerBalance);
        console.log("starting fund me balance: ", startingFundMeBalance);

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        console.log("ending owner balance: ", endingFundMeBalance);
        console.log("ending fund me balance: ", endingOwnerBalance);

        assertEq(endingFundMeBalance, 0);
        assertEq(endingOwnerBalance, ownerBalance + startingFundMeBalance);
    }

    function testOwnerCanWithdrawWithMultipleFunders() public funded {
        uint256 numberOfFunders = 100;
        uint256 startingFunderIndex = 1;

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundBalance = address(fundMe).balance;

        console.log("starting owner balance: ", startingOwnerBalance);
        console.log("starting fund balance: ", startingFundBalance);

        for (uint256 i = startingFunderIndex; i < numberOfFunders; i++) {
            address funderAddress = makeAddr(Strings.toString(i));
            vm.deal(funderAddress, STARTING_BALANCE);
            vm.prank(funderAddress);
            fundMe.fund{value: SEND_HIGH_AMOUNT}();
        }
        address[] memory funders = fundMe.getFunders();
        console.log("funders: ", funders.length);

        uint256 fundBalanceAfterFunding = address(fundMe).balance;

        console.log("fund balance after funding: ", fundBalanceAfterFunding);

        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("gas used: ", gasUsed);

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundBalance = address(fundMe).balance;

        console.log("ending fund balance: ", endingFundBalance);
        console.log("ending owner balance: ", endingOwnerBalance);
    }
    function testOwnerCanCheaperWithdrawWithMultipleFunders() public funded {
        uint256 numberOfFunders = 100;
        uint256 startingFunderIndex = 1;

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundBalance = address(fundMe).balance;

        console.log("starting owner balance: ", startingOwnerBalance);
        console.log("starting fund balance: ", startingFundBalance);

        for (uint256 i = startingFunderIndex; i < numberOfFunders; i++) {
            address funderAddress = makeAddr(Strings.toString(i));
            vm.deal(funderAddress, STARTING_BALANCE);
            vm.prank(funderAddress);
            fundMe.fund{value: SEND_HIGH_AMOUNT}();
        }
        address[] memory funders = fundMe.getFunders();
        console.log("funders: ", funders.length);

        uint256 fundBalanceAfterFunding = address(fundMe).balance;

        console.log("fund balance after funding: ", fundBalanceAfterFunding);

        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("gas used: ", gasUsed);

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundBalance = address(fundMe).balance;

        console.log("ending fund balance: ", endingFundBalance);
        console.log("ending owner balance: ", endingOwnerBalance);
    }
}
