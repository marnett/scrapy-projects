contract ACL {
    address admin;
//    uint no_of_rules;
    struct rule{

        uint source_ip;
        uint source_port;
        uint destination_ip;
        uint destination_port;
        bool state; // allow true deny false
        address user;
    }
    mapping(address => rule) map_rule;
    struct acl{
        rule[] rules;
    }
    acl acl_list;

    function ACL()
    {
    admin=msg.sender;
    }

    function addRules(uint source_ip,uint source_port,uint receiver_ip,uint receiver_port,address user_add,bool state)
    {
        if(msg.sender != admin) return;
        acl_list.rules.length=acl_list.rules.length++;
        acl_list.rules[acl_list.rules.length]=rule(source_ip, source_port, receiver_ip,receiver_port, state, user_add);

    }
    function removeRules(address user_add)
    {
    if(msg.sender != admin) return;
        delete map_rule[user_add];

    }
}
