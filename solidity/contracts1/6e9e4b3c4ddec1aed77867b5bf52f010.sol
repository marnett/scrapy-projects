import "assertions/Asserter.sol";

contract Array {

    int[5] public array;
    int[] public dynArray;

    function Array(){
    }

    function setElement(uint index, int val) external {
        array[index] = val;
    }

    function push(int val) external {
        var len = dynArray.length++;
        dynArray[len] = val;
    }

    function pop() external returns (int val){
        var pos = dynArray.length - 1;
        val = dynArray[pos];
        --dynArray.length;
    }

    function dynArrayLen() external returns (uint length){
        length = dynArray.length;
    }

    function arrayLen() external returns (uint length){
        length = array.length;
    }

    function resetDynArray(){
        dynArray.length = 0;
    }

    function setArray(int[5] _array) external {
        array = _array;
    }

}

contract ArrayTest is Asserter {

    int constant ARR_0 = 1;

    int constant PUSH_1 = 5;
    int constant PUSH_2 = 10;
    int constant PUSH_3 = 15;
    int constant PUSH_4 = 20;
    int constant PUSH_5 = 25;

    uint constant LEN = 3;

    function testSetArray0(){
        Array testee = new Array();
        testee.setElement(0, ARR_0);
        var arr0 = testee.array(0);
        assertIntsEqual(arr0, ARR_0, "array[0] does not match.");
    }

    function testPush(){
        Array testee = new Array();
        testee.push(PUSH_1);
        testee.push(PUSH_2);
        testee.push(PUSH_3);
        var len = testee.dynArrayLen();
        // Fail intentionally
        assertUintsEqual(len, 3, "length does not match.");
    }

    function testPop(){
        Array testee = new Array();
        testee.push(PUSH_4);
        var pop = testee.pop();
        assertIntsEqual(pop, PUSH_4, "pop does not match.");
    }

    function testResetDynArray(){
        Array testee = new Array();
        testee.resetDynArray();
        var len = testee.dynArrayLen();
        assertUintsEqual(len, 0, "length does not match.");
    }

    function testSetArray(){
        Array testee = new Array();
        int[5] arr;
        arr[0] = 4;
        arr[1] = 5;
        arr[2] = 6;
        testee.setArray(arr);
        var len = testee.arrayLen();
        assertUintsEqual(len, 5, "length does not match.");

    }

    function testAccessDynArray(){
        Array testee = new Array();
        testee.resetDynArray();
        testee.push(PUSH_5);
        var da0 = testee.dynArray(0);
        assertIntsEqual(da0, PUSH_5, "value does not match.");
    }
}