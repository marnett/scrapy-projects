contract Test {
	bytes32 b;
	function Test(){
		b = 0x12345678901234567890123456789012; 
	}
	event Event(uint indexed a, bytes32 b);
	event Event2(uint indexed a, bytes32 b);
	function foo(uint a) {
		Event(a, b); 
	}
}

contract CrowdFunding {
	
	struct Funder {
		address addr;
		uint amount;
	}
	
	struct Campaign {
		address beneficiary;
		uint fundingGoal;
		uint numFunders;
		uint amount;
		uint deadline;
		mapping (uint => Funder) funders;
	}
	
	mapping (uint => Campaign) campaigns;
	uint numCampaigns;
	
	function newCampaign(address beneficiary, uint goal, uint deadline) returns (uint campaignID) {
		campaignID = numCampaigns++; 
		Campaign c = campaigns[campaignID]; 
		c.beneficiary = beneficiary;
		c.fundingGoal = goal;
		c.deadline = block.number + deadline;
	}
	
	function contribute(uint campaignID) {
		Campaign c = campaigns[campaignID];
		Funder f = c.funders[c.numFunders++];
		f.addr = msg.sender;
		f.amount = msg.value;
		c.amount += f.amount;
	}
	
	function checkGoalReached(uint campaignID) returns (bool reached) {
		Campaign c = campaigns[campaignID];
		if (c.amount >= c.fundingGoal){
			c.beneficiary.send(c.amount);
			c.amount = 0;
			c.beneficiary = 0;
			c.fundingGoal = 0;
			c.deadline = 0;
			uint i = 0;
			uint f = c.numFunders;
			c.numFunders = 0;
			while (i <= f){
				c.funders[i].addr = 0;
				c.funders[i].amount = 0;
				i++;
			}
			return true;
		}
		if (c.deadline <= block.number){
			uint j = 0;
			uint n = c.numFunders;
			c.beneficiary = 0;
			c.fundingGoal = 0;
			c.numFunders = 0;
			c.deadline = 0;
			c.amount = 0;
			while (j <= n){
				c.funders[j].addr.send(c.funders[j].amount);
				c.funders[j].addr = 0;
				c.funders[j].amount = 0;
				j++;
			}
			return true;
		}
		return false;
	}
}
