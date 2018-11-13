pragma solidity ^0.4.18;
contract setString {

  string public str;
  int public iteration;
  constructor (string _str) public{
    str = _str;
    iteration = 1;
  }

  function changeString(string _str) public{
    str = _str;
    iteration += 1;
  }

}
