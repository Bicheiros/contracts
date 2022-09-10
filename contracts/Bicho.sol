// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface BichoInterface{
    function ReceiveSortedResults(uint256 drawID,uint256[] memory randomWords,uint256 timestamp) external;
}

contract Bicho{

    event KeeperChanged(address oldKeeper,address newKeeper);
    event OwnerChanged(address oldOwner,address newOwner);
    event MaxBetsPerUserChanged(uint256 oldMaxBetsPerUser,uint256 newMaxBetsPerUser);
    event GameStateChanged(GameState current);
    event NewBets(address sender,uint256[] betID,BetType[] betType,uint32[][] values,uint256[] quantity);

    enum BetType {
        SecoMilhar, 
        SecoDezena, 
        SecoCentena, 
        SecoGrupo,
        CercadoMilhar,
        CercadoDezena,
        CercadoCentena,
        CercadoGrupo,
        DuqueMilhar,
        DuqueDezena,
        DuqueCentena,
        DuqueGrupo,
        TernoMilhar,
        TernoDezena,
        TernoCentena,
        TernoGrupo
    }

    enum GameState {
        OPEN,
        CLOSED
    }

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
        uint256[] randomWords;
        uint timestamp;
    }

    uint256 public counter;
    address public keeper;
    address public s_owner;

    uint256 maxBetsPerUser = 100;

    GameState currentGameState;

    mapping(address => Bets) bets;

    address[] players;
    mapping( uint256 =>  mapping(address => Bets)) public pastGames;
    mapping( uint256 => Result ) public pastVictories;

    constructor(){
        s_owner = msg.sender;
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

        emit NewBets(msg.sender,betIDs,betTypes,values,quantity);
    }

    function ReceiveSortedResults(uint256 drawID,uint256[] memory randomWords,uint256 timestamp) external {
        require(msg.sender == keeper || msg.sender == s_owner);
        closeGameState();
        pastVictories[drawID] = Result(randomWords,timestamp);
        for (uint256 index = 0; index < players.length; index++) {
            pastGames[drawID][players[index]] = bets[players[index]] ;
            delete bets[players[index]];
        }
        delete players;
    }

    function withdraw() public {
        
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