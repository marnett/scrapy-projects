contract Users {
    // Here we store the names. Make it public to automatically generate an
    // accessor function named 'users' that takes a string as argument.
    mapping (string32 => address) public users;

    // AUTOGENERATED for public mapping
    //function users(string32 name) returns (address) { 
    //    return users[name]; 
    //}

    // Register the provided name with the caller address.
    // Also, we don't want them to register "" as their name.
    function register(string32 name) {
        if(name != "" && users[name] == 0){
            users[name] = msg.sender;
        }
    }

    // Unregister the provided name with the caller address.
    function unregister(string32 name) {
        if(name != "" && users[name] != 0 && users[name] == msg.sender) {
            users[name] = 0;
        }
    }
}
