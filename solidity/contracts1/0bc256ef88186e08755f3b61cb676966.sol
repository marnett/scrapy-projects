contract metaCoin {
  mapping(address => uint) balances;
  function metaCoin(){
    balances[msg.sender] = 10000;
  }
  funtion sendCoin(address receiver, uint amount) returns(bool sufficient) {
    if(balances[msg.sender] < amount) return false;
    balances[msg.sender] -= amount;
    balances[receiver] += amount;
    return true;
  }
}


var metaCoin = web3.eth.contractFromAbi([{"constant":false,"inputs":[{"name":"receiver","type":"address"},{"name":"amount","type":"uint256"}],"name":"sendCoin","outputs":[{"name":"sufficient","type":"bool"}],"type":"function"}]);
contract metaCoin{function sendCoin(address receiver,uint256 amount)returns(bool sufficient){}}
90b98a11… :sendCoin