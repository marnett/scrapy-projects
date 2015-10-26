contract Roulette {

    // -------------------------------------------------------------------------
    //  GLOBAL VARIABLES
    // -------------------------------------------------------------------------
    string sWelcome;
    /* Remark 1:
     *  Contract Seed for generateRand(),
     *  adds an additional degree of 'randomness'
     */
    uint conSeed;
    uint bettingLimitMin;
    uint bettingLimitMax;
    /* Remark 2:
     *  depositLimit is an attempt to protect the players
     *  by limiting the amount they can deposit.
     */
    uint depositLimit;

    // Casino
    struct Casino {
        address owner;
        uint balance;
    }
    Casino casino;

    // Users
    struct Bet {
        uint blockNumber;
        uint betChoice;
        uint betSize;
        uint winFactor; /* possible Win Factor */
        bool processed;
    }
    struct User {
        address addr;
        uint balance;
        uint deposit;
        uint id;
        Bet[] bets;
    }
    User[] users;
    mapping (address => uint) usersByAddr;


    // -------------------------------------------------------------------------
    //  INIT CONSTRUCTOR
    // -------------------------------------------------------------------------
    function Roulette() {
        sWelcome = "\n-----------------------------\n     Welcome to Roulette \n Got coins? Then come on in! \n-----------------------------\n";
        // General Variables
        conSeed = 1;
        bettingLimitMin = 1*10**18;
        bettingLimitMax = 100*10**18;
        depositLimit = 1000*10**18;
        // Casino
        casino.owner = msg.sender;
        casino.balance = 0;
        // Users
        users.length = 0;
    }


    // -------------------------------------------------------------------------
    //  CASINO ACCOUNT INFORMATION
    // -------------------------------------------------------------------------
    // Constant Functions
    // Casino
    function welcome() constant returns (string) {
        return sWelcome;
    }
    function casinoBalance() constant returns (uint) {
        return casino.balance;
    }


    // -------------------------------------------------------------------------
    //  USER ACCOUNT INFORMATION, BALANCE MANIPULATION
    // -------------------------------------------------------------------------
    // Constant Functions
    // Show Deposited amount of user
    // Pre: Existing User
    // Post: returns userDepositedAmount
    function userDepositedAmount() constant returns (uint) {
        uint userId = usersByAddr[msg.sender];
        if (userId != 0)
            return users[userId - 1].deposit;
        else
            return 0;
    }
    // Update User Balance
    // Pre: Existing User
    // Post: returns userBalance, but does NOT execute pending bets.
    function nonUpdatedBalance() returns (uint) {
        uint userId = usersByAddr[msg.sender];
        if (userId != 0)
            return users[userId - 1].balance;
        else
            return 0;
    }
    // Non-Constant Functions
    // User Deposit
    // Pre: Deposit betw. 0.1 ETH and 100 ETH
    // Post: Changed user.balance and casino.balance accordingly
    function deposit() public returns (bool) {
        // Input Handling
        address addr = msg.sender;
        uint amount = msg.value;
        if (amount < bettingLimitMin || amount > bettingLimitMax) {
            // Return Funds
            if (amount >= bettingLimitMin)
                addr.send(amount);
            return false;
        }
        // Is new Player?
        // Yes.
        /* Note:
         *  Mappings can be seen as hashtables which are virtually initialized
         *  such that every possible key exists and is mapped to a value
         *  whose byte-representation is all zeros.
         */
        if (usersByAddr[msg.sender] == 0) {
            // Exexcute
            users.length += 1;
            users[users.length - 1].balance = amount;
            users[users.length - 1].deposit = amount;
            users[users.length - 1].id = users.length;
            users[users.length - 1].bets.length = 0;
            usersByAddr[msg.sender] = users[users.length - 1].id;
            casino.balance += amount;
            return true;
        }
        // No.
        else {
            uint userId = usersByAddr[msg.sender];
            // Player Protection
            if (users[userId - 1].deposit + amount > depositLimit) {
                // Return Funds
                if (amount >= bettingLimitMin)
                    addr.send(amount);
                return false;
            }
            // Execute
            users[userId - 1].balance += amount;
            users[userId - 1].deposit += amount;
            casino.balance += amount;
            return true;
        }
    }
    // User withdraw
    // Pre: Existing User; Valid Amount
    // Post: Changed user.balance and casino.balance accordingly
    function withdraw(uint amount) public returns (bool) {
        // Non-Existing User
        uint userId = usersByAddr[msg.sender];
        if (userId == 0)
            return false;
        // Existing User but withdrawal amount is invalid
        uint userBalance = users[userId - 1].balance;
        if (amount < 1*10**18 || amount > userBalance)
            return false;
        // Existing User and withdrawal amount is valid
        else {
            users[userId - 1].balance -= amount;
            users[userId - 1].addr.send(amount);
            casino.balance -= amount;
            return true;
        }
    }


    // -------------------------------------------------------------------------
    //  BETTING
    // -------------------------------------------------------------------------
    // Bet on Number
    // Pre:
    //  i) Existing User
    //  ii) Input number betw. 0 and 36
    //  iii) Betting Limit Max reduced by factor ten.
    // Post: Changed user.balance and casino.balance accordingly
    function betOnNumber(uint number, uint betSize) public returns (string) {
        // Input Handling
        address addr = msg.sender;
        uint userId = usersByAddr[addr];
        if (userId == 0) {
            return "Non-Existing User";
        }
        if (betSize < bettingLimitMin || betSize > bettingLimitMax / 10) {
            return "Please choose an amount between 0.1 and 10 ETH";
        }
        if (betSize * 36 > casino.balance) {
            return "Casino has insufficient funds for this bet amount";
        }
        if (betSize > users[userId - 1].balance) {
            return "User has insufficient funds";
        }
        if (number < 0 || number > 36) {
            return "Please choose a number between 0 and 36";
        }
        // Storage Bet Data
        users[userId - 1].bets.length += 1;
        uint numBets = users[userId - 1].bets.length;
        users[userId - 1].bets[numBets - 1].blockNumber = block.number;
        users[userId - 1].bets[numBets - 1].betChoice = number;
        users[userId - 1].bets[numBets - 1].betSize = betSize;
        users[userId - 1].bets[numBets - 1].winFactor = 36;
        users[userId - 1].bets[numBets - 1].processed = false;
        // Bookkeeping
        users[userId - 1].balance -= betSize;
        casino.balance += betSize;
        return "Bet executed and pending!";
    }
    // Dozen Bet
    // Pre: Input Dozen is '0' = Bet on 1-12, '1' = Bet on 13-24 or '2' = Bet on 25-36
    // Post: Changed user.balance and casino.balance accordingly
    function betOnDozen(uint dozen, uint betSize) public returns (string) {
        // Input Handling
        address addr = msg.sender;
        uint userId = usersByAddr[addr];
        if (userId == 0) {
            return "Non-Existing User";
        }
        if (betSize < bettingLimitMin || betSize > bettingLimitMax) {
            return "Please choose an amount between 0.1 and 100 ETH";
        }
        if (betSize * 3 > casino.balance) {
            return "Casino has insufficient funds for this bet amount";
        }
        if (betSize > users[userId - 1].balance) {
            return "User has insufficient funds";
        }
        if (dozen < 0 || dozen > 2) {
            return "Please choose a number between '0' = Bet on 1-12, '1' = Bet on 13-24 or '2' = Bet on 25-36";
        }
        // Storage Bet Data
        users[userId - 1].bets.length += 1;
        uint numBets = users[userId - 1].bets.length;
        users[userId - 1].bets[numBets - 1].blockNumber = block.number;
        users[userId - 1].bets[numBets - 1].betChoice = dozen;
        users[userId - 1].bets[numBets - 1].betSize = betSize;
        users[userId - 1].bets[numBets - 1].winFactor = 3;
        users[userId - 1].bets[numBets - 1].processed = false;
        // Bookkeeping
        users[userId - 1].balance -= betSize;
        casino.balance += betSize;
        return "Bet executed and pending!";
    }
    // Bet on Color
    // Pre: Input Dozen is '0' = Bet on 1-12, '1' = Bet on 13-24 or '2' = Bet on 25-36
    // Post: Changed user.balance and casino.balance accordingly
    function betOnColor(uint color, uint betSize) public returns (string) {
        // Input Handling
        address addr = msg.sender;
        uint userId = usersByAddr[addr];
        if (userId == 0) {
            return "Non-Existing User";
        }
        if (betSize < bettingLimitMin || betSize > bettingLimitMax) {
            return "Please choose an amount between 0.1 and 100 ETH";
        }
        if (betSize * 2 > casino.balance) {
            return "Casino has insufficient funds for this bet amount";
        }
        if (betSize > users[userId - 1].balance) {
            return "User has insufficient funds";
        }
        if (color != 0 && color != 1) {
            return "Please choose either '0' = red or '1' = black as a color";
        }
        // Storage Bet Data
        users[userId - 1].bets.length += 1;
        uint numBets = users[userId - 1].bets.length;
        users[userId - 1].bets[numBets - 1].blockNumber = block.number;
        users[userId - 1].bets[numBets - 1].betChoice = color;
        users[userId - 1].bets[numBets - 1].betSize = betSize;
        users[userId - 1].bets[numBets - 1].winFactor = 2;
        users[userId - 1].bets[numBets - 1].processed = false;
        // Bookkeeping
        users[userId - 1].balance -= betSize;
        casino.balance += betSize;
        return "Bet executed and pending!";
    }


    // -------------------------------------------------------------------------
    //  PSEUDO RANDOM ALGORITHM
    // -------------------------------------------------------------------------
    // Returns a pseudo Random number.
    // Pre: Current Block Data, Contract intern var.
    // Post: Generates a Pseudo Rand Number
    function generateRand() private returns (uint) {
        // Seeds
        conSeed = 7*(conSeed*(conSeed + 1));
        conSeed = conSeed % 10**12;
        uint number = 5*block.number; // ~ 10**5 ; 60000
        uint diff = 1*block.difficulty; // ~ 2 Tera = 2*10**12; 1731430114620
        uint time = 2*block.timestamp; // ~ 2 Giga = 2*10**9; 1439147273
        uint gas = 3*block.gaslimit; // ~ 3 Mega = 3*10**6
        // Rand Number
        uint total = 11*(conSeed + number + diff + time + gas);
        uint rand = total % 40;
        return rand;
    }
    // Process Bet
    // Pre: Initialized User, i.e. User who deposited already.
    // Post: Returns true if all Bets have been processed, false if not.
    function processBets(uint userId) private returns (bool) {
        // Iterate over all Bets
        User user = users[userId - 1];
        uint numBets = user.bets.length;
        for (uint b = 0; b < numBets; ++b) {
            // Processed already
            if (user.bets[b].processed == true)
                continue;
            // Too early
            if (block.number < user.bets[b].blockNumber + 2)
                continue;
            // Roll the wheel
            conSeed += 1;
            uint rand = generateRand();
            bool won = false;
            // Bet on Number
            if (user.bets[b].winFactor == 36) {
                // Win
                if (user.bets[b].betChoice == rand)
                    won = true;
            }
            // Bet on Dozen
            if (user.bets[b].winFactor == 3) {
                uint randD = (rand + 1) % 3;
                // Win
                if (rand != 0 && (randD == user.bets[b].betChoice) && rand != 37 && rand != 38 && rand != 39)
                    won = true;
            }
            // Bet on Color
            if (user.bets[b].winFactor == 2) {
                uint randC = (rand + 1) % 2;
                if (rand != 0 && (randC == user.bets[b].betChoice) && rand != 37 && rand != 38 && rand != 39)
                    won = true;
            }

            // Bookkeeping
            if (won == true) {
                uint winAmount = user.bets[b].betSize * user.bets[b].winFactor;
                user.balance += winAmount;
                casino.balance -= winAmount;
            }
            // Flag processed
            user.bets[b].processed = true;
        }

        // Delete bets Array, if all bets are processed.
        bool allBetsProcessed = true;
        for (uint8 b_ = 0; b_ < numBets; ++b_) {
            if (user.bets[b_].processed == false)
                allBetsProcessed = false;
        }
        if (allBetsProcessed == true) {
            delete user.bets;
            return true;
        }
        else
            return false;
    }
    // Update User Balance
    // Pre: Existing User
    // Post: returns userBalance, executes pending bets if possible.
    function updateBalance() returns (uint) {
        uint userId = usersByAddr[msg.sender];
        // Non-Existing Player
        if (userId == 0)
            return 0;
        uint userBets = users[userId - 1].bets.length;
        // No Pending Transactions
        if (userBets == 0)
            return users[userId - 1].balance;
        else {
            processBets(userId);
            return users[userId - 1].balance;
        }
    }


    // -------------------------------------------------------------------------
    //  KILL CONTRACT
    // -------------------------------------------------------------------------
    // Function to recover the funds on the contract
    function kill() {
        if (msg.sender != casino.owner)
            return;
        // Return User Funds
        for (uint u = 0; u < users.length; ++u) {
            users[u].addr.send(users[u].balance);
        }
        // Return my Funds and kill Contract
        suicide(casino.owner);
    }
}
