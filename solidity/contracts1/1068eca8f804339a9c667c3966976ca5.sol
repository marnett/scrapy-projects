contract SimpleStorage {

    uint storedData;
    // uint romanData;
    bytes32 stringData = "cow"; 
    bytes32 shaCow;
    address sAddr = 0xcd2a3d9f938e13cd947ec05abc7fe734df8dd826;
    
    
    function SimpleStorage() {// my comment
        
        uint i = 0; // here I am fixing 
        while (i < 2000){
            ++i; // another change 
        }
        
        storedData = 5;
        // romanData = storedData / 2;
        // stringData = "Roman";
        shaCow = sha3(stringData);
    }
    
    function set(uint x) {
        storedData = x;
    }
    function get() constant returns (uint retVal) {
        return storedData;
    }
}