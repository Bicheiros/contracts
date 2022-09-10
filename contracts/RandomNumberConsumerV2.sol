// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import "hardhat/console.sol";

interface RandomNumberConsumerV2Interface {
    function setDataFetched(bool _dataFetched) external;

    function dataFetched() external view returns (bool);

    function s_requestId() external view returns (uint256);

    function s_randomWords() external view returns (uint256[] memory);
}

/**
 * @title The RandomNumberConsumerV2 contract
 * @notice A contract that gets random values from Chainlink VRF V2
 */
contract RandomNumberConsumerV2 is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface immutable COORDINATOR;

    // Your subscription ID.
    uint64 immutable s_subscriptionId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 immutable s_keyHash;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 constant CALLBACK_GAS_LIMIT = 90000000;

    // The default is 3, but you can set this higher.
    uint16 constant REQUEST_CONFIRMATIONS = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 constant NUM_WORDS = 5;

    uint256[] public s_randomWords;
    uint256 public s_requestId;
    address s_owner;
    address keeper;
    address immutable s_coordinator;
    bool public dataFetched;

    event ReturnedRandomness(uint256[] randomWords);
    event OwnerChanged(address oldOwner, address newOwner);

    /**
     * @notice Constructor inherits VRFConsumerBaseV2
     *
     * @param subscriptionId - the subscription ID that this contract uses for funding requests
     * @param vrfCoordinator - coordinator, check https://docs.chain.link/docs/vrf-contracts/#configurations
     * @param keyHash - the gas lane to use, which specifies the maximum gas price to bump to
     */
    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash
    ) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_keyHash = keyHash;
        s_owner = msg.sender;
        s_coordinator = vrfCoordinator;
        s_subscriptionId = subscriptionId;
        dataFetched = false;
    }

    /**
     * @notice Requests randomness
     * Assumes the subscription is funded sufficiently; "Words" refers to unit of data in Computer Science
     */
    function requestRandomWords() external keeperOrOwner {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );
    }

    function setDataFetched(bool _dataFetched) public {
        dataFetched = _dataFetched;
    }

    /**
     * @notice Callback function used by VRF Coordinator
     *
     * @param requestId - id of the request
     * @param randomWords - array of random results from VRF Coordinator
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        require(msg.sender == s_coordinator);
        s_randomWords = randomWords;

        uint8 length = uint8(s_randomWords.length);
        uint256 sum = 0;
        uint256 index;
        for (index = 0; index < length; index++) {
            s_randomWords[index] = randomWords[index] % 10000;
            sum += s_randomWords[index];
        }

        uint256 aux = s_randomWords[0] * s_randomWords[1];

        s_randomWords.push(sum % 1000);
        s_randomWords.push(((aux - (aux % 1000)) / 1000) % 1000);
        s_randomWords.push((s_randomWords[0] * 4) % 100);

        length = uint8(s_randomWords.length);
        for (index = 0; index < length; index++) {
            console.log("item", index + 1, s_randomWords[index]);
        }
        setDataFetched(true);
        emit ReturnedRandomness(s_randomWords);
    }

    modifier onlyKeeper() {
        require(msg.sender == keeper);
        _;
    }

    modifier keeperOrOwner() {
        require(msg.sender == keeper || msg.sender == s_owner);
        _;
    }

    function setOwner(address _newOwner) public onlyOwner {
        emit OwnerChanged(s_owner, _newOwner);
        s_owner = _newOwner;
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }
}
