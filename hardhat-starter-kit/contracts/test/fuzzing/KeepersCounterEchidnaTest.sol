// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../../KeepersCounter.sol";

contract KeepersCounterEchidnaTest is KeepersCounter {
  constructor() KeepersCounter(8 days,address(0),address(0)) {}

  function echidna_test_perform_upkeep_gate() public view returns (bool) {
    // return counter == 0;
  }
}