import "assertions/Asserter.sol";

contract Structs {

    struct S {
        uint x;
        uint y;
        T t;
    }

    struct T {
        uint a;
        uint b;
    }

    // I'm just sitting here, being a struct.
    S strct;

    function Structs(uint a, uint b, uint x, uint y) {
        var newStruct = S(x, y, T({a: a, b: b}));
        strct = newStruct;
    }

    function setStructA(uint a) external {
        strct.t.a = a;
    }

    function getStructA() external constant returns (uint a){
        return strct.t.a;
    }

    function setStructB(uint b) external {
        strct.t.b = b;
    }

    function getStructB() external constant returns (uint b){
        return strct.t.b;
    }

    function setStructX(uint x) external {
        strct.x = x;
    }

    function getStructX() external constant returns (uint x){
        return strct.x;
    }

    function setStructY(uint y) external {
        strct.y = y;
    }

    function getStructY() external constant returns (uint y){
        return strct.y;
    }
}

contract StructsTest is Asserter {

    uint constant A = 1;
    uint constant B = 2;
    uint constant X = 3;
    uint constant Y = 4;

    Structs testee;

    function StructsTest(){
        testee = new Structs(0, 0, 0, 0);
    }

    function testSetStructA() {
        testee.setStructA(A);
        var a = testee.getStructA();
        assertUintsEqual(a, A, "Did not get correct 'a'.");
    }

    function testSetStructB() {
        testee.setStructB(B);
        var b = testee.getStructB();
        assertUintsEqual(b, B, "Did not get correct 'b'.");
    }

    function testSetStructX() {
        testee.setStructX(X);
        var x = testee.getStructX();
        assertUintsEqual(x, X, "Did not get correct 'x'.");
    }

    function testSetStructY() {
        testee.setStructY(Y);
        var y = testee.getStructY();
        assertUintsEqual(y, Y, "Did not get correct 'y'.");
    }

}