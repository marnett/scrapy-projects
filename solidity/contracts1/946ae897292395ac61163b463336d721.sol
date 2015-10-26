contract ticketer {
    address admin;
    uint time;
    uint tickets;
    uint price;
    uint initialticks;
    uint lastbuy;
    uint last_price;
    struct Movie {
        uint ticket;
        address account_no;
        uint time;
        }
    mapping(address => Movie) map_mov;
    Movie[] movie;
    function ticker() {
        admin = msg.sender;
        movie.length = 0 ;
    }   

    function addtickets (address account, uint tics, uint prices) {
        if (msg.sender != admin ) return ;
        else 
        {
            tickets =  tics;
            price = prices;
            time = block.timestamp;
            initialticks = tics;
        }
    }
    function getprice ( uint tickets, uint price , uint initialticks , uint lastbuy, uint time){
        last_price=((1+(((initialticks-tickets)/initialticks)/4))*(1+(((lastbuy-time)/time)/4))*price);
    }
    function gettics ( address account_no ,uint _value,uint tickets, uint price , uint initialticks , uint lastbuy, uint time){
        getprice(tickets,  price ,  initialticks ,  lastbuy,  time);
        if (msg.value < last_price) return ; 
        else{
            movie.length+=1;
            movie[movie.length].ticket= 1;
            movie[movie.length].account_no=msg.sender;
            movie[movie.length].time=block.timestamp;
            tickets -= 1;
            lastbuy=block.timestamp;
            if (tickets == 0 ) {
                sucide(admin);
            }
        }
    }
}  