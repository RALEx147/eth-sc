//Write your own contracts here. Currently compiles using solc v0.4.15+commit.bbb8e64f.
pragma solidity ^0.4.20;

contract generateInt {
  uint256 public result;
  uint256 public nonce;

  constructor() public{
    result = generateNumberWinner();

  }




  function random() public returns (uint) {
    uint out = uint(keccak256(abi.encodePacked(now, msg.sender, nonce))) % 10;
    nonce++;
    result = out;
    return out;
  }

  function generateNumberWinner() public view returns (uint) {
      return block.number % 10 + 1; // This isn't secure
   }




}

contract random{
uint nonce = 0;
function rand(uint min, uint max) public returns (uint){
    nonce++;
    result = uint(keccak256(abi.encodePacked(nonce)))%(min+max)-min;
    return result;
}
}
