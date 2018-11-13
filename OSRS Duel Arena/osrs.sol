pragma solidity ^0.4.18;


contract roll{

  uint nonce = 0;
  function rand(uint min, uint max) internal returns (uint){
      nonce++;
      return uint(keccak256(abi.encodePacked(nonce)))%(max-min)+min;
  }

  enum attackStyle{
    aggressive,
    accurate,
    defensive,
    controlled
  }


}


contract osrs is roll {

  address public owner;
  uint private decFactor = 1000000000000;

  uint[] public hitsplatsP1;
  uint[] public hitsplatsP2;

  mapping(address => uint[]) hitsplats;
  function duel(player _player1, player _player2) public returns (player){
      resetDuel();

    	uint p1Acc = accuracy(_player1.atkRoll(), _player2.defRoll());
    	uint p2Acc = accuracy(_player2.atkRoll(), _player1.defRoll());

    	uint p1Max = _player1.maxHit();
    	uint p2Max = _player2.maxHit();

    	uint round = 0;
    	while (_player1.getHP() > 0 && _player2.getHP() > 0) {
      		uint p1Roll = rand(0, decFactor);
      		uint p2Roll = rand(0, decFactor);
      		if (p1Roll < p1Acc){
        			uint hitsplatP2 = rand(0, p1Max);
        			_player2.deductHP(hitsplatP2 * decFactor);
              hitsplatsP2.push(hitsplatP2);
      		}
      		if (p2Roll < p2Acc){
        			uint hitsplatP1 = rand(0, p2Max);
        			_player1.deductHP(hitsplatP1 * decFactor);
              hitsplatsP1.push(hitsplatP1);
      		}
      		round += 1;
      	}
      	if (_player1.getHP() <= 0 && _player2.getHP() <= 0){
      		  return (_player1.getPID() < _player2.getPID() ? _player1 : _player2);
      	}
      	return (_player2.getHP() > 0 ? _player2 : _player1);
  }


  function accuracy(uint atk, uint def) public constant returns (uint){
    	if (atk > def) {
    		  return decFactor - (((def + 2) * decFactor) / ((2 * (atk + 1))));
    	}
    	else{
    		  return atk * decFactor / (2 * (def + 1));
    	}
  }

  function resetDuel() public {
      hitsplatsP1.length = 0;
      hitsplatsP2.length = 0;
  }




}

contract DuelArena is osrs{
    struct bet {
        uint amount;
        player user;
        player opponent;
    }
    uint public tax;
    uint public minBet;
    uint public totalBet;
    address public owner;
    address[] public addresses;

    mapping(address => bet) bets;

    function join(uint _health, uint _attack, uint _strength, uint _defence, attackStyle _style, uint _atkBonus, uint _strBonus, uint _defBonus, string _name/*, player _opponent*/) public payable{

        player user = new player(_health, _attack, _strength, _defence, _style, _atkBonus, _strBonus, _defBonus, _name);
        bets[msg.sender].user = user;
        bets[msg.sender].amount = msg.value;
        /* bets[msg.sender].opponent = _opponent; */

        addresses.push(msg.sender);

        if (addresses.length >= 2) {
            totalBet = bets[addresses[0]].amount + bets[addresses[1]].amount;
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
            }
        }

        delete bets[playerAddress];
        addresses.length = 0;
        totalBet = 0;
        resetDuel();

    }


    constructor() public {
        owner = msg.sender;
        tax = 200; //0.5%
        minBet = 10000;
    }


}



contract player is roll{

    string public name;
  	uint public pid;
  	uint public health;

  	uint public decFactoritution;
  	uint public attack;
  	uint public strength;
  	uint public defence;
    uint public constitution;
  	attackStyle public style;

  	uint public atkBonus;
  	uint public defBonus;
  	uint public strBonus;


    function atkRoll() public constant returns (uint) {
        uint eLevel = attack + 8;
        if (style == attackStyle.accurate) { eLevel += 3; }
        else if (style == attackStyle.controlled) { eLevel += 1; }
        return eLevel * (atkBonus + 64);
    }

    function defRoll() public constant returns (uint) {
        uint eLevel = defence + 8;
        if (style == attackStyle.defensive) { eLevel += 3; }
        else if (style == attackStyle.controlled) { eLevel += 1; }
        return eLevel * (defBonus + 64);
    }

    function maxHit() public constant returns (uint) {
        uint eLevel = strength;
        uint decFactor = 10000;
        if (style == attackStyle.aggressive) { eLevel += 3; }
        else if (style == attackStyle.controlled) { eLevel += 1; }

        uint a = (strBonus * eLevel * decFactor / 640);
        uint b = (strBonus* decFactor / 80);
        uint c = (eLevel* decFactor / 10);
        uint maxhit = 13000 + a + b + c;
        return maxhit / decFactor;
    }

    function deductHP(uint _hitsplat) public {
        health -= _hitsplat;
    }

    function getHP() public constant returns (uint){
       return health;
    }

    function reset() public {
        health = constitution;
        updatePid();
    }

    function updatePid() public {
        pid = rand(0, 256^2-1);
    }

    function getPID() public constant returns (uint){
       return pid;
    }

    constructor(uint _health, uint _attack, uint _strength, uint _defence, attackStyle _style, uint _atkBonus, uint _strBonus, uint _defBonus, string _name) public {
        health = _health;

    		constitution = _health;
    		attack = _attack;
    		strength = _strength;
    		defence = _defence;
    		style = _style;

    		atkBonus = _atkBonus;
    		defBonus = _defBonus;
    		strBonus = _strBonus;
    		name = _name;
    		pid = rand(0, 256^2 - 1);
    }





}
