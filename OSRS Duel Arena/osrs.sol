pragma solidity ^0.4.24;


/*
TODO
* optimize gas costs
* accept duel function
* duel specific player
* which functions for gui vs contract
*/


contract roll{

    uint nonce = 0;
    function rand(uint min, uint max) internal returns (uint){
        nonce = SafeMath.add(nonce,1);
        uint generated = uint(keccak256(abi.encodePacked(nonce, block.number, min, max)));
        uint base = SafeMath.sub(max, min);
        return SafeMath.add(SafeMath.mod(generated,base),min);
    }

    enum attackStyle{
        aggressive,
        accurate,
        defensive,
        controlled
    }

}



contract osrs is roll {

  uint private decFactor = 1000000000000;


  function duel(player _player1, player _player2) internal returns (player){

      uint p1Acc = accuracy(_player1.atkRoll(), _player2.defRoll());
      uint p2Acc = accuracy(_player2.atkRoll(), _player1.defRoll());

      uint p1Max = _player1.maxHit();
      uint p2Max = _player2.maxHit();

      uint round = 0;
      while ((_player1.getHP() != 0 || _player2.getHP() != 0) && round <= 15) {
          require(round < 5);
          uint p1Roll = rand(0, SafeMath.add(decFactor, 1));
          uint p2Roll = rand(0, SafeMath.add(decFactor, 1));

          if (p1Acc > p1Roll){  hit(_player2, p1Max, round); }
          else{ _player2.deductHP(0, "miss"); }
          if (p2Acc > p2Roll){  hit(_player1, p2Max, round); }
          else{ _player1.deductHP(0, "miss"); }//i bet they they never miss huh?

          if (_player1.getHP() > 0) {  applyPoison(_player1, round); }
          if (_player2.getHP() > 0) {  applyPoison(_player2, round); }

          round += 1;
      }

        uint p1hp = _player1.getHP();
        uint p2hp = _player2.getHP();
        uint p1pid = _player1.getPID();
        uint p2pid = _player2.getPID();
        
      if (p1hp == p2hp) {
         if (p1pid <= p2pid){
             return _player1;
         }
         else{
             return _player2;
         }
        }
      if (p1hp == 0) {  return _player2; }
      if (p2hp == 0) { return _player1; }
      if (p1hp > p2hp){
          return _player1;
         }
    return _player2;
       
       
   
  
  }


  function accuracy(uint atk, uint def) internal view returns (uint){
      if (atk > def) {
          return SafeMath.sub(decFactor, SafeMath.div(SafeMath.mul(SafeMath.add(def,2), decFactor), SafeMath.mul(SafeMath.add(atk, 1), 2)));
      }
      else{
          return SafeMath.div(SafeMath.mul(atk, decFactor), SafeMath.mul(2, SafeMath.add(def, 1)));
      }
  }


  function applyPoison(player _player, uint round) internal{
      if (_player.checkPoisoned()){
          uint poisonTicked = SafeMath.sub(round, _player.whenPoisoned());
          if (poisonTicked >= 7){
              _player.deductHP(4, "p");
              _player.poisoned(round);
              
          }
      }
  }

  function hit(player _player, uint _otherMaxhit, uint _round) internal{
      uint pois = rand(0, 4);
      if (pois == 3){
          _player.poisoned(_round);
      }
      uint hitsplat = rand(0, _otherMaxhit);
      _player.deductHP(hitsplat, "hit");
  }







}

contract DuelArena is osrs{
  struct bet {
      uint amount;
      player user;
      player opponent;
  }
  uint tax;
  address public owner;
  // address payable[] addresses; 0.5.0
  address[] addresses;
  uint public minBet;
  uint public totalBet;
  string public recentWinner;
  uint public recentwinninghit;

  uint public testshowbetslength;

  
  mapping(address => bet) public bets;

  function join(uint _health, uint _attack, uint _strength, uint _defence, attackStyle _style, uint _atkBonus, uint _strBonus, uint _defBonus, string memory _name/*, player _opponent*/) public payable{
      /* resetDisplays(); */

      player p = new player(_health, _attack, _strength, _defence, _style, _atkBonus, _strBonus, _defBonus, _name);
      bets[msg.sender].user = p;
      bets[msg.sender].amount = msg.value;


      addresses.push(msg.sender);
      totalBet = SafeMath.add(totalBet, msg.value);

      if (addresses.length >= 2) {
         
         require(totalBet == SafeMath.add(bets[addresses[0]].amount, bets[addresses[1]].amount));
          player d = duel(bets[addresses[0]].user, bets[addresses[1]].user);
          won(d);
      }
  }


  function won(player _winner) internal{
      uint taxed = SafeMath.div(totalBet, tax);
      uint winnings = SafeMath.sub(totalBet, taxed);

      for(uint i = 0; i < addresses.length; i++){
          address playerAddress = addresses[0];
          bets[playerAddress].user.reset();
          if(bets[playerAddress].user == _winner){
              playerAddress.transfer(winnings);
              
              
              recentWinner = bets[playerAddress].user.getName();
              /* recentwinninghit = bets[playerAddress].user.getHitsplats()[0]; */
          }
      }

      /* displayHits(); */
      /* delete bets[playerAddress]; */

      delete bets[addresses[0]];
      delete bets[addresses[1]];
      addresses.length = 0;
      totalBet = 0;
      

  }


  constructor() public {
      owner = msg.sender;
      tax = 200; //0.5%
      minBet = 10000;
  }

  function getTax() public {
      require(msg.sender == owner);
      msg.sender.transfer(address(this).balance);
  }


}



contract player is roll{

  string public name;
  uint public pid;
  uint public health;
  bool public isPoisoned;
  uint public poisonedTick;
  uint[] public hitsplats;
  string[] public hitspatType;

  uint public attack;
  uint public strength;
  uint public defence;
  uint public constitution;
  attackStyle public style;

  uint public atkBonus;
  uint public defBonus;
  uint public strBonus;


  function atkRoll() public view returns (uint) {
      uint eLevel = SafeMath.add(attack, 8);
      if      (style == attackStyle.accurate)   { eLevel = SafeMath.add(eLevel, 3); }
      else if (style == attackStyle.controlled) { eLevel = SafeMath.add(eLevel, 1); }
      return SafeMath.mul(eLevel, SafeMath.add(atkBonus, 64));
  }

  function defRoll() public view returns (uint) {
      uint eLevel = SafeMath.add(defence, 8);
      if      (style == attackStyle.defensive)  { eLevel = SafeMath.add(eLevel, 3); }
      else if (style == attackStyle.controlled) { eLevel = SafeMath.add(eLevel, 1); }
      return SafeMath.mul(eLevel, SafeMath.add(defBonus, 64));
  }

  function maxHit() public view returns (uint) {
      uint eLevel = strength;
      uint decFactor = 1000000;
      if      (style == attackStyle.aggressive) { eLevel = SafeMath.add(eLevel, 3); }
      else if (style == attackStyle.controlled) { eLevel = SafeMath.add(eLevel, 1); }

      uint a = SafeMath.div(SafeMath.mul(SafeMath.mul(strBonus, eLevel), decFactor), 640);
      uint b = SafeMath.div(SafeMath.mul(strBonus, decFactor), 80);
      uint c = SafeMath.div(SafeMath.mul(eLevel, decFactor), 10);
      uint abc =  SafeMath.add(SafeMath.add(a, b), c);
      uint maxhit = SafeMath.add(SafeMath.mul(13, SafeMath.div(decFactor, 10)), abc);
      return SafeMath.div(maxhit, decFactor);
  }

  function deductHP(uint _hitsplat, string memory _typee) public {
      health = SafeMath.sub(health, _hitsplat);
      hitsplats.push(_hitsplat);
      hitspatType.push(_typee);
  }




  function reset() public {
      health = constitution;
      updatePid();
      isPoisoned = false;
      poisonedTick = 0;
      hitsplats.length = 0;
      hitspatType.length = 0;
  }

  function updatePid() public {
      pid = rand(0, 256^2-1);
  }



  function poisoned(uint _atRound) public {
      isPoisoned = true;
      poisonedTick = _atRound;
  }

  function checkPoisoned() public view returns (bool) {
      return isPoisoned;
  }

  function whenPoisoned() public view returns (uint) {
      return poisonedTick;
  }


  function getName()
  public view returns (string memory){return name;}

  function getHitsplats()
  public view returns (uint[] memory){return hitsplats;}

  function getHP()
  public view returns (uint){return health;}

  function getPID()
  public view returns (uint){return pid;}

  constructor(uint _health, uint _attack, uint _strength, uint _defence, attackStyle _style, uint _atkBonus, uint _strBonus, uint _defBonus, string memory _name) public {
      constitution = _health;
      attack = _attack;
      strength = _strength;
      defence = _defence;
      style = _style;
      atkBonus = _atkBonus;
      defBonus = _defBonus;
      strBonus = _strBonus;
      name = _name;

      reset();
  }
}


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        if(b >= a){
            return 0;
        }
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}
