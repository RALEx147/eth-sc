pragma solidity ^0.4.18;


contract bet {

  address public owner;
  address[] public players;
  uint256 public totalAmount;
  uint256 public interest;
  uint256 public minAmount;
  uint256 public maxPlayers;
  string public testCHECK;

  struct Player {
   uint256 amount;
   uint8 num;
   string name;
  }

  mapping(address => Player) public playerInfo;

  function() public payable {}


  function kill() public {
    if(msg.sender == owner) selfdestruct(owner);
  }



  constructor() public{
    owner = msg.sender;
    interest = 200;//0.5%
    minAmount = 1000;
    maxPlayers = 2;
    testCHECK = "none";

  }

  function setBet(string _name) public payable{

    assert(players.length < maxPlayers);
    assert(!isValidPlayer(msg.sender));
    assert(msg.value >= minAmount);
    playerInfo[msg.sender].amount = msg.value;
    playerInfo[msg.sender].name = _name;

    if (players.length == 0){ playerInfo[msg.sender].num = 0; }
    else{ playerInfo[msg.sender].num = 1; }

    players.push(msg.sender);
    totalAmount += msg.value;
    if(players.length == 2) result();
  }

  function result() internal{
    address[1] memory winner;
    uint256 LoserBet = 0;
    uint256 WinnerBet = 0;

    uint randomNumber = rand(1,10);
    uint winningNumber = 99;
    if (randomNumber <= 4) {
      winningNumber = 1;
    }
    else{
      winningNumber = 0;
    }

    for(uint256 i = 0; i < players.length; i++){
       address playerAddress = players[i];
       if(playerInfo[playerAddress].num == winningNumber){
          winner[0] = playerAddress;
          WinnerBet = playerInfo[playerAddress].amount;
       }
       else{
          LoserBet = playerInfo[playerAddress].amount;
       }
    }

    uint256 total = LoserBet + WinnerBet;
    require(total == totalAmount);

    uint256 tax = total / interest;
    uint256 winnings = total - tax;


    winner[0].transfer(winnings);

    delete playerInfo[playerAddress];
    players.length = 0;
    LoserBet = 0;
    WinnerBet = 0;
    totalAmount = 0;


  }










  function isValidPlayer(address player) public constant returns (bool){
    for(uint256 i = 0; i < players.length; i++){
         if(players[i] == player) return true;
      }
    return false;
  }


  uint nonce = 0;
  function rand(uint min, uint max) internal returns (uint){
      nonce++;
      return uint(keccak256(abi.encodePacked(nonce)))%(max-min)+min;
  }



}
