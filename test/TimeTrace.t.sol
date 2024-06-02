// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../contracts/TimeTrace.sol";

contract TimeTraceTest is Test {
    TimeTrace public timeTrace;

    address owner = vm.addr(1);
    address user1 = vm.addr(2);
    address user2 = vm.addr(3);
    address user3 = vm.addr(4);

    address[] private verifiers;

    function setUp() public {
        timeTrace = new TimeTrace(owner);

        // Initialize verifier addresses
        verifiers.push(address(user1));
        verifiers.push(address(user2));
        verifiers.push(address(user3));
    }

    function testMint() public {
        string memory cid = "UniqueCID1";
        uint256 tokenId = 1;
        uint256 amount = 1;
        bytes memory data = "0x";

        // Act
        vm.prank(vm.addr(1)); // Simulating the owner is calling the function
        timeTrace.mint(vm.addr(1), tokenId, amount, data, cid);

        // Assert
        assertEq(timeTrace.balanceOf(owner, tokenId), amount, "Token amount is incorrect");
        assertEq(timeTrace.timestamp(tokenId), block.timestamp, "Timestamp is incorrect");
        assertEq(timeTrace.uniqueCid(tokenId), cid, "CID is incorrect");
        assertEq(timeTrace.tokenCreator(tokenId), owner, "Token creator is incorrect");
        assertEq(timeTrace.amountOfTokensOwned(owner), 1, "Only 1 token should be created");
        assertEq(timeTrace.tokenCreatorOwnedIds(owner, 0), tokenId ,"Creator should only own token at index 1");
        // assertEq(timeTrace.getTokenCreatorOwnedIds(), 1 ,"Creator should only own token at index 1");

    }

      function testAddVerifiers() public {
        uint256 tokenId = 1;
        uint256 amount = 1;
        bytes memory data = "0x";
        string memory cid = "UniqueCID1";

        // Mint a token to set the msg.sender as the token creator
        vm.startPrank(owner);
        timeTrace.mint(owner, tokenId, amount, data, cid);
        vm.stopPrank();

        // Try to add verifiers
        vm.startPrank(user1); // Let's assume receiver is now trying to add verifiers, should fail because receiver is not the creator
        vm.expectRevert("Must be token creator to add verifiers");
        timeTrace.addVerifiers(tokenId, verifiers);
        vm.stopPrank();

        // Properly add verifiers by the token creator
        vm.startPrank(owner);
        timeTrace.addVerifiers(tokenId, verifiers);
        vm.stopPrank();

        // Assert the verifiers are added correctly
        address[] memory addedVerifiers = timeTrace.getVerifiers(tokenId);
        for (uint i = 0; i < verifiers.length; i++) {
            assertEq(addedVerifiers[i], verifiers[i], "Verifier address does not match");
        }

        timeTrace.getVerifiers(tokenId);
        assertEq(addedVerifiers.length, verifiers.length, "Verifiers length mismatch");

        // Check if tokens were minted to verifiers
        for (uint i = 0; i < verifiers.length; i++) {
            assertEq(timeTrace.balanceOf(verifiers[i], tokenId), 1, "Token was not minted to verifier");
        }

        assertEq(timeTrace.isTokenVerifier(user1, tokenId), true, "user1 should be a token verifier");
        assertEq(timeTrace.isVerified(user1, tokenId), false, "This token should not be verified yet");
    }

    function testVerifyToken() public {
      uint256 tokenId = 1;
      uint256 amount = 1;
      bytes memory data = "0x";
      string memory cid = "UniqueCID1";

      // Setup: Mint a token and add verifiers
      vm.startPrank(owner);
      timeTrace.mint(owner, tokenId, amount, data, cid);
      timeTrace.addVerifiers(tokenId, verifiers);
      vm.stopPrank();

      // Test: Attempt to verify the token by a non-verifier should fail
      vm.startPrank(vm.addr(5)); // An address that is not a verifier
      vm.expectRevert("Not authorized to verify this token");
      timeTrace.verifyToken(tokenId);
      vm.stopPrank();

      // Test: Attempt to verify the token by a verifier should succeed
      vm.startPrank(user1);
      timeTrace.verifyToken(tokenId);
      vm.stopPrank();

      // Assert: Check if the verification has been recorded
      address[] memory whoVerified = timeTrace.getAddressesThatVerifiedToken(tokenId);
      assertEq(whoVerified.length, 1, "Verification count should be 1");
      assertEq(whoVerified[0], user1, "Verified address mismatch");

      // Assert: Ensure that the token is marked as verified for user1
      assertTrue(timeTrace.isVerified(user1, tokenId), "Token should be marked as verified for user1");
      // assertEq(timeTrace.isVerified(user1, tokenId), true, "Token should be marked as verified for user1");

      // Test: Ensure that the verification timestamp is correct for user1 
      assertEq(timeTrace.verifiedTokenTimestamp(user1 ,tokenId), block.timestamp, "Timestamp is incorrect");

      // Test: Ensure the token cannot be verified again by the same verifier
      vm.startPrank(user1);
      vm.expectRevert("Token already verified by this address");
      timeTrace.verifyToken(tokenId);
      vm.stopPrank();

      // Test: Ensure that the token creator cannot verify their own token
      vm.startPrank(owner);
      vm.expectRevert("This address is the Token Creator and cannot be a verifier");
      timeTrace.verifyToken(tokenId);
      vm.stopPrank();

    }
}
