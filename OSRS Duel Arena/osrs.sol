pragma solidity ^0.5.0;

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
        uint generated = uint(keccak256(abi.encodePacked(nonce, block.number)));
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
      while (health(_player1) > 0 && health(_player2) > 0) {
          uint p1Roll = rand(0, SafeMath.add(decFactor, 1));
          uint p2Roll = rand(0, SafeMath.add(decFactor, 1));
          uint p1Pois = rand(0, 4);
          uint p2Pois = rand(0, 4);
          if (p1Roll < p1Acc){
              if (p1Pois == 3){
                  _player2.poisoned(round);
              }
              uint hitsplatP2 = rand(0, p1Max);
              _player2.deductHP(hitsplatP2, "hit");
          }
          else{ _player2.deductHP(0, "miss"); }
          if (p2Roll < p2Acc){
              if (p2Pois == 3){
                  _player1.poisoned(round);
              }
              uint hitsplatP1 = rand(0, p2Max);
              _player1.deductHP(hitsplatP1, "hit");
          }
          else{ _player1.deductHP(0, "miss"); }

          if (health(_player1) > 0) {	applyPoison(_player1, round); }
          if (health(_player2) > 0) {	applyPoison(_player2, round); }

          round = SafeMath.add(round, 1);
      }
      if (health(_player1) <= 0 && health(_player2) <= 0){
          return (_player1.getPID() < _player2.getPID() ? _player1 : _player2);
      }
      return (health(_player2) > 0 ? _player2 : _player1);
  }


  function accuracy(uint atk, uint def) internal view returns (uint){
      if (atk > def) {
          return SafeMath.div(SafeMath.mul(SafeMath.add(def,2), decFactor), SafeMath.mul(SafeMath.add(atk, 1), 2));
      }
      else{
          return SafeMath.div(SafeMath.mul(atk, decFactor), SafeMath.mul(2, SafeMath.add(def, 1)));

      }
  }


  function applyPoison(player _player, uint round) public{
      if (_player.checkPoisoned()){
          uint poisonTicked = SafeMath.sub(round, _player.whenPoisoned());
          if (poisonTicked >= 7){
              _player.deductHP(4, "p");
              _player.poisoned(round);
          }
      }
  }



  function health(player _player) internal view returns (uint) {
      return _player.getHP();
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
  address payable[] addresses;
  uint public minBet;
  uint public totalBet;
  string public recentWinner;
  uint public recentwinninghit;

  uint public testshowbetslength;
  mapping(address => bet) public bets;

  function join(uint _health, uint _attack, uint _strength, uint _defence, attackStyle _style, uint _atkBonus, uint _strBonus, uint _defBonus, string memory _name/*, player _opponent*/) public payable{
      /* resetDisplays(); */

      player user = new player(_health, _attack, _strength, _defence, _style, _atkBonus, _strBonus, _defBonus, _name);
      bets[msg.sender].user = user;
      bets[msg.sender].amount = msg.value;


      addresses.push(msg.sender);
      totalBet = SafeMath.add(totalBet, msg.value);

      if (addresses.length >= 2) {
          require(totalBet == SafeMath.add(bets[addresses[0]].amount, bets[addresses[1]].amount));
          won(duel(bets[addresses[0]].user, bets[addresses[1]].user));
      }
  }


  function won(player _winner) internal{
      uint taxed = SafeMath.div(totalBet, tax);
      uint winnings = SafeMath.sub(totalBet, taxed);

      for(uint i = 0; i < addresses.length; i++){
          address payable playerAddress = addresses[i];
          bets[playerAddress].user.reset();
          if(bets[playerAddress].user == _winner){
              playerAddress.transfer(winnings);
              /* recentWinner = bets[playerAddress].user.getName(); */
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
