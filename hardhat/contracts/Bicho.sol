pragma solidity ^0.8.7;

contract Bicho{

    event KeeperChanged(address oldKeeper,address newKeeper);
    event OwnerChanged(address oldOwner,address newOwner);

    address public keeper;
    address public s_owner;

    constructor(address _keeper){
        keeper = _keeper;
        s_owner = msg.sender;
    }

    function setKeeper(address _newKeeper) public onlyOwner{
        emit OwnerChanged(keeper,_newKeeper);
        keeper = _newKeeper;
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