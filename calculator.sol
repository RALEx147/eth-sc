pragma solidity ^0.4.18;


contract Calculator {

  int public result;

  constructor() public{
    result = -1;
  }
 
  function calc(string _function, int _var1, int _var2) public returns (int){
    if (checkString(_function, "ADD")){
      result = add(_var1,_var2);
      return result;
    }
    else if (checkString(_function, "SUB")){
      result = sub(_var1,_var2);
      return result;
    }
    else if (checkString(_function, "MULT")){
      result = mult(_var1,_var2);
      return result;
    }
    else if (checkString(_function, "DIV")){
      result = div(_var1,_var2);
      return result;
    }
    else{
      return -1;
    }
  }

  function getFunctionStrings() public pure returns (string){
    return "{\'ADD\',\'SUB\',\'MULT\',\'DIV\',}";
  }




  function checkString(string _function, string _input) private pure returns (bool) {
    return (int(keccak256(abi.encodePacked(_function))) == int(keccak256(abi.encodePacked(_input))));
  }
  function add(int _var1, int _var2) private pure returns (int){
    return _var1 + _var2;
  }
  function sub(int _var1, int _var2) private pure returns (int){
    return _var1 - _var2;
  }
  function mult(int _var1, int _var2) private pure returns (int){
    return _var1 * _var2;
  }
  function div(int _var1, int _var2) private pure returns (int){
    return _var1 / _var2;
  }

}
