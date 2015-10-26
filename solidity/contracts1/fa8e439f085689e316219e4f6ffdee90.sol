contract SimpleStorage {
  uint public storedData;
  uint public storedData2;

  mapping (address => uint) public coinBalanceOf;
  event CoinTransfer(address sender, address receiver, uint amount);

  function SimpleStorage(uint initialValue) {
    storedData = initialValue;
    coinBalanceOf[msg.sender] = 10000;
  }

  function set(uint x) {
    storedData = x;
  }
  function get() constant returns (uint retVal) {
    return storedData;
  }
  function set2(uint x) {
    storedData2 = x;
  }
  function get2() constant returns (uint retVal) {
    return storedData2;
  }

  function sendCoin(address receiver, uint amount) returns(bool sufficient) {
        if (coinBalanceOf[msg.sender] < amount) return false;
        coinBalanceOf[msg.sender] -= amount;
        coinBalanceOf[receiver] += amount;
        CoinTransfer(msg.sender, receiver, amount);
        return true;
  }
}