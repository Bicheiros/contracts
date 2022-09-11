// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "./RandomNumberConsumerV2.sol";
import "./Bicho.sol";


/**
 * @title The Counter contract
 * @notice  A keeper-compatible contract that increments counter variable at fixed time intervals
 */
contract KeepersCounter is KeeperCompatibleInterface {

  event IntervalChanged(uint256 oldInterval,uint256 newInterval);
  event OwnerChanged(address oldOwner,address newOwner);
  event PerformGame(uint256 drawID, uint256[] randomWords,uint256 timestamp,uint256 blockNumber);

  address public vrfConsumer;
  address public s_owner;
  RandomNumberConsumerV2Interface immutable CONSUMER;
  BichoInterface immutable TARGET;


  /**
   * Use an interval in seconds and a timestamp to slow execution of Upkeep
   */
  uint256 public interval;
  uint256 public lastTimeStamp;

  /**
   * @notice Executes once when a contract is created to initialize state variables
   *
   * @param updateInterval - Period of time between two counter increments expressed as UNIX timestamp value
   */
  constructor(uint256 updateInterval, address _s_owner,address _vrfConsumer,address _Bicho) {
    interval = updateInterval;
    lastTimeStamp = block.timestamp;
    s_owner = _s_owner;
    vrfConsumer = _vrfConsumer;
    CONSUMER = RandomNumberConsumerV2Interface(_vrfConsumer);
    TARGET = BichoInterface(_Bicho);
  }

  /**
   * @notice Checks if the contract requires work to be done
   */
  function checkUpkeep(
    bytes memory /* checkData */
  )
    public
    view
    override
    returns (
      bool upkeepNeeded,
      bytes memory /* performData */
    )
  {
    bool blockConditionOne = (block.timestamp - lastTimeStamp) > interval;
    bool blockConditionTwo = CONSUMER.dataFetched();
    bool blockConditionThree = TARGET.AlreadyHaveBets();

    upkeepNeeded = blockConditionOne && blockConditionTwo && blockConditionThree;
    // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
  }

  /**
   * @notice Performs the work on the contract, if instructed by :checkUpkeep():
   */
  function performUpkeep(
    bytes calldata /* performData */
  ) external override {
    // add some verification
    (bool upkeepNeeded, ) = checkUpkeep("");
    require(upkeepNeeded, "Time interval not met");

    uint256 lastTimeStamp = block.timestamp;
    CONSUMER.setDataFetched(false);
    
    uint256 drawID = CONSUMER.s_requestId();
    uint256[] memory randomWords = CONSUMER.s_randomWords();

    emit PerformGame(drawID, randomWords,  block.timestamp, block.number);
    // Call the logic to find winners;
    TARGET.ReceiveSortedResults(drawID, randomWords,block.timestamp);
  }

  function setInterval(uint256 _interval) public onlyOwner {
    emit IntervalChanged(interval,_interval);
    interval = _interval;

  }
  
  function setOwner(address _newOwner) public onlyOwner{
    emit OwnerChanged(s_owner,_newOwner);
    s_owner = _newOwner;
  }

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }
}
