    contract REIT {
        address admin;
        struct Customer {
            //uint position;
            bool cust_type;
            uint amount;
            address account_no;
        }
        
        
        mapping(address => Customer) map_cust;
        Customer[] customer;
      

      
        function REIT() {
            admin = msg.sender;
            customer.length = 0;
        }


     function send(address sender,address receiver, uint amount) {
            Customer send_c =map_cust[sender];
            Customer recv_c =map_cust[receiver];
            if (send_c.amount < amount) return;
            send_c.amount -= amount;
            recv_c.amount += amount;
            //Send(msg.sender, receiver, amount);
        }


    function addUser(address account_number,uint amount)
    {
        if(msg.sender!=admin) return;
        else
        {
            customer.length+=1;
            //customer[customer.length].position=customer.length;
            customer[customer.length].cust_type=false;
            customer[customer.length].account_no=account_number;
             customer[customer.length].amount=amount;
        }

    }

    function addMerchant(address account_number,uint amount)
    {
        if(msg.sender!=admin) return;
        else
        {
            customer.length+=1;
            //customer[customer.length].position=customer.length;
            customer[customer.length].cust_type=true;
            customer[customer.length].account_no=account_number;
             customer[customer.length].amount=amount;
        }

    }

    }