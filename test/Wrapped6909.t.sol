// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IERC6909} from "@openzeppelin/contracts/interfaces/draft-IERC6909.sol";

import {Wrapped6909Factory} from "../src/Wrapped6909Factory.sol";
import {Wrapped6909} from "../src/Wrapped6909.sol";
import {IWrapped6909} from "../src/interfaces/IWrapped6909.sol";
import {MockERC6909} from "./mocks/MockERC6909.sol";

contract Wrapped6909Test is Test {
    Wrapped6909Factory public factory;
    MockERC6909 public mockToken;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    uint256 public constant TOKEN_ID_1 = 1;
    uint256 public constant TOKEN_ID_2 = 2;
    uint256 public constant MINT_AMOUNT = 1000e18;

    event Wrapped6909Created(address indexed token, uint256 indexed tokenId, address indexed wrapped6909);

    function setUp() public {
        factory = new Wrapped6909Factory();
        mockToken = new MockERC6909();

        // Setup metadata for test tokens
        mockToken.setMetadata(TOKEN_ID_1, "Test Token 1", "TEST1", 18);
        mockToken.setMetadata(TOKEN_ID_2, "Test Token 2", "TEST2", 6);

        // Mint tokens to alice
        mockToken.mint(alice, TOKEN_ID_1, MINT_AMOUNT);
        mockToken.mint(alice, TOKEN_ID_2, MINT_AMOUNT);
    }

    // ============ Factory Tests ============

    function test_FactoryDeployment() public view {
        assertNotEq(address(factory.getImplementation()), address(0));
        assertTrue(factory.getImplementation().code.length > 0);
    }

    function test_GetWrapped6909Address() public {
        address predicted = factory.getWrapped6909Address(address(mockToken), TOKEN_ID_1);
        address actual = factory.wrap6909(address(mockToken), TOKEN_ID_1, 0);

        assertEq(predicted, actual);
    }

    function test_Wrap6909_CreateWrapper() public {
        vm.expectEmit(true, true, false, true);
        emit Wrapped6909Created(address(mockToken), TOKEN_ID_1, address(0));

        address wrappedToken = factory.wrap6909(address(mockToken), TOKEN_ID_1, 0);

        assertNotEq(wrappedToken, address(0));
        assertTrue(wrappedToken.code.length > 0);

        // Check metadata
        Wrapped6909 wrapped = Wrapped6909(wrappedToken);
        assertEq(wrapped.name(), "Wrapped Test Token 1");
        assertEq(wrapped.symbol(), "wTEST1");
        assertEq(wrapped.decimals(), 18);
        assertEq(wrapped.token(), address(mockToken));
        assertEq(wrapped.tokenId(), TOKEN_ID_1);
    }

    function test_Wrap6909_DifferentTokenIds() public {
        address wrapped1 = factory.wrap6909(address(mockToken), TOKEN_ID_1, 0);
        address wrapped2 = factory.wrap6909(address(mockToken), TOKEN_ID_2, 0);

        assertTrue(wrapped1 != wrapped2);

        assertEq(Wrapped6909(wrapped1).name(), "Wrapped Test Token 1");
        assertEq(Wrapped6909(wrapped2).name(), "Wrapped Test Token 2");
        assertEq(Wrapped6909(wrapped1).decimals(), 18);
        assertEq(Wrapped6909(wrapped2).decimals(), 6);
    }

    function test_Wrap6909_Deterministic() public {
        address wrapped1 = factory.wrap6909(address(mockToken), TOKEN_ID_1, 0);

        // Deploy another factory
        Wrapped6909Factory factory2 = new Wrapped6909Factory();
        address wrapped2 = factory2.wrap6909(address(mockToken), TOKEN_ID_1, 0);

        // Should be different addresses (different factory addresses)
        assertTrue(wrapped1 != wrapped2);
    }

    function test_Wrap6909_ReturnsExistingWrapper() public {
        address wrappedToken1 = factory.wrap6909(address(mockToken), TOKEN_ID_1, 0);

        // Second call should return the same address without reverting
        address wrappedToken2 = factory.wrap6909(address(mockToken), TOKEN_ID_1, 0);

        assertEq(wrappedToken1, wrappedToken2);
    }

    function test_Wrap6909_WithDeposit() public {
        uint256 depositAmount = 100e18;

        vm.startPrank(alice);
        mockToken.approve(address(factory), TOKEN_ID_1, depositAmount);

        address wrappedToken = factory.wrap6909(address(mockToken), TOKEN_ID_1, depositAmount);
        vm.stopPrank();

        Wrapped6909 wrapped = Wrapped6909(wrappedToken);

        // Check that alice received wrapped tokens
        assertEq(wrapped.balanceOf(alice), depositAmount);
        // Check that the wrapper contract holds the underlying tokens
        assertEq(mockToken.balanceOf(wrappedToken, TOKEN_ID_1), depositAmount);
        // Check that alice's original balance decreased
        assertEq(mockToken.balanceOf(alice, TOKEN_ID_1), MINT_AMOUNT - depositAmount);
    }

    function test_Wrap6909_ExistingWrapper_AdditionalDeposit() public {
        // Create wrapper first
        factory.wrap6909(address(mockToken), TOKEN_ID_1, 0);

        uint256 additionalAmount = 50e18;

        vm.startPrank(alice);
        mockToken.approve(address(factory), TOKEN_ID_1, additionalAmount);

        // Should not revert when wrapper already exists, just deposit
        address wrappedToken = factory.wrap6909(address(mockToken), TOKEN_ID_1, additionalAmount);
        vm.stopPrank();

        Wrapped6909 wrapped = Wrapped6909(wrappedToken);
        assertEq(wrapped.balanceOf(alice), additionalAmount);
    }

    function test_Wrap6909_InsufficientBalance() public {
        uint256 excessiveAmount = MINT_AMOUNT + 1;

        vm.startPrank(alice);
        mockToken.approve(address(factory), TOKEN_ID_1, excessiveAmount);

        vm.expectRevert();
        factory.wrap6909(address(mockToken), TOKEN_ID_1, excessiveAmount);
        vm.stopPrank();
    }

    function test_Wrap6909_InsufficientAllowance() public {
        uint256 depositAmount = 100e18;

        vm.expectRevert();
        vm.prank(alice);
        factory.wrap6909(address(mockToken), TOKEN_ID_1, depositAmount);
    }

    // ============ Wrapper Tests ============

    function test_DepositFor() public {
        address wrappedToken = factory.wrap6909(address(mockToken), TOKEN_ID_1, 0);
        Wrapped6909 wrapped = Wrapped6909(wrappedToken);

        uint256 depositAmount = 100e18;

        vm.startPrank(alice);
        mockToken.approve(wrappedToken, TOKEN_ID_1, depositAmount);
        wrapped.depositFor(bob, depositAmount);
        vm.stopPrank();

        // Check balances
        assertEq(wrapped.balanceOf(bob), depositAmount);
        assertEq(mockToken.balanceOf(wrappedToken, TOKEN_ID_1), depositAmount);
        assertEq(mockToken.balanceOf(alice, TOKEN_ID_1), MINT_AMOUNT - depositAmount);
    }

    function test_DepositFor_SelfDeposit() public {
        address wrappedToken = factory.wrap6909(address(mockToken), TOKEN_ID_1, 0);
        Wrapped6909 wrapped = Wrapped6909(wrappedToken);

        uint256 depositAmount = 100e18;

        vm.startPrank(alice);
        mockToken.approve(wrappedToken, TOKEN_ID_1, depositAmount);
        wrapped.depositFor(alice, depositAmount);
        vm.stopPrank();

        assertEq(wrapped.balanceOf(alice), depositAmount);
    }

    function test_DepositFor_ZeroAmount() public {
        address wrappedToken = factory.wrap6909(address(mockToken), TOKEN_ID_1, 0);
        Wrapped6909 wrapped = Wrapped6909(wrappedToken);

        vm.startPrank(alice);
        mockToken.approve(wrappedToken, TOKEN_ID_1, 0);
        wrapped.depositFor(bob, 0);
        vm.stopPrank();

        assertEq(wrapped.balanceOf(bob), 0);
    }

    function test_DepositFor_InsufficientBalance() public {
        address wrappedToken = factory.wrap6909(address(mockToken), TOKEN_ID_1, 0);
        Wrapped6909 wrapped = Wrapped6909(wrappedToken);

        vm.startPrank(alice);
        mockToken.approve(wrappedToken, TOKEN_ID_1, MINT_AMOUNT + 1);

        vm.expectRevert();
        wrapped.depositFor(bob, MINT_AMOUNT + 1);
        vm.stopPrank();
    }

    function test_DepositFor_InsufficientAllowance() public {
        address wrappedToken = factory.wrap6909(address(mockToken), TOKEN_ID_1, 0);
        Wrapped6909 wrapped = Wrapped6909(wrappedToken);

        vm.expectRevert();
        vm.prank(alice);
        wrapped.depositFor(bob, 100e18);
    }

    function test_WithdrawTo() public {
        address wrappedToken = factory.wrap6909(address(mockToken), TOKEN_ID_1, 0);
        Wrapped6909 wrapped = Wrapped6909(wrappedToken);

        uint256 depositAmount = 100e18;
        uint256 withdrawAmount = 50e18;

        // First deposit
        vm.startPrank(alice);
        mockToken.approve(wrappedToken, TOKEN_ID_1, depositAmount);
        wrapped.depositFor(alice, depositAmount);

        // Then withdraw
        wrapped.withdrawTo(bob, withdrawAmount);
        vm.stopPrank();

        // Check balances
        assertEq(wrapped.balanceOf(alice), depositAmount - withdrawAmount);
        assertEq(mockToken.balanceOf(bob, TOKEN_ID_1), withdrawAmount);
        assertEq(mockToken.balanceOf(wrappedToken, TOKEN_ID_1), depositAmount - withdrawAmount);
    }

    function test_WithdrawTo_FullAmount() public {
        address wrappedToken = factory.wrap6909(address(mockToken), TOKEN_ID_1, 0);
        Wrapped6909 wrapped = Wrapped6909(wrappedToken);

        uint256 depositAmount = 100e18;

        vm.startPrank(alice);
        mockToken.approve(wrappedToken, TOKEN_ID_1, depositAmount);
        wrapped.depositFor(alice, depositAmount);
        wrapped.withdrawTo(alice, depositAmount);
        vm.stopPrank();

        assertEq(wrapped.balanceOf(alice), 0);
        assertEq(mockToken.balanceOf(alice, TOKEN_ID_1), MINT_AMOUNT);
        assertEq(mockToken.balanceOf(wrappedToken, TOKEN_ID_1), 0);
    }

    function test_WithdrawTo_ZeroAmount() public {
        address wrappedToken = factory.wrap6909(address(mockToken), TOKEN_ID_1, 0);
        Wrapped6909 wrapped = Wrapped6909(wrappedToken);

        vm.prank(alice);
        wrapped.withdrawTo(bob, 0);

        assertEq(wrapped.balanceOf(alice), 0);
        assertEq(mockToken.balanceOf(bob, TOKEN_ID_1), 0);
    }

    function test_WithdrawTo_InsufficientBalance() public {
        address wrappedToken = factory.wrap6909(address(mockToken), TOKEN_ID_1, 0);
        Wrapped6909 wrapped = Wrapped6909(wrappedToken);

        vm.expectRevert();
        vm.prank(alice);
        wrapped.withdrawTo(bob, 1);
    }

    // ============ ERC20 Functionality ============

    function test_ERC20_Transfer() public {
        address wrappedToken = factory.wrap6909(address(mockToken), TOKEN_ID_1, 0);
        Wrapped6909 wrapped = Wrapped6909(wrappedToken);

        uint256 depositAmount = 100e18;
        uint256 transferAmount = 30e18;

        // Deposit first
        vm.startPrank(alice);
        mockToken.approve(wrappedToken, TOKEN_ID_1, depositAmount);
        wrapped.depositFor(alice, depositAmount);

        // Transfer wrapped tokens
        wrapped.transfer(bob, transferAmount);
        vm.stopPrank();

        assertEq(wrapped.balanceOf(alice), depositAmount - transferAmount);
        assertEq(wrapped.balanceOf(bob), transferAmount);
    }

    function test_ERC20_Approve() public {
        address wrappedToken = factory.wrap6909(address(mockToken), TOKEN_ID_1, 0);
        Wrapped6909 wrapped = Wrapped6909(wrappedToken);

        uint256 approveAmount = 50e18;

        vm.prank(alice);
        wrapped.approve(bob, approveAmount);

        assertEq(wrapped.allowance(alice, bob), approveAmount);
    }

    function test_ERC20_TransferFrom() public {
        address wrappedToken = factory.wrap6909(address(mockToken), TOKEN_ID_1, 0);
        Wrapped6909 wrapped = Wrapped6909(wrappedToken);

        uint256 depositAmount = 100e18;
        uint256 transferAmount = 30e18;

        // Setup: Alice deposits and approves Bob
        vm.startPrank(alice);
        mockToken.approve(wrappedToken, TOKEN_ID_1, depositAmount);
        wrapped.depositFor(alice, depositAmount);
        wrapped.approve(bob, transferAmount);
        vm.stopPrank();

        // Bob transfers from Alice to himself
        vm.prank(bob);
        wrapped.transferFrom(alice, bob, transferAmount);

        assertEq(wrapped.balanceOf(alice), depositAmount - transferAmount);
        assertEq(wrapped.balanceOf(bob), transferAmount);
        assertEq(wrapped.allowance(alice, bob), 0);
    }

    // ============ Fuzz Tests ============

    function testFuzz_Wrap6909_WithDeposit(uint256 amount) public {
        amount = bound(amount, 1, MINT_AMOUNT);

        vm.startPrank(alice);
        mockToken.approve(address(factory), TOKEN_ID_1, amount);
        address wrappedToken = factory.wrap6909(address(mockToken), TOKEN_ID_1, amount);
        vm.stopPrank();

        Wrapped6909 wrapped = Wrapped6909(wrappedToken);
        assertEq(wrapped.balanceOf(alice), amount);
        assertEq(mockToken.balanceOf(wrappedToken, TOKEN_ID_1), amount);
        assertEq(mockToken.balanceOf(alice, TOKEN_ID_1), MINT_AMOUNT - amount);
    }

    function testFuzz_DepositWithdraw(uint256 amount) public {
        amount = bound(amount, 1, MINT_AMOUNT);

        address wrappedToken = factory.wrap6909(address(mockToken), TOKEN_ID_1, 0);
        Wrapped6909 wrapped = Wrapped6909(wrappedToken);

        vm.startPrank(alice);
        mockToken.approve(wrappedToken, TOKEN_ID_1, amount);
        wrapped.depositFor(alice, amount);
        wrapped.withdrawTo(alice, amount);
        vm.stopPrank();

        assertEq(wrapped.balanceOf(alice), 0);
        assertEq(mockToken.balanceOf(alice, TOKEN_ID_1), MINT_AMOUNT);
    }

    function testFuzz_MultipleDeposits(uint256 amount1, uint256 amount2) public {
        amount1 = bound(amount1, 1, MINT_AMOUNT / 2);
        amount2 = bound(amount2, 1, MINT_AMOUNT - amount1);

        address wrappedToken = factory.wrap6909(address(mockToken), TOKEN_ID_1, 0);
        Wrapped6909 wrapped = Wrapped6909(wrappedToken);

        vm.startPrank(alice);
        mockToken.approve(wrappedToken, TOKEN_ID_1, amount1 + amount2);
        wrapped.depositFor(alice, amount1);
        wrapped.depositFor(bob, amount2);
        vm.stopPrank();

        assertEq(wrapped.balanceOf(alice), amount1);
        assertEq(wrapped.balanceOf(bob), amount2);
        assertEq(wrapped.totalSupply(), amount1 + amount2);
    }
}
