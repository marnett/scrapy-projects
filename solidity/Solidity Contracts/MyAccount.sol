
contract MyAccount{

   bytes32 name = "Roman";
   address owner = 0xcd2a3d9f938e13cd947ec05abc7fe734df8dd827;
   uint balance = 1000000;
   

   function addToBalance(uint to_add){
		balance = balance + to_add;   
   }

   function subFromBalance(uint to_sub){
        balance = balance - to_sub;  
   }


}

   