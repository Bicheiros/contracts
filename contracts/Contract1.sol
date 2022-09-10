// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Contract1 {
    // The random number is a js implementation of the Xorshift PRNG
    uint[6] public randseed;

    constructor() {
        for (uint256 index = 0; index < randseed.length; index++) {
            randseed[index] = 0;
        }

        seedrand("arthur");
    }

    function seedrand(string memory seed) internal {
        for (uint256 index = 0; index < randseed.length; index++) {
            randseed[index] = 0;
        }

        for (uint256 index = 0; index <  bytes(seed).length; index++) {
            randseed[index % 6] = (randseed[index % 6] << 5) - randseed[index % 6] + uint(uint8(bytes(seed)[index])); 
        }
    }

    function rand() internal returns (uint256) {
        uint t = randseed[0] ^ (randseed[0] << 11);

        randseed[0] = randseed[1];
        randseed[1] = randseed[2];
        randseed[2] = randseed[3];
        randseed[3] = randseed[4];
        randseed[4] = randseed[5];
        randseed[5] = randseed[5] ^ (randseed[5] >> 19) ^ t ^ (t >> 8);

        return (randseed[5] >> 0) / (1 << 31 >> 0);
    }

    function random() external returns (uint256) {
        return rand();
    }

}