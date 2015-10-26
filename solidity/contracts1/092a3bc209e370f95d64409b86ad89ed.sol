contract Test{
	struct coinWallet {
		uint redCoin;
		uint greenCoin;
	}

	coinWallet myWallet;
	
	function Test(){
		myWallet.redCoin = 500;
		myWallet.greenCoin = 250;
	}
}