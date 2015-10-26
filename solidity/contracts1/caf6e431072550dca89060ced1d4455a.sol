contract HighStakesPyramid {
 
    // Global Variables
    uint treeBalance;
    uint numInvestorsMinusOne;
    uint treeDepth;
    address[] myTree;
 
    // Init Constructor
    function HighStakesPyramid() {
        treeBalance = 0;
        myTree.length = 6;
        myTree[0] = msg.sender;
        numInvestorsMinusOne = 0;
    }
   
    // Returns number of Investors.
    function getNumInvestors() constant returns (uint){
        return numInvestorsMinusOne+1;
    }
    
    // Returns the not yet distributed amount (in Wei) of the Contract.
    function getContractBalance() constant returns (uint){
        return treeBalance;
    }
    
    // Returns the number of Investors till the next Level is reached, 
    //  i.e till the next ether distribution round.
    function getNumNextLevel() constant returns (uint){
        return myTree.length - (numInvestorsMinusOne + 1);
    }
    
    // Fallback Function
    function() {
        uint amount = msg.value;
        if (amount>=100*10**18){
            numInvestorsMinusOne+=1;
            myTree[numInvestorsMinusOne]=msg.sender;
            amount-=100*10**18;
            treeBalance+=100*10**18;
            if (numInvestorsMinusOne<=2){
                //myTree[0].send(treeBalance);
                //treeBalance=0;
                treeDepth=1;
            }
            else if (numInvestorsMinusOne+1==myTree.length){
                for(uint i=myTree.length-3*(treeDepth+1);i<myTree.length-treeDepth-2;i++){
                    myTree[i].send(50*10**18);
                    treeBalance-=50*10**18;
                }
                uint eachLevelGets = treeBalance/(treeDepth+1)-1;
                uint numInLevel = 1;
                for(i=0;i<myTree.length-treeDepth-2;i++){
                    myTree[i].send(eachLevelGets/numInLevel-1);
                    treeBalance -= eachLevelGets/numInLevel-1;
                    if (numInLevel*(numInLevel+1)/2 -1== i){
                        numInLevel+=1;
                    }
                }
                myTree.length+=treeDepth+3;
                treeDepth+=1;
            }
        }
        treeBalance+=amount;
    }
}
