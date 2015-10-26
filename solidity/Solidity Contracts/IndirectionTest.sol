import "assertions/Asserter.sol";

contract Indirection {

    function actuallyDoesSomething() constant returns (int val){
        val = 55;
    }

    function testMethod() constant returns (int val){
        val = actuallyDoesSomething();
    }

}

contract IndirectorOne {

    Indirection id = new Indirection();

    function testLevelOne() returns (int val) {
        val = idInt();
    }

    function idInt() internal returns (int val){
        val = idPub();
    }

    function idPub() returns (int val){
        val = id.testMethod();
    }
}

contract IndirectorTwo {

    IndirectorOne ido = new IndirectorOne();

    function testLevelTwo() returns (int val){
        val = ido.testLevelOne();
    }
}

contract IndirectorThree {

    IndirectorTwo idw = new IndirectorTwo();

    function testLevelThree() returns (int val){
        val = idw.testLevelTwo();
    }

}

contract IndirectionTest is Asserter {

    IndirectorThree idt = new IndirectorThree();

    function testIndirection() {
        var val = idt.testLevelThree();
        assertIntsEqual(val, 55, "Ints did not match.");
    }

}