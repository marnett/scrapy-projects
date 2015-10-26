contract REIT {
    
       struct Property {
       // string owner;
        string property_name;
        uint property_id;//unique key
        uint amount;
        //uint8 no_of_share_holders;
        //uint8 no_of_shares;
        address delegate;
       // mapping (uint8 => ShareHolder) map_shres;
    }
    struct ShareHolder
    {
        
       // uint8 id;//unique key
        uint8 no_of_shares;
        address owner;
    }
   
    mapping (address => ShareHolder) map_shares;
    address admin;
    uint no_of_property;//Total no of properties registered
    uint total_amount;
    uint total_no_of_shares;
    mapping(address => Property) property;//mapping takes propert id and gives respective property struct
    Property[] property_array;
    uint8 Base_Price;
    
    
       function REIT() {
        admin = msg.sender;
        no_of_property = 0;
        
    }

    
   function AddNewProperty(string name, uint id,uint amount,address PropertyAddress) returns(uint property_no)
  {
      if(msg.sender!=admin) return;
      property_no=no_of_property++;
      property[PropertyAddress]=Property(name,id,amount,PropertyAddress);
      total_amount+=amount;
      
  }

function getShareNo(uint8 base_price)
{
 Base_Price=base_price;   
 total_no_of_shares=total_amount/Base_Price;
}
function AssignShares(address holdername,uint8 no_of_shares)
{
 //ShareHolder sh=map_shares(holdername);
map_shares[holdername]=ShareHolder(no_of_shares,holdername);

 
}


 
  function send(address property_add,address sender_add,address receiver_add, uint8 shares) {
        //Property p=property[property_add];
        ShareHolder sender=map_shares[sender_add];
        ShareHolder receiver=map_shares[receiver_add];
        
       
        if (sender.no_of_shares < shares) return;
        sender.no_of_shares -= shares;
        receiver.no_of_shares += shares;
        
    }

 

}
