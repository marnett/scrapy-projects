contract SharedMining {

     address owner;
     
     struct Share {
        address addr;
        bytes32 name;
        uint qte;
     }

     uint holderindex;
     mapping (uint => Share) share_holder;
     //actually 1000 -> 100%
     function SharedMining(){
        owner = msg.sender;
        share_holder[0].addr=msg.sender;
        share_holder[0].name = 'admin';
        share_holder[0].qte = 1000;
        holderindex +=1;
     }

     function hadShareholder(address holder, bytes32 name, uint qte ) returns (bool){

        if(msg.sender != owner)
                return false;
        if (qte >= 1000) 
                return false;

        uint subshare = qte / holderindex;
        for (uint i = 0; i < holderindex; i++){

                share_holder[i].qte -= subshare;
        }
        share_holder[holderindex].addr = holder;
        share_holder[holderindex].name = name;
        share_holder[holderindex].qte = qte;
        holderindex+=1;
        return true;

     
     }

     
     function getShareholderName(uint idx) returns (bytes32){
        if (idx < holderindex)
                return share_holder[idx].name;
        return '';

     }

     function getShareholderQte(uint idx) returns (uint){
        if (idx < holderindex)
                return share_holder[idx].qte;
        return 0;

     }

     function getShareholderAddr(uint idx) returns (address){
        if (idx < holderindex)
                return share_holder[idx].addr;
        return 0x0;

     }





}
