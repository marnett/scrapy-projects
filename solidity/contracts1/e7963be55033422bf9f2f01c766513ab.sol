import "assertions/Asserter.sol";

contract Coin {

    address public minter;
    mapping (address => uint) public balances;

    function Coin() {
        minter = msg.sender;
    }

    function mint(address owner, uint amount) {
        if (msg.sender != minter) return;
        balances[owner] += amount;
    }

    function send(address receiver, uint amount) {
        if (balances[msg.sender] < amount) return;
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
    }

}

// Used to interact with the coin contract.
contract CoinAgent {

	// Reference to the coin contract.
	Coin coin;

	// These contracts will be handed the reference to the coin contract by the test contract.
	function CoinAgent(address coinAddress){
		coin = Coin(coinAddress);
	}

	// Call 'mint' on coin.
	function mint(address owner, uint amount) {
		coin.mint(owner, amount);
	}

	// Call 'send' on coin.
	function send(address receiver, uint amount) external {
		coin.send(receiver, amount);
	}
}

contract CoinTest is Asserter {

    // Create a new instance of the 'Coin' contract.
    Coin coin = new Coin();

    // Create a couple of agents.
    CoinAgent minterAgent = new CoinAgent(coin);
    CoinAgent senderAgent = new CoinAgent(coin);
    CoinAgent receiverAgent = new CoinAgent(coin);
    CoinAgent sendFailerAgent = new CoinAgent(coin);
	CoinAgent receiveFailerAgent = new CoinAgent(coin);

    // Gonna use this as a default value for coins.
    uint constant COINS = 5;

    // Test 1 - Are we the minter?
    function testIsMinter() {
        // We created the coin contract, and should therefore be the minter.
        // Use the public accessor for 'minter' to check.
        var minter = coin.minter();

        assertAddressesEqual(minter, address(this), "TestContract is not minter");
    }

    // Test 2 - Can we mint?
	function testMinting() {
		var myAddr = address(this);

		assertAddressesEqual(coin.minter(), address(this), "TestContract is not minter");

		// Mint some coins and send them to ourselves.
		coin.mint(myAddr, COINS);
		var myBalance = coin.balances(myAddr);

		assertUintsEqual(myBalance, COINS, "minter balance is wrong");
	}

	// Test 3 - Can non-minters mint?
	function testMintingWhenNotMinter() {
		// Use 'minterAgent' which has a different address.
		var minterAddr = address(minterAgent);
		minterAgent.mint(minterAddr, COINS);
		var minterBalance = coin.balances(minterAddr);

		assertUintsEqual(minterBalance, 0, "minter balance is not 0");
	}

	// Test 4 - Can coins be sent?
	function testSending() {
		var senderAddr = address(senderAgent);
		var receiverAddr = address(receiverAgent);
		// Mint and pass to sender.
		coin.mint(senderAddr, COINS);

		assertUintsEqual(coin.balances(senderAddr), COINS, "minting failed");

		// Transfer from sender to receiver.
		senderAgent.send(receiverAddr, COINS);
		// Check the receivers balance.
		var receiverBalance = coin.balances(receiverAddr);

		assertUintsEqual(receiverBalance, COINS, "receiver balance is wrong");
	}

	// Test 5 - Can coins be sent even if balance is too low?
	function testSendingWithBalanceTooLow() {
		var sendFailerAddr = address(sendFailerAgent);
		var receiveFailerAddr = address(receiveFailerAgent);
		sendFailerAgent.send(receiveFailerAddr, COINS);
		// Check the receiveFailers balance.
		var receiveFailerBalance = coin.balances(receiveFailerAddr);

		assertUintsEqual(receiveFailerBalance, 0, "receiver was sent coins");
	}

}