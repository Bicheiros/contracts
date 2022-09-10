// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "./RandomNumberConsumerV2.sol";

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
  constructor(uint256 updateInterval, address _s_owner,address _vrfConsumer) {
    interval = updateInterval;
    lastTimeStamp = block.timestamp;
    s_owner = _s_owner;
    vrfConsumer = _vrfConsumer;
    CONSUMER = RandomNumberConsumerV2Interface(_vrfConsumer);
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
    upkeepNeeded = (block.timestamp - lastTimeStamp) > interval && CONSUMER.dataFetched();
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

    lastTimeStamp = block.timestamp;
    CONSUMER.setDataFetched(false);
    emit PerformGame(CONSUMER.s_requestId(),CONSUMER.s_randomWords(),block.timestamp,block.number);
    // Call the logic to find winners;
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
