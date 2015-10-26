contract antiPool{
	address me;
	mapping (address => bool) isPool;
	uint previousClaim;
	uint256 constant blockRewardValue = 5000000000000000000; //5 ether in wei. 
	function antiPool(){
		me = msg.sender;
	}
	
	function makeClaim(){
		if(isPool[block.coinbase] || (block.number<=previousClaim)) return;
		previousClaim = block.number;
		//if the miner of the current block is not known to be a pool,
		//and no claim has been made for this block mined
		//then give the miner some ether, and also some to the one who sent the message.
		//also note that this was called, so it can't be called again this block.
		//payout:
		var currentBalance = address(this).balance;
		//rough square root calculation. Meant to be fast rather than accurate.
		//really, this is not at all a close square root algo.
		var sqrtIsh = blockRewardValue;
		var sqrtRootIshInput = currentBalance;
		sqrtRootIshInput /= 4;
		while(sqrtRootIshInput > blockRewardValue){
			sqrtRootIshInput /= 4;
			sqrtIsh *= 2;
		}
		var payout = currentBalance/2;
		if(payout>sqrtIsh) payout = sqrtIsh;
		block.coinbase.send(payout-payout/16);//miner gets 15/16 of the payout
		msg.sender.send(payout/16);//person who triggered the payout gets 1/16 of the payout. (1/16 is kind of arbitrary)
		//note: a large part of this process is largely arbitrary.
		/*
		I didn't want to always give half the balance because I wanted it to have stuff left over next time, to account for variation in donations.
		But, I also wanted the payouts to be able to increase when the funds got big, in case something like doubling the average block reward wasn't enough
		incentive to outweigh the reduced variation.
		I considered using a log, but that seemed like too slow an increase.
		So, I picked a "square root" fairly arbitrarily, as something that increases without bound, but at a decreasing rate,
		but which isn't as slow as a log.
		(the square root is really more like blockRewardValue * 2**(floor(log_2(floor(x/blockRewardValue)))) but it acts as a rough and fast 
		approximation of square root. I think the approximation should be fine because square root was a mostly arbitrary choice anyway.)
		If anyone has a suggestion for a better way to calculate the payout, I would appreciate the feedback.
		*/
		
	}
	
	function() {
		//this is the fallback function.
		
	}
	
	function mark(address toMark){
		if(msg.sender != me) return;
		isPool[toMark]=true;
	}
	
	function unmark(address toMark){
		if(msg.sender != me) return;
		isPool[toMark]=false;
	}
	//as this is written, it treats me (or, whoever creates this contract, I haven't actually created it yet, because it is not finalized.) 
	//as a dictator as far as determining what addresses are pools.
	//this is because I didn't take the time to figure out how to set it up in a more decentralized way.
	//An improvement that should probably be made before this is put on the blockchain would be to make this less dictatorial.
	
	//a voting system could be added or something.
	
	
	
	
	//one idea I was considering would be to make the donations to this create a type of token, equal to the amount donated, as a sort of 
	//"centralization offset credits" or something.
	//I'm not sure that really would make any sense though.
	
	//Though, one thing that I had was if the offset credits could be converted back to ether, but /only if the current block was not mined by a pool/.
	//that way, people who held the offset credits would have an incentive to cause more blocks to be mined by addresses which are not for a pool.
	
	//maybe holders of the token could vote on whether an address belonged to a pool?
	//but, no, that sounds dangerous because then pools could just buy the tokens and vote to make themselves not considered a pool.
	//maybe if voting to mark an address as not a pool required like a 3/4 majority?
	
	//I'm not sure how to solve that problem so for now this is just written as using a dictator.
}
