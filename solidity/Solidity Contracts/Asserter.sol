/// @title Asserter
/// @author Andreas Olofsson (andreas@erisindustries.com)
contract Asserter {

    /// @dev The test event is used to read the test results.
    /// @param fId 4 byte function identifier (would normally be address(msg.sig)).
    /// @param result Whether or not the assertion holds. The result is always a boolean.
    /// @param error Errors can be reported here. 0 means normal execution.
    /// @param message A message to write if the assertion fails. NOTE: must be <= 32 chars.
    event TestEvent(address indexed fId, bool indexed result, uint error, bytes32 indexed message);

    /// @dev used internally to trigger the event.
    function report(bool result, bytes32 message) internal constant {
        if(result){
            TestEvent(address(msg.sig), true, 0, "");
        } else {
            TestEvent(address(msg.sig), false, 0, message);
        }
    }

    // ************************************** bytes32 **************************************

    /// @dev Assert that the two bytes32 A and B are equal.
    /// @param A The first bytes(32).
    /// @param B The second bytes(32).
    /// @param msg The message to display if the assertion fails.
    function assertBytes32Equal(bytes32 A, bytes32 B, bytes32 message) internal constant returns (bool result){
        result = (A == B);
        report(result, message);
    }

    /// @dev Assert that the two bytes32 A and B are not equal.
    /// @param A The first bytes(32).
    /// @param B The second bytes(32).
    /// @param msg The message to display if the assertion fails.
    function assertBytes32NotEqual(bytes32 A, bytes32 B, bytes32 message) internal constant returns (bool result) {
        result = (A != B);
        report(result, message);
    }

    /// @dev Assert that the bytes32 'bts' is zero.
    /// @param bts the bytes(32).
    /// @param msg The message to display if the assertion fails.
    function assertBytes32IsZero(bytes32 bts, bytes32 message) internal constant returns (bool result){
        result = (bts == 0);
        report(result, message);
    }

    /// @dev Assert that the bytes32 'bts' is not zero.
    /// @param str The bytes(32).
    /// @param msg The message to display if the assertion fails.
    function assertBytes32NotEmpty(bytes32 bts, bytes32 message) internal constant returns (bool result){
        result = (bts != 0);
        report(result, message);
    }

    // ************************************** address **************************************

    /// @dev Assert that the two addresses A and B are equal.
    /// @param A The first address.
    /// @param B The second address.
    /// @param msg The message to display if the assertion fails.
    function assertAddressesEqual(address A, address B, bytes32 message) internal constant returns (bool result){
        result = (A == B);
        report(result, message);
    }

    /// @dev Assert that the two addresses A and B are not equal.
    /// @param A The first address.
    /// @param B The second address.
    /// @param msg The message to display if the assertion fails.
    function assertAddressesNotEqual(address A, address B, bytes32 message) internal constant returns (bool result) {
        result = (A != B);
        report(result, message);
    }

    /// @dev Assert that the address 'addr' is zero.
    /// @param addr The Address.
    /// @param msg The message to display if the assertion fails.
    function assertAddressZero(address addr, bytes32 message) internal constant returns (bool result){
        result = (addr == 0);
        report(result, message);
    }

    /// @dev Assert that the address 'addr' is not zero.
    /// @param addr The Address.
    /// @param msg The message to display if the assertion fails.
    function assertAddressNotZero(address addr, bytes32 message) internal constant returns (bool result){
        result = (addr != 0);
        report(result, message);
    }

    // ************************************** bool **************************************

    /// @dev Assert that the two booleans A and B are equal.
    /// @param A The first boolean.
    /// @param B The second boolean.
    /// @param msg The message to display if the assertion fails.
    function assertBoolsEqual(bool A, bool B, bytes32 message) internal constant returns (bool result) {
        result = (A == B);
        report(result, message);
    }

    /// @dev Assert that the two booleans A and B are not equal.
    /// @param A The first boolean.
    /// @param B The second boolean.
    /// @param msg The message to display if the assertion fails.
    function assertBoolsNotEqual(bool A, bool B, bytes32 message) internal constant returns (bool result) {
        result = (A != B);
        report(result, message);
    }

    /// @dev Assert that the boolean b is true.
    /// @param b The boolean.
    /// @param msg The message to display if the assertion fails.
    function assertTrue(bool b, bytes32 message) internal constant returns (bool result) {
        result = b;
        report(result, message);
    }

    /// @dev Assert that the boolean b is false.
    /// @param b The boolean.
    /// @param msg The message to display if the assertion fails.
    function assertFalse(bool b, bytes32 message) internal constant returns (bool result) {
        result = !b;
        report(result, message);
    }

    // ************************************** uint **************************************

    /// @dev Assert that the two uints (256) A and B are equal.
    /// @param A The first uint.
    /// @param B The second uint.
    /// @param msg The message to display if the assertion fails.
    function assertUintsEqual(uint A, uint B, bytes32 message) internal constant returns (bool result) {
        result = (A == B);
        report(result, message);
    }



    /// @dev Assert that the two uints (256) A and B are not equal.
    /// @param A The first uint.
    /// @param B The second uint.
    /// @param msg The message to display if the assertion fails.
    function assertUintsNotEqual(uint A, uint B, bytes32 message) internal constant returns (bool result) {
        result = (A != B);
        report(result, message);
    }

    /// @dev Assert that the uint (256) A is larger then B.
    /// @param A The first uint.
    /// @param B The second uint.
    /// @param msg The message to display if the assertion fails.
    function assertUintLargerThen(uint A, uint B, bytes32 message) internal constant returns (bool result) {
        result = (A > B);
        report(result, message);
    }

    /// @dev Assert that the uint (256) A is larger then or equal to B.
    /// @param A The first uint.
    /// @param B The second uint.
    /// @param msg The message to display if the assertion fails.
    function assertUintLargerThenOrEqual(uint A, uint B, bytes32 message) internal constant returns (bool result) {
        result = (A >= B);
        report(result, message);
    }

    /// @dev Assert that the uint (256) A is smaller then B.
    /// @param A The first uint.
    /// @param B The second uint.
    /// @param msg The message to display if the assertion fails.
    function assertUintSmallerThen(uint A, uint B, bytes32 message) internal constant returns (bool result) {
        result = (A < B);
        report(result, message);
    }

    /// @dev Assert that the uint (256) A is smaller then or equal to B.
    /// @param A The first uint.
    /// @param B The second uint.
    /// @param msg The message to display if the assertion fails.
    function assertUintSmallerThenOrEqual(uint A, uint B, bytes32 message) internal constant returns (bool result) {
        result = (A <= B);
        report(result, message);
    }

    /// @dev Assert that the uint (256) number is 0.
    /// @param number The uint to test.
    /// @param msg The message to display if the assertion fails.
    function assertUintZero(uint number, bytes32 message) internal constant returns (bool result) {
        result = (number == 0);
        report(result, message);
    }

    /// @dev Assert that the uint (256) number is not 0.
    /// @param number The uint to test.
    /// @param msg The message to display if the assertion fails.
    function assertUintNotZero(uint number, bytes32 message) internal constant returns (bool result) {
        result = (number != 0);
        report(result, message);
    }

    // ************************************** int **************************************

    /// @dev Assert that the two ints (256) A and B are equal.
    /// @param A The first int.
    /// @param B The second int.
    /// @param msg The message to display if the assertion fails.
    function assertIntsEqual(int A, int B, bytes32 message) internal constant returns (bool result) {
        result = (A == B);
        report(result, message);
    }

    /// @dev Assert that the two ints (256) A and B are not equal.
    /// @param A The first int.
    /// @param B The second int.
    /// @param msg The message to display if the assertion fails.
    function assertIntsNotEqual(int A, int B, bytes32 message) internal constant returns (bool result) {
        result = (A != B);
        report(result, message);
    }

    /// @dev Assert that the int (256) A is larger then B.
    /// @param A The first int.
    /// @param B The second int.
    /// @param msg The message to display if the assertion fails.
    function assertIntLargerThen(int A, int B, bytes32 message) internal constant returns (bool result) {
        result = (A > B);
        report(result, message);
    }

    /// @dev Assert that the int (256) A is larger then or equal to B.
    /// @param A The first int.
    /// @param B The second int.
    /// @param msg The message to display if the assertion fails.
    function assertIntLargerThenOrEqual(int A, int B, bytes32 message) internal constant returns (bool result) {
        result = (A >= B);
        report(result, message);
    }

    /// @dev Assert that the int (256) A is smaller then B.
    /// @param A The first int.
    /// @param B The second int.
    /// @param msg The message to display if the assertion fails.
    function assertIntSmallerThen(int A, int B, bytes32 message) internal constant returns (bool result) {
        result = (A < B);
        report(result, message);
    }

    /// @dev Assert that the int (256) A is smaller then or equal to B.
    /// @param A The first int.
    /// @param B The second int.
    /// @param msg The message to display if the assertion fails.
    function assertIntSmallerThenOrEqual(int A, int B, bytes32 message) internal constant returns (bool result) {
        result = (A <= B);
        report(result, message);
    }

    /// @dev Assert that the int (256) number is 0.
    /// @param number The int to test.
    /// @param msg The message to display if the assertion fails.
    function assertIntZero(int number, bytes32 message) internal constant returns (bool result) {
        result = (number == 0);
        report(result, message);
    }

    /// @dev Assert that the int (256) number is not 0.
    /// @param number The int to test.
    /// @param msg The message to display if the assertion fails.
    function assertIntNotZero(int number, bytes32 message) internal constant returns (bool result) {
        result = (number != 0);
        report(result, message);
    }

}