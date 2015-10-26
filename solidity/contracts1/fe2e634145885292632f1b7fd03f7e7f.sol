contract test{
    string s;

    function test() {
    	s = "Hello, World!";
    }

    function get() constant returns (string ret) {
    	return s;
    }
}