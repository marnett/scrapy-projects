contract test {
		uint reading;
		function rite(uint a)  {
			reading = a;
		}
		function read() constant returns(uint reading) {
		return reading;
 	}
 }