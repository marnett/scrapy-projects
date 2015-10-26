import "assertions/Asserter.sol";
import "Bank.sol";

contract AccountOwner {

    Bank bank;

    function AccountOwner(address bankAddr){
        bank = Bank(bankAddr);
    }

    function endow(bytes32 to, uint amount) external returns (uint16 result){
        return bank.endow(to, amount, "...");
    }

    function registerNewAccount(bytes32 name) external returns (uint16 result) {
        return bank.registerNewAccount(name);
    }

    function deleteAccount(bytes32 name) external returns (uint16 result) {
        return bank.deleteAccount(name);
    }

    function transfer(bytes32 to, uint amount) external returns (uint16 result){
        return bank.transfer(to, amount, "...");
    }

}

/// @title BankTest
/// @author Andreas Olofsson (andreas@erisindustries.com)
// Note most of these tests does not count as towards coverage, since the transfer method
// is called via another account. Should add support for this in s-unit.
contract BankTest is Asserter {

    // Error codes from Bank.

    // General.
    uint8 constant SUCCESS = 0; // Success.
    // Account related.
    uint8 constant NO_ACCOUNT = 10; // Caller has no account.
    uint8 constant ACCOUNT_EXISTS = 11; // Caller already has an account.
    uint8 constant NO_TARGET = 12; // Recipient does not have an account.
    uint8 constant NOT_OWNER = 13; // Caller is not owner.
    // Balance related
    uint8 constant NO_AMOUNT = 20; // Transacted amount is 0.
    uint8 constant INSUFFICIENT_BALANCE = 21; // Insufficient balance.

    uint constant TEST_BALANCE = 1000;

    Bank testee;
    AccountOwner testReg;
    AccountOwner testRegFail;
    AccountOwner testDelete;
    AccountOwner testEndow;
    AccountOwner testEndowFailer;
    AccountOwner testTransferer;
    AccountOwner testTransferee;
    AccountOwner testTransfererBalanceCheck;
    AccountOwner testTransfereeBalanceCheck;
    AccountOwner testTransfererNoAccount;
    AccountOwner testTransfererNoAmount;
    AccountOwner testTransfererInsufficientBalance;
    AccountOwner testTransfererNoTarget;

    function BankTest(){
        testee = new Bank();
        testReg = new AccountOwner(address(testee));
        testRegFail = new AccountOwner(address(testee));
        testDelete = new AccountOwner(address(testee));
        testEndow = new AccountOwner(address(testee));
        testEndowFailer = new AccountOwner(address(testee));
        testTransferer = new AccountOwner(address(testee));
        testTransferee = new AccountOwner(address(testee));
        testTransfererBalanceCheck = new AccountOwner(address(testee));
        testTransfereeBalanceCheck = new AccountOwner(address(testee));
        testTransfererNoAccount = new AccountOwner(address(testee));
        testTransfererNoAmount = new AccountOwner(address(testee));
        testTransfererInsufficientBalance = new AccountOwner(address(testee));
        testTransfererNoTarget = new AccountOwner(address(testee));
    }

    function testOwnerSucceeding(){
        var owner = testee.owner();
        assertAddressesEqual(owner, address(this), "owner address does not match.");
    }

    function testGetMyAddress(){
        var myAddrs = testee.getMyAddress();
        assertAddressesEqual(myAddrs, address(this), "owner address does not match.");
    }

    function testRegisterAccount(){
        var ret = testReg.registerNewAccount("testReg");
        assertUintsEqual(ret, SUCCESS, "registration failed");
    }

    function testRegisterAccountFailAlreadyExists(){
        var ret = testRegFail.registerNewAccount("testReg");
        var ret2 = testRegFail.registerNewAccount("testReg");
        assertUintsEqual(uint(ret2), ACCOUNT_EXISTS, "registration succeeded");
    }

    function testRegDeleteOwner(){
        testee.registerNewAccount("testOwnerAcc");
        var ret = testee.deleteAccount("testOwnerAcc");
        assertUintsEqual(ret, SUCCESS, "registrating owner failed");
    }

    function testDeleteAccount(){
        testDelete.registerNewAccount("testDelete");
        var ret = testDelete.deleteAccount("testDelete");
        assertUintsEqual(ret, SUCCESS, "registration failed");
    }

    function testEndowSucceeding(){
        testEndow.registerNewAccount("testEndow");
        var result = testee.endow("testEndow", TEST_BALANCE, "testmessage");
        assertUintsEqual(uint(result), SUCCESS, "endow failed");
    }

    function testEndowFailNotOwner(){
        testEndowFailer.registerNewAccount("testEndowFailer");
        var result = testEndowFailer.endow("testEndowFailer", TEST_BALANCE);
        assertUintsEqual(uint(result), NOT_OWNER, "endow succeeded");
    }

    function testEndowFailNoTarget(){
        var result = testee.endow("noAcc", TEST_BALANCE, "testmessage");
        assertUintsEqual(uint(result), NO_TARGET, "endow succeeded");
    }

    function testTransferSuccess(){
        testTransferer.registerNewAccount("testTransferer");
        testTransferee.registerNewAccount("testTransferee");
        testee.endow("testTransferer", TEST_BALANCE, "testmessage");
        testTransferer.transfer("testTransferee", TEST_BALANCE);
        var balanceIn = testee.getBalance("testTransferee");
        assertUintsEqual(balanceIn, TEST_BALANCE, "balances does not match");
    }

    function testTransferSenderBalanceCheck(){
        testTransfererBalanceCheck.registerNewAccount("testTransfererBalanceCheck");
        testTransfereeBalanceCheck.registerNewAccount("testTransfereeBalanceCheck");
        testee.endow("testTransfererBalanceCheck", TEST_BALANCE, "testmessage");
        testTransfererBalanceCheck.transfer("testTransfereeBalanceCheck", TEST_BALANCE / 2);
        var balanceIn = testee.getBalance("testTransfererBalanceCheck");
        assertUintsEqual(balanceIn, TEST_BALANCE / 2, "balances does not match");
    }

    function testTransferFailedNoAccount(){
        var result = testTransfererNoAccount.transfer("noAcc", 1);
        assertUintsEqual(uint(result), NO_ACCOUNT, "no account fail");
    }

    function testTransferFailedNoAmount(){
        testTransfererNoAmount.registerNewAccount("testTfrNoAmt");
        var result = testTransferer.transfer("noAcc", 0);
        assertUintsEqual(uint(result), NO_AMOUNT, "no amount fail");
    }

    function testTransferFailedInsufficientBalance(){
        testTransfererInsufficientBalance.registerNewAccount("testTfrIsfBlnc");
        var result = testTransfererInsufficientBalance.transfer("noAcc", 1);
        assertUintsEqual(uint(result), INSUFFICIENT_BALANCE, "insufficient balance fail");
    }

    function testTransferFailedNoTarget(){
        testTransfererNoTarget.registerNewAccount("tstTrsfrrNTrgt");
        testee.endow("tstTrsfrrNTrgt", TEST_BALANCE, "testmessage");
        var result = testTransfererNoTarget.transfer("noAcc", 1);
        assertUintsEqual(uint(result), NO_TARGET, "no target fail");
    }

}