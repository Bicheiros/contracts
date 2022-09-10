// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Bicho{

    event KeeperChanged(address oldKeeper,address newKeeper);
    event OwnerChanged(address oldOwner,address newOwner);
    event MaxBetsPerUserChanged(uint256 oldMaxBetsPerUser,uint256 newMaxBetsPerUser);
    event GameStateChanged(GameState current);
    event NewBets(address sender,uint256[] betID,BetType[] betType,uint256[][] values,uint256[] quantity);

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
        uint256[] values;
        uint256 quantity;
    }

    struct Bets{
        address better;
        Bet[] bets;
    }

    uint256 public counter;
    address public keeper;
    address public s_owner;

    uint256 maxBetsPerUser = 100;

    GameState currentGameState;

    mapping(address => Bets) bets;

    mapping( uint256 =>  mapping(address => Bets)) public pastGames;

    constructor(address _keeper){
        keeper = _keeper;
        s_owner = msg.sender;
    }

    function newBets(BetType[] calldata betTypes,uint256[][] calldata values,uint256[] calldata quantity) public payable {
        uint256 previousCounter = counter;
        counter += betTypes.length;

        if( bets[msg.sender].bets.length == 0 ){
            bets[msg.sender].bets = new Bet[](maxBetsPerUser);
        }

        uint256[] memory betIDs = new uint256[](counter-previousCounter);
        for (uint256 index = 0; index < betTypes.length; index++) {
            uint256 newID = previousCounter+index;
            betIDs[index]=newID;
            bets[msg.sender].bets[bets[msg.sender].bets.length] = Bet(newID,betTypes[index],values[index],quantity[index]);
        }

        emit NewBets(msg.sender,betIDs,betTypes,values,quantity);

        counter += betTypes.length;
    }

    function openGameState() public onlyOwner{
        emit GameStateChanged(GameState.OPEN);
        currentGameState = GameState.OPEN;
    }

    function closedGameState() public onlyOwner{
        emit GameStateChanged(GameState.CLOSED);
        currentGameState = GameState.CLOSED;
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
        require(msg.sender == s_owner,"not the owner");
        _;
    }

    modifier gameStateOpen(){
        require(currentGameState == GameState.OPEN,"game state is closed");
        _;
    }
}