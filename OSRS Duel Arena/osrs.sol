pragma solidity ^0.4.18;


contract roll{

  uint nonce = 0;
  function rand(uint min, uint max) internal returns (uint){
      nonce++;
      return uint(keccak256(abi.encodePacked(nonce, block.number)))%(max-min)+min;
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
    	while (_player1.getHP() > 0 && _player2.getHP() > 0) {
      		uint p1Roll = rand(0, decFactor);
      		uint p2Roll = rand(0, decFactor);
          uint p1Pois = rand(0, 3);
          uint p2Pois = rand(0, 3);
      		if (p1Roll < p1Acc){
              if (p1Pois == 3){
                  _player2.poisoned(round);
              }
        			uint hitsplatP2 = rand(0, p1Max);
        			_player2.deductHP(hitsplatP2);
      		}
      		if (p2Roll < p2Acc){
              if (p2Pois == 3){
                  _player1.poisoned(round);
              }
        			uint hitsplatP1 = rand(0, p2Max);
        			_player1.deductHP(hitsplatP1);
      		}
          if (_player1.checkPoisoned()){
              /* if (round - _player1.whenPoisoned() >= 7){ */
                  _player1.deductHP(4);
                  _player1.poisoned(round);
              /* } */
          }
          if (_player2.checkPoisoned()){
              /* if (round - _player2.whenPoisoned() >= 7){ */
                  _player2.deductHP(4);
                  _player2.poisoned(round);
              /* } */
          }
      		round += 1;
      	}
      	if (_player1.getHP() <= 0 && _player2.getHP() <= 0){
      		  return (_player1.getPID() < _player2.getPID() ? _player1 : _player2);
      	}
      	return (_player2.getHP() > 0 ? _player2 : _player1);
  }


  function accuracy(uint atk, uint def) internal view returns (uint){
    	if (atk > def) {
    		  return decFactor - (((def + 2) * decFactor) / ((2 * (atk + 1))));
    	}
    	else{
    		  return atk * decFactor / (2 * (def + 1));
          //SafeMath.div(SafeMath.mul(atk, decFactor), SafeMath.mul(2, SafeMath.add(def, 1)));
    	}
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
    address[] addresses;
    uint public minBet;
    uint public totalBet;
    string public recentWinner;
    uint public recentwinninghit;


    mapping(address => bet) bets;

    function join(uint _health, uint _attack, uint _strength, uint _defence, attackStyle _style, uint _atkBonus, uint _strBonus, uint _defBonus, string _name/*, player _opponent*/) public payable{
        /* resetDisplays(); */

        player user = new player(_health, _attack, _strength, _defence, _style, _atkBonus, _strBonus, _defBonus, _name);
        bets[msg.sender].user = user;
        bets[msg.sender].amount = msg.value;


        addresses.push(msg.sender);
        totalBet += msg.value;

        if (addresses.length >= 2) {
            require(totalBet == bets[addresses[0]].amount + bets[addresses[1]].amount);
            won(duel(bets[addresses[0]].user, bets[addresses[1]].user));
        }
    }


    function won(player winner) internal{
        uint taxed = totalBet / tax;
        uint winnings = totalBet - taxed;

        for(uint i = 0; i < addresses.length; i++){
            address playerAddress = addresses[i];
            bets[playerAddress].user.reset();
            if(bets[playerAddress].user == winner){
                playerAddress.transfer(winnings);
                /* recentWinner = bets[playerAddress].user.getName(); */
                /* recentwinninghit = bets[playerAddress].user.getHitsplats()[0]; */
            }
        }



        /* displayHits(); */
        delete bets[playerAddress];
        /*
        delete bets[addresses[0]];
        delete bets[addresses[1]]; */
        addresses.length = 0;
        totalBet = 0;

    }


    constructor() public {
        owner = msg.sender;
        tax = 200; //0.5%
        minBet = 10000;
    }

    /* function getTax() public {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    } */


}



contract player is roll{

    string public name;
  	uint public pid;
  	uint public health;
    bool public isPoisoned;
    uint public poisonedTick;
    /* uint[] public hitsplats; */


  	uint public attack;
  	uint public strength;
  	uint public defence;
    uint public constitution;
  	attackStyle public style;

  	uint public atkBonus;
  	uint public defBonus;
  	uint public strBonus;


    function atkRoll() public view returns (uint) {
        uint eLevel = attack + 8;
        if (style == attackStyle.accurate) { eLevel += 3; }
        else if (style == attackStyle.controlled) { eLevel += 1; }
        return eLevel * (atkBonus + 64);
    }

    function defRoll() public view returns (uint) {
        uint eLevel = defence + 8;
        if (style == attackStyle.defensive) { eLevel += 3; }
        else if (style == attackStyle.controlled) { eLevel += 1; }
        return eLevel * (defBonus + 64);
    }

    function maxHit() public view returns (uint) {
        uint eLevel = strength;
        uint decFactor = 1000000;
        if (style == attackStyle.aggressive) { eLevel += 3; }
        else if (style == attackStyle.controlled) { eLevel += 1; }

        uint a = (strBonus * eLevel * decFactor / 640);
        uint b = (strBonus* decFactor / 80);
        uint c = (eLevel* decFactor / 10);
        uint maxhit = 13 * SafeMath.div(decFactor, 10) + a + b + c;
        return maxhit / decFactor;
    }

    function deductHP(uint _hitsplat) public {
        health -= _hitsplat;
        /* hitsplats.push(_hitsplat); */
    }


    function getHP() public view returns (uint){
        return health;
    }

    function reset() public {
        health = constitution;
        updatePid();
        isPoisoned = false;
        poisonedTick = 0;
        /* hitsplats.length = 0; */
    }

    function updatePid() public {
        pid = rand(0, 256^2-1);
    }

    function getPID() public view returns (uint){
        return pid;
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

    function getName() public view returns (string){
        return name;
    }


    /* function getHitsplats() public view returns (uint[]){
        return hitsplats;
    } */

    constructor(uint _health, uint _attack, uint _strength, uint _defence, attackStyle _style, uint _atkBonus, uint _strBonus, uint _defBonus, string _name) public {
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
        require(b <= a);
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
