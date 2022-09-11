// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface BichoInterface{
    function ReceiveSortedResults(uint256 drawID,uint256[] memory randomWords,uint256 timestamp) external;
}

contract Bicho{

    event KeeperChanged(address oldKeeper,address newKeeper);
    event OwnerChanged(address oldOwner,address newOwner);
    event MaxBetsPerUserChanged(uint256 oldMaxBetsPerUser,uint256 newMaxBetsPerUser);
    event WithdrawThresholdChanged(uint256 oldThreshold,uint256 newThreshold);
    event GameStateChanged(GameState current);

    event NewBets(address sender,uint256 gameID,uint256[] betID,BetType[] betType,uint32[][] values,uint256[] quantity);

    event ResultsReceived(address[] playersFromRound,uint256[] results,uint256 drawID,uint256 gameID ,uint256 withdrawThreshold,uint256 timestamp);

    enum BetType {
        VaiVem,
        SecoGrupo,
        CercadoGrupo,
        DuqueGrupo,
        TernoGrupo
    }


    enum GameState {
        OPEN,
        CLOSED
    }

    mapping( BetType => uint256) public BetValues;
    BetValues[VaiVem] = 40;
    BetValues[SecoGrupo] = 18;
    BetValues[CercadoGrupo] = ;
    BetValues[DuqueGrupo] = ;
    BetValues[TernoGrupo] = 130;

    struct Bet{
        uint256 betID;
        BetType betType;
        uint32[] values;
        uint256 quantity;
    }

    struct Bets{
        address better;
        uint256 amount;
        Bet[] bets;
        bool retrieved;
    }

    struct Result{
        uint256 drawID;
        uint256[] randomWords;
        uint timestamp;
    }

    uint256 public currentGameID;
    uint256 public counter;
    address public s_owner;

    address public keeper;

    uint256 maxBetsPerUser = 100;
    uint256 withdrawThreshold = 7 days; // 1 week

    GameState currentGameState;

    mapping(address => Bets) bets;

    address[] players;
    mapping( uint256 =>  mapping(address => Bets)) public pastGames;
    mapping( uint256 => Result ) public pastResults;

    constructor(){
        counter = 0;
        s_owner = msg.sender;
        currentGameID = 1;
    }

    function newBets(BetType[] calldata betTypes,uint32[][] calldata values,uint256[] calldata quantity) public payable {
        require(currentGameState != GameState.CLOSED,"game state is closed");

        uint256 previousCounter = counter;
        uint256 newcounter = counter + betTypes.length;
        uint256 sum = 0;

        Bets storage betsHere = bets[msg.sender];
        if( betsHere.bets.length == 0 ){
            betsHere.better = msg.sender;
            betsHere.bets = new Bet[](maxBetsPerUser);
            betsHere.amount = 0;
            players.push(msg.sender);
        }

        for (uint256 index = 0; index < betTypes.length; index++) {
            sum += quantity[index];
        }

        require( sum + betsHere.amount  <= maxBetsPerUser,"user can't have more bets than the maximum allowed");
        previousCounter = counter;
        counter += betTypes.length;
        uint256[] memory betIDs = new uint256[](newcounter-previousCounter);
        for (uint256 index = 0; index < betTypes.length; index++) {
            uint256 newID = previousCounter+index;
            betIDs[index]=newID;
            betsHere.bets[betsHere.bets.length + index] = Bet(newID,betTypes[index],values[index],quantity[index]);
        }

        counter += betTypes.length;
        bets[msg.sender] = betsHere;

        emit NewBets(msg.sender,currentGameID,betIDs,betTypes,values,quantity);
    }

    function ReceiveSortedResults(uint256 drawID,uint256[] memory randomWords,uint256 timestamp) external {
        require(msg.sender == keeper || msg.sender == s_owner);
        closeGameState();
        emit ResultsReceived(players, randomWords,drawID,currentGameID,withdrawThreshold,timestamp);
        pastResults[currentGameID] = Result(drawID,randomWords,timestamp);
        for (uint256 index = 0; index < players.length; index++) {
            pastGames[currentGameID][players[index]] = bets[players[index]] ;
            delete bets[players[index]];
        }
        currentGameID++;
        delete players;
    }

    function withdraw(uint256 gameID) public {
        Bet[] memory betsWithdraw = pastGames[gameID][msg.sender].bets;
        // verificar se ele ganhou
        // struct Bets{
        //     address better;
        //     uint256 amount;
        //     Bet[] bets;
        //     bool retrieved;
        // }
        // transferir para ele
    }

    function openGameState() public {
        emit GameStateChanged(GameState.OPEN);
        currentGameState = GameState.OPEN;
    }

    function closeGameState() public {
        emit GameStateChanged(GameState.CLOSED);
        currentGameState = GameState.CLOSED;
    }

    function setMaxBetsPerUserChanged(uint256 _newMaxBetsPerUser) public onlyOwner{
        emit MaxBetsPerUserChanged(maxBetsPerUser,_newMaxBetsPerUser);
        maxBetsPerUser = _newMaxBetsPerUser;
    }

    function setWithdrawThreshold(uint256 _newThreshold) public onlyOwner{
        emit WithdrawThresholdChanged(withdrawThreshold, _newThreshold);
        withdrawThreshold = _newThreshold;
    }

    function setKeeper(address _newKeeper) public onlyOwner{
        emit OwnerChanged(keeper,_newKeeper);
        keeper = _newKeeper;
    }

    modifier onlyKeeper() {
        require(msg.sender == keeper,"not the keeper");
        _;
    }

    function setOwner(address _newOwner) public onlyOwner{
        emit OwnerChanged(s_owner,_newOwner);
        s_owner = _newOwner;
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner,"not the owner");
        _;
    }

    modifier gameStateOpen(){
        require(currentGameState == GameState.OPEN,"game state is closed");
        _;
    }
}