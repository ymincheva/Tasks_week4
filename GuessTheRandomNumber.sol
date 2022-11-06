// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/*
NOTE: cannot use blockhash in Remix so use ganache-cli

npm i -g ganache-cli
ganache-cli
In remix switch environment to Web3 provider
*/

/*
GuessTheRandomNumber is a game where you win 1 Ether if you can guess the
pseudo random number generated from block hash and timestamp.

At first glance, it seems impossible to guess the correct number.
But let's see how easy it is win.

1. Alice deploys GuessTheRandomNumber with 1 Ether
2. Eve deploys Attack
3. Eve calls Attack.attack() and wins 1 Ether

What happened?
Attack computed the correct answer by simply copying the code that computes the random number.
*/

import '@chainlink/contracts/src/v0.8/VRFConsumerBase.sol';

contract GuessTheRandomNumber is VRFConsumerBase {

   event RequestFulfilled(bytes32 requestId, uint256 randomness);

    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;

   constructor()
        VRFConsumerBase(
            0x2bce784e69d2Ff36c71edcB9F88358dB0DfB55b4, // VRF Coordinator
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB // LINK Token
        )
    {
        keyHash = 0x0476f9a745b61ea5c0ab224d3a6e4c99f0b02fce4da01143a4f70aa80ae76e8a;
        fee = 0.1 * 10**18; // 0.1 LINK (Varies by network)
    }


    /**
     * Requests randomness
     */
    function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, 'Not enough LINK - fill contract with faucet');
        return requestRandomness(keyHash, fee);
    }

     /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
        emit RequestFulfilled(requestId, randomness);
    }

    function guess(uint _guess) public {
      //  uint answer = uint(
      //      keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))
       // );
         uint answer = uint(
            keccak256(abi.encodePacked(getRandomNumber()))
       );
        if (_guess == answer) {
            (bool sent, ) = msg.sender.call{value: 1 ether}("");
            require(sent, "Failed to send Ether");
        }
    }
}

contract Attack {
    receive() external payable {}

    function attack(GuessTheRandomNumber guessTheRandomNumber) public {
        uint answer = uint(
            keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))
        );

        guessTheRandomNumber.guess(answer);
    }

    // Helper function to check balance
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}