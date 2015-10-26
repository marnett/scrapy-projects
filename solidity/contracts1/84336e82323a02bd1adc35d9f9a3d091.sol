/*
 *  Version 0.2.0
 *
 *  address: 0xc1cfa6ac1d7cf99bd1e145dcd04ec462b3b0c4da
 */
contract Relay {
        address operator;

        function Relay() {
                operator = msg.sender;
        }

        function relayCall(address contractAddress, bytes4 abiSignature, bytes data) public returns (bool) {
                if (msg.sender != operator) {
                        __throw();
                }
                return contractAddress.call(abiSignature, data);
        }

        function __throw() internal {
                int[] x;
                x[1];
        }
}


contract CallerPool {
        address operator;

        function CallerPool() {
                operator = msg.sender;
        }

        /*
         *  Caller bonding
         */
        mapping (address => uint) public callerBonds;

        function getMinimumBond() public returns (uint) {
                return tx.gasprice * block.gaslimit;
        }

        function _deductFromBond(address callerAddress, uint value) internal {
                /*
                 *  deduct funds from a bond value without risk of an
                 *  underflow.
                 */
                if (value > callerBonds[callerAddress]) {
                        // Prevent Underflow.
                        __throw();
                }
                callerBonds[callerAddress] -= value;
        }

        function _addToBond(address callerAddress, uint value) internal {
                /*
                 *  Add funds to a bond value without risk of an
                 *  overflow.
                 */
                if (callerBonds[callerAddress] + value < callerBonds[callerAddress]) {
                        // Prevent Overflow
                        __throw();
                }
                callerBonds[callerAddress] += value;
        }

        function depositBond() public {
                _addToBond(msg.sender, msg.value);
        }

        function withdrawBond(uint value) public {
                /*
                 *  Only if you are not in either of the current call pools.
                 */
                if (isInAnyPool(msg.sender)) {
                        // Prevent underflow
                        if (value > callerBonds[msg.sender]) {
                                __throw();
                        }
                        // Don't allow withdrawl if this would drop the bond
                        // balance below the minimum.
                        if (callerBonds[msg.sender] - value < getMinimumBond()) {
                                return;
                        }
                }
                _deductFromBond(msg.sender, value);
                if (!msg.sender.send(value)) {
                        // Potentially sending money to a contract that
                        // has a fallback function.  So instead, try
                        // tranferring the funds with the call api.
                        if (!msg.sender.call.gas(msg.gas).value(value)()) {
                                // Revert the entire transaction.  No
                                // need to destroy the funds.
                                __throw();
                        }
                }
        }

        function() {
                /*
                 *  Fallback function that allows depositing bond funds just by
                 *  sending a transaction.
                 */
                _addToBond(msg.sender, msg.value);
        }

        /*
         *  API used by Alarm service
         */
        function getDesignatedCaller(bytes32 callKey, uint targetBlock, uint8 gracePeriod, uint blockNumber) public returns (address) {
                /*
                 *  Returns the caller from the current call pool who is
                 *  designated as the executor of this call.
                 */
                if (blockNumber < targetBlock || blockNumber > targetBlock + gracePeriod) {
                        // blockNumber not within call window.
                        return 0x0;
                }

                // Pool used is based on the starting block for the call.  This
                // allows us to know that the pool cannot change for at least
                // POOL_FREEZE_NUM_BLOCKS which is kept greater than the max
                // grace period.
                uint poolNumber = getPoolKeyForBlock(targetBlock);
                if (poolNumber == 0) {
                        // No pool currently in operation.
                        return 0x0;
                }
                var pool = callerPools[poolNumber];

                uint numWindows = gracePeriod / 4;
                uint blockWindow = (blockNumber - targetBlock) / 4;

                if (blockWindow + 2 > numWindows) {
                        // We are within the free-for-all period.
                        return 0x0;
                }

                uint offset = uint(callKey) % pool.length;
                return pool[(offset + blockWindow) % pool.length];
        }

        //event AwardedMissedBlockBonus(address indexed fromCaller, address indexed toCaller, uint indexed poolNumber, bytes32 callKey, uint blockNumber, uint bonusAmount);

        function _doBondBonusTransfer(address fromCaller, address toCaller) internal returns (uint) {
                uint bonusAmount = getMinimumBond();
                uint bondBalance = callerBonds[fromCaller];

                // If the bond balance is lower than the award
                // balance, then adjust the reward amount to
                // match the bond balance.
                if (bonusAmount > bondBalance) {
                        bonusAmount = bondBalance;
                }

                // Transfer the funds fromCaller => toCaller
                _deductFromBond(fromCaller, bonusAmount);
                _addToBond(toCaller, bonusAmount);

                return bonusAmount;
        }

        function awardMissedBlockBonus(address toCaller, bytes32 callKey, uint targetBlock, uint8 gracePeriod) public {
                if (msg.sender != operator) {
                        return;
                }

                uint poolNumber = getPoolKeyForBlock(targetBlock);
                var pool = callerPools[poolNumber];
                uint i;
                uint bonusAmount;
                address fromCaller;

                uint numWindows = gracePeriod / 4;
                uint blockWindow = (block.number - targetBlock) / 4;

                // Check if we are within the free-for-all period.  If so, we
                // award from all pool members.
                if (blockWindow + 2 > numWindows) {
                        address firstCaller = getDesignatedCaller(callKey, targetBlock, gracePeriod, targetBlock);
                        for (i = targetBlock; i <= targetBlock + gracePeriod; i += 4) {
                                fromCaller = getDesignatedCaller(callKey, targetBlock, gracePeriod, i);
                                if (fromCaller == firstCaller && i != targetBlock) {
                                        // We have already gone through all of
                                        // the pool callers so we should break
                                        // out of the loop.
                                        break;
                                }
                                if (fromCaller == toCaller) {
                                        continue;
                                }
                                bonusAmount = _doBondBonusTransfer(fromCaller, toCaller);

                                // Log the bonus was awarded.
                                //AwardedMissedBlockBonus(fromCaller, toCaller, poolNumber, callKey, block.number, bonusAmount);
                        }
                        return;
                }

                // Special case for single member and empty pools
                if (pool.length < 2) {
                        return;
                }

                // Otherwise the award comes from the previous caller.
                for (i = 0; i < pool.length; i++) {
                        // Find where the member is in the pool and
                        // award from the previous pool members bond.
                        if (pool[i] == toCaller) {
                                fromCaller = pool[(i + pool.length - 1) % pool.length];

                                bonusAmount = _doBondBonusTransfer(fromCaller, toCaller);

                                // Log the bonus was awarded.
                                //AwardedMissedBlockBonus(fromCaller, toCaller, poolNumber, callKey, block.number, bonusAmount);

                                // Remove the caller from the next pool.
                                if (getNextPoolKey() == 0) {
                                        // This is the first address to modify the
                                        // current pool so we need to setup the next
                                        // pool.
                                        _initiateNextPool();
                                }
                                _removeFromPool(fromCaller, getNextPoolKey());
                                return;
                        }
                }
        }

        /*
         *  Caller Pool Management
         */
        uint[] public poolHistory;
        mapping (uint => address[]) callerPools;

        function getPoolKeyForBlock(uint blockNumber) public returns (uint) {
                if (poolHistory.length == 0) {
                        return 0;
                }
                for (uint i = 0; i < poolHistory.length; i++) {
                        uint poolStartBlock = poolHistory[poolHistory.length - i - 1];
                        if (poolStartBlock <= blockNumber) {
                                return poolStartBlock;
                        }
                }
                return 0;
        }

        function getActivePoolKey() public returns (uint) {
                return getPoolKeyForBlock(block.number);
        }

        function getPoolSize(uint poolKey) returns (uint) {
                return callerPools[poolKey].length;
        }

        function getNextPoolKey() public returns (uint) {
                if (poolHistory.length == 0) {
                        return 0;
                }
                uint latestPool = poolHistory[poolHistory.length - 1];
                if (latestPool > block.number) {
                        return latestPool;
                }
                return 0;
        }

        function isInAnyPool(address callerAddress) public returns (bool) {
                /*
                 *  Returns boolean whether the `callerAddress` is in either
                 *  the current active pool or the next pool.
                 */
                return isInPool(msg.sender, getActivePoolKey()) || isInPool(msg.sender, getNextPoolKey());
        }

        function isInPool(address callerAddress, uint poolNumber) public returns (bool) {
                /*
                 *  Returns boolean whether the `callerAddress` is in the
                 *  poolNumber.
                 */
                if (poolNumber == 0 ) {
                        // Nobody can be in pool 0
                        return false;
                }

                var pool = callerPools[poolNumber];

                // Nobody is in the pool.
                if (pool.length == 0) {
                        return false;
                }

                for (uint i = 0; i < pool.length; i++) {
                        // Address is in the pool and thus is allowed to exit.
                        if (pool[i] == callerAddress) {
                                return true;
                        }
                }

                return false;
        }

        // Ten minutes into the future.
        uint constant POOL_FREEZE_NUM_BLOCKS = 256;
        //uint constant POOL_FREEZE_NUM_BLOCKS = 40;

        function getPoolFreezeDuration() public returns (uint) {
                return POOL_FREEZE_NUM_BLOCKS;
        }

        function getPoolMinimumLength() public returns (uint) {
                return 2 * POOL_FREEZE_NUM_BLOCKS;
        }

        function canEnterPool(address callerAddress) public returns (bool) {
                /*
                 *  Returns boolean whether `callerAddress` is allowed to enter
                 *  the next pool (which may or may not already have been
                 *  created.
                 */
                // Not allowed to join if you are in either the current
                // active pool or the next pool.
                if (isInAnyPool(callerAddress)) {
                        return false;
                }

                // Next pool begins within the POOL_FREEZE_NUM_BLOCKS grace
                // period so no changes are allowed.
                if (getNextPoolKey() != 0 && block.number >= (getNextPoolKey() - POOL_FREEZE_NUM_BLOCKS)) {
                        return false;
                }

                // Account bond balance is too low.
                if (callerBonds[callerAddress] < getMinimumBond()) {
                        return false;
                }
                
                return true;
        }

        function canExitPool(address callerAddress) public returns (bool) {
                /*
                 *  Returns boolean whether `callerAddress` is allowed to exit
                 *  the current active pool.
                 */
                // Can't exit if we aren't in the current active pool.
                if (!isInPool(callerAddress, getActivePoolKey())) {
                        return false;
                }

                // There is a next pool coming up.
                if (getNextPoolKey() != 0) {
                        // Next pool begins within the POOL_FREEZE_NUM_BLOCKS
                        // window and thus can't be modified.
                        if (block.number >= (getNextPoolKey() - POOL_FREEZE_NUM_BLOCKS)) {
                                return false;
                        }

                        // Next pool was already setup and callerAddress isn't
                        // in it which indicates that they already left.
                        if (!isInPool(callerAddress, getNextPoolKey())) {
                                return false;
                        }
                }

                // They must be in the current pool and either the next pool
                // hasn't been initiated or it has but this user hasn't left
                // yet.
                return true;
        }

        function _initiateNextPool() internal {
                if (getNextPoolKey() != 0) {
                        // If there is already a next pool, we shouldn't
                        // initiate a new one until it has become active.
                        __throw();
                }
                // Set the next pool to start at double the freeze block number
                // in the future.
                uint nextPool = block.number + 2 * POOL_FREEZE_NUM_BLOCKS;

                // Copy the current pool into the next pool.
                callerPools[nextPool] = callerPools[getActivePoolKey()];

                // Randomize the pool order
                _shufflePool(nextPool);

                // Push the next pool into the pool history.
                poolHistory.length += 1;
                poolHistory[poolHistory.length - 1] = nextPool;
        }

        function _shufflePool(uint poolNumber) internal {
                var pool = callerPools[poolNumber];

                uint swapIndex;
                address buffer;

                for (uint i = 0; i < pool.length; i++) {
                        swapIndex = uint(sha3(block.blockhash(block.number), i)) % pool.length;
                        if (swapIndex == i) {
                                continue;
                        }
                        buffer = pool[i];
                        pool[i] = pool[swapIndex];
                        pool[swapIndex] = buffer;
                }
        }

        //event AddedToPool(address indexed callerAddress, uint indexed pool);
        //event RemovedFromPool(address indexed callerAddress, uint indexed pool);

        function _addToPool(address callerAddress, uint poolNumber) internal {
                if (poolNumber == 0 ) {
                        // This shouldn't be called with 0;
                        __throw();
                }

                // already in the pool.
                if (isInPool(callerAddress, poolNumber)) {
                        return;
                }
                var pool = callerPools[poolNumber];
                pool.length += 1;
                pool[pool.length - 1] = callerAddress;
                
                // Log the addition.
                //AddedToPool(callerAddress, poolNumber);
        }

        function _removeFromPool(address callerAddress, uint poolNumber) internal {
                if (poolNumber == 0 ) {
                        // This shouldn't be called with 0;
                        __throw();
                }

                // nothing to remove.
                if (!isInPool(callerAddress, poolNumber)) {
                        return;
                }
                var pool = callerPools[poolNumber];
                // special case length == 1
                if (pool.length == 1) {
                        pool.length = 0;
                }
                for (uint i = 0; i < pool.length; i++) {
                        // When we find the index of the address to remove we
                        // shift the last person to that location and then we
                        // truncate the last member off of the end.
                        if (pool[i] == callerAddress) {
                                pool[i] = pool[pool.length - 1];
                                pool.length -= 1;
                                break;
                        }
                }

                // Log the addition.
                //RemovedFromPool(callerAddress, poolNumber);
        }

        function enterPool() public {
                /*
                 *  Request to be added to the call pool.
                 */
                if (canEnterPool(msg.sender)) {
                        if (getNextPoolKey() == 0) {
                                // This is the first address to modify the
                                // current pool so we need to setup the next
                                // pool.
                                _initiateNextPool();
                        }
                        _addToPool(msg.sender, getNextPoolKey());
                }
        }

        function exitPool() public {
                /*
                 *  Request to be removed from the call pool.
                 */
                if (canExitPool(msg.sender)) {
                        if (getNextPoolKey() == 0) {
                                // This is the first address to modify the
                                // current pool so we need to setup the next
                                // pool.
                                _initiateNextPool();
                        }
                        _removeFromPool(msg.sender, getNextPoolKey());
                }
        }

        function __throw() internal {
                int[] x;
                x[1];
        }
}


contract Alarm {
        /*
         *  Administration API
         *
         *  There is currently no special administrative API beyond the hard
         *  coded owner address which receives 1% of each executed call.  This
         *  eliminates any need for trust as nobody has any special access.
         */
        function Alarm() {
                unauthorizedRelay = new Relay();
                authorizedRelay = new Relay();
                callerPool = new CallerPool();
        }

        address constant owner = 0xd3cda913deb6f67967b99d67acdfa1712c293601;

        /*
         *  Account Management API
         */
        mapping (address => uint) public accountBalances;

        function _deductFunds(address accountAddress, uint value) internal {
                /*
                 *  Helper function that should be used for any reduction of
                 *  account funds.  It has error checking to prevent
                 *  underflowing the account balance which would be REALLY bad.
                 */
                if (value > accountBalances[accountAddress]) {
                        // Prevent Underflow.
                        __throw();
                }
                accountBalances[accountAddress] -= value;
        }

        function _addFunds(address accountAddress, uint value) internal {
                /*
                 *  Helper function that should be used for any addition of
                 *  account funds.  It has error checking to prevent
                 *  overflowing the account balance.
                 */
                if (accountBalances[accountAddress] + value < accountBalances[accountAddress]) {
                        // Prevent Overflow.
                        __throw();
                }
                accountBalances[accountAddress] += value;
        }

        //event Deposit(address indexed _from, address indexed accountAddress, uint value);

        function deposit(address accountAddress) public {
                /*
                 *  Public API for depositing funds in a specified account.
                 */
                _addFunds(accountAddress, msg.value);
                //Deposit(msg.sender, accountAddress, msg.value);
        }

        //event Withdraw(address indexed accountAddress, uint value);

        function withdraw(uint value) public {
                /*
                 *  Public API for withdrawing funds.
                 */
                if (accountBalances[msg.sender] >= value) {
                        _deductFunds(msg.sender, value);
                        if (!msg.sender.send(value)) {
                                // Potentially sending money to a contract that
                                // has a fallback function.  So instead, try
                                // tranferring the funds with the call api.
                                if (!msg.sender.call.gas(msg.gas).value(value)()) {
                                        // Revert the entire transaction.  No
                                        // need to destroy the funds.
                                        __throw();
                                }
                        }
                        //Withdraw(msg.sender, value);
                }
        }

        function() {
                /*
                 *  Fallback function that allows depositing funds just by
                 *  sending a transaction.
                 */
                _addFunds(msg.sender, msg.value);
                //Deposit(msg.sender, msg.sender, msg.value);
        }

        /*
         *  Call tracking API
         */
        struct Node {
                bytes32 callKey;
                bytes32 left;
                bytes32 right;
        }

        bytes32 public rootNodeCallKey;

        mapping (bytes32 => Node) call_to_node;

        function _getTreeMaxBlock(bytes32 callKey) internal returns (uint) {
                /*
                 *  Returns the greatest block number for all calls in the
                 *  section of the call tree denoted by callKey.
                 */
                Node currentNode = call_to_node[callKey];

                while (true) {
                        if (currentNode.right == 0x0) {
                                return key_to_calls[currentNode.callKey].targetBlock;
                        }

                        currentNode = call_to_node[currentNode.right];
                }
        }

        function _shouldGoLeft(bytes32 callKey, uint blockNumber) internal returns (bool) {
                /*
                 * not if left is empty
                 * not if current node was already called
                 * not if current node is in the past or current block.
                 * not if left node is in the past.
                 */
                Node currentNode = call_to_node[callKey];

                // Nowhere to go.
                if (currentNode.left == 0x0) {
                        return false;
                }

                Call currentCall = key_to_calls[callKey];

                // Current call is already in the past or is up next.
                if (currentCall.targetBlock <= blockNumber) {
                        return false;
                }

                // Left call is in the past
                if (blockNumber > _getTreeMaxBlock(currentNode.left)) {
                        return false;
                }

                return true;
        }

        function _shouldGoRight(bytes32 callKey, uint blockNumber) internal returns (bool) {
                /*
                 * not if right is empty.
                 * not if current node is already in the future.
                 * not if current node is equal to targetBlock and it isn't already called.
                 *
                 */
                Node currentNode = call_to_node[callKey];

                // Nowhere to go.
                if (currentNode.right == 0x0) {
                        return false;
                }

                Call currentCall = key_to_calls[callKey];

                // Current call is already in the future
                if (currentCall.targetBlock > blockNumber) {
                        return false;
                }

                // Current call equals the desired block number and has not
                // been called yet and is not cancelled.
                if (currentCall.targetBlock == blockNumber) {
                        return false;
                }

                return true;
        }

        function getNextBlockWithCall(uint blockNumber) public returns (uint) {
                bytes32 nextCallKey = getNextCallKey(blockNumber);
                if (nextCallKey == 0x0) {
                        return 0;
                }
                return key_to_calls[nextCallKey].targetBlock;
        }

        function getNextCallKey(uint blockNumber) public returns (bytes32) {
                if (rootNodeCallKey == 0x0) {
                        // No calls registered
                        return 0x0;
                }

                Node currentNode = call_to_node[rootNodeCallKey];

                while (true) {
                        if (_shouldGoLeft(currentNode.callKey, blockNumber)) {
                                currentNode = call_to_node[currentNode.left];
                                continue;
                        }
                        if (_shouldGoRight(currentNode.callKey, blockNumber)) {
                                currentNode = call_to_node[currentNode.right];
                                continue;
                        }

                        // Not if it is before the blockNumber
                        if (key_to_calls[currentNode.callKey].targetBlock < blockNumber) {
                                return 0x0;
                        }

                        // Then it must be the next one.
                        return currentNode.callKey;
                }
        }

        function _isBlockNumberInTree(bytes32 callKey, uint blockNumber) internal returns (bool) {
                var node = call_to_node[callKey];

                while (true) {
                        var call = key_to_calls[node.callKey];

                        if (call.targetBlock == blockNumber) {
                                return true;
                        }

                        if (node.left != 0x0 && call.targetBlock > blockNumber) {
                                node = call_to_node[node.left];
                                continue;
                        }

                        if (node.right != 0x0 && call.targetBlock < blockNumber) {
                                node = call_to_node[node.right];
                                continue;
                        }

                        return false;
                }
        }

        function getNextCallSibling(bytes32 callKey) public returns (bytes32) {
                /*
                 *  Returns the callKey any subsequent calls that have the same
                 *  block number as the provided callKey.  If there are no
                 *  subsequent calls with the same block number returns 0x0
                 */
                var node = call_to_node[callKey];
                var call = key_to_calls[callKey];
                uint targetBlock = call.targetBlock;

                while (true) {
                        if (node.right != 0x0 && _isBlockNumberInTree(node.right, targetBlock)) {
                                node = call_to_node[node.right];
                                call = key_to_calls[node.callKey];
                                if (call.targetBlock == targetBlock) {
                                        return node.callKey;
                                }
                                continue;
                        }

                        if (node.left != 0x0 && _isBlockNumberInTree(node.left, targetBlock)) {
                                node = call_to_node[node.left];
                                call = key_to_calls[node.callKey];
                                if (call.targetBlock == targetBlock) {
                                        return node.callKey;
                                }
                                continue;
                        }

                        return 0x0;
                }
        }

        function getCallLeftChild(bytes32 callKey) public returns (bytes32) {
                return call_to_node[callKey].left;
        }

        function getCallRightChild(bytes32 callKey) public returns (bytes32) {
                return call_to_node[callKey].right;
        }

        //event CallPlacedInTree(bytes32 indexed callKey);

        function placeCallInTree(bytes32 callKey) internal {
                /*
                 * Calls are stored in a tree structure.  Each tree node
                 * represents a single call.  Nodes have a left and right
                 * child.  The left child represents a call that should happen
                 * before the node.  The right child represents a call that
                 * should happen after the node.
                 */
                Call targetCall = key_to_calls[callKey];

                if (callKey == call_to_node[callKey].callKey) {
                        // This call key is already placed in the tree.
                        return;
                }

                if (rootNodeCallKey == 0x0) {
                        // This is the first call placement and thus should be
                        // set as the root node.
                        rootNodeCallKey = callKey;
                }

                Node currentNode = call_to_node[rootNodeCallKey];

                while (true) {
                        if (currentNode.callKey == 0x0) {
                                // This is a new node and should be mapped 
                                currentNode.callKey = callKey;
                                //CallPlacedInTree(callKey);
                                return;
                        }

                        Call currentCall = key_to_calls[currentNode.callKey];

                        if (targetCall.targetBlock < currentCall.targetBlock) {
                                // Call should occure before the current node
                                // and thus should exist in the left subtree.
                                if (currentNode.left == 0x0) {
                                        currentNode.left = callKey;
                                }
                                currentNode = call_to_node[currentNode.left];
                                continue;
                        }

                        // Call should occur after the current node and thus
                        // should exist in the right subtree.
                        if (currentNode.right == 0x0) {
                                currentNode.right = callKey;
                        }
                        currentNode = call_to_node[currentNode.right];
                }
        }

        //event TreeRotatedRight(bytes32 indexed oldRootNodeCallKey, bytes32 indexed newRootNodeCallKey);

        function _rotateRight() internal {
                /*
                 *  1. Detatch the left child of the root node.  This is the
                 *     new root node.
                 *  2. Detatch the right child of the new root node.
                 *  3. Set the old root node as the right child of the new root node.
                 *  4. Set the detatched right child from the new root node in
                 *     the appropriate location in the tree.
                 */
                var oldRootNode = call_to_node[rootNodeCallKey];
                var newRootNode = call_to_node[oldRootNode.left];
                // #1
                oldRootNode.left = 0x0;
                rootNodeCallKey = newRootNode.callKey;

                // #2
                bytes32 detatchedChildCallKey = newRootNode.right;
                newRootNode.right = 0x0;

                // #3
                newRootNode.right = oldRootNode.callKey;

                // #4
                if (detatchedChildCallKey != 0x0) {
                        // First reset the node to not have a callKey,
                        // otherwise the call to `placeCallInTree` will exit
                        // early thinking this node is already placed.
                        var detatchedChildNode = call_to_node[detatchedChildCallKey];
                        detatchedChildNode.callKey = 0x0;
                        // Now place it at it's new location in the tree.
                        placeCallInTree(detatchedChildCallKey);
                }

                //TreeRotatedRight(oldRootNode.callKey, newRootNode.callKey);
        }

        function _shouldRotateRight() internal returns (bool) {
                /*
                 *  Is the left child of the rootNode in the future of the
                 *  current block number.
                 */
                if (rootNodeCallKey == 0x0) {
                        return false;
                }

                var currentRoot = call_to_node[rootNodeCallKey];

                // No left child so cant rotate right.
                if (currentRoot.left == 0x0) {
                        return false;
                }

                // Current root already in the past.
                if (key_to_calls[rootNodeCallKey].targetBlock <= block.number) {
                        return false;
                }

                return true;
        }

        //event TreeRotatedLeft(bytes32 indexed oldRootNodeCallKey, bytes32 indexed newRootNodeCallKey);

        function _rotateLeft() internal {
                /*
                 *  1. Detatch the right child of the root node.  This is the
                 *     new root node.
                 *  2. Detatch the left child of the new root node.
                 *  3. Set the old root node as the left child of the new root node.
                 *  4. Set the detatched left child from the new root node in
                 *     the appropriate location in the tree.
                 */
                var oldRootNode = call_to_node[rootNodeCallKey];
                var newRootNode = call_to_node[oldRootNode.right];
                // #1
                oldRootNode.right = 0x0;
                rootNodeCallKey = newRootNode.callKey;

                // #2
                bytes32 detatchedChildCallKey = newRootNode.left;

                // #3
                newRootNode.left = oldRootNode.callKey;

                // #4
                if (detatchedChildCallKey != 0x0) {
                        // First reset the node to not have a callKey,
                        // otherwise the call to `placeCallInTree` will exit
                        // early thinking this node is already placed.
                        var detatchedChildNode = call_to_node[detatchedChildCallKey];
                        detatchedChildNode.callKey = 0x0;
                        // Now place it at it's new location in the tree.
                        placeCallInTree(detatchedChildCallKey);
                }
                //TreeRotatedLeft(oldRootNode.callKey, newRootNode.callKey);
        }

        function _shouldRotateLeft() internal returns (bool) {
                /*
                 *  We should rotate left if both the current root node, and
                 *  its right child are both in the past.
                 */
                // Empty call tree.
                if (rootNodeCallKey == 0x0) {
                        return false;
                }

                var currentRoot = call_to_node[rootNodeCallKey];

                // No right child so cant rotate left.
                if (currentRoot.right == 0x0) {
                        return false;
                }

                // Current root already in the future.
                if (key_to_calls[rootNodeCallKey].targetBlock >= block.number) {
                        return false;
                }

                if (key_to_calls[currentRoot.right].targetBlock >= block.number) {
                        return false;
                }

                return true;
        }

        function rotateTree() public {
                /*
                 *  Shifts the root node of the tree so that the root node is
                 *  the tree node prior to the next scheduled call.
                 */
                if (rootNodeCallKey == 0x0) {
                        // No root node (empty tree)
                        return;
                }

                var currentRoot = call_to_node[rootNodeCallKey];
                var rootBlockNumber = key_to_calls[rootNodeCallKey].targetBlock;

                // The current root is in the past so we can potentially rotate
                // the tree to the left to increase the root block number.
                if (rootBlockNumber < block.number) {
                        while (_shouldRotateLeft()) {
                                _rotateLeft();
                        }
                        return;
                }

                // The current root is in the future so we can potentially
                // rotate the tree to the right to decrease the root block
                // number.
                if (rootBlockNumber > block.number) {
                        while (_shouldRotateRight()) {
                                _rotateRight();
                        }
                }
        }

        /*
         *  Scheduling Authorization API
         */
        Relay unauthorizedRelay;
        Relay authorizedRelay;

        function unauthorizedAddress() public returns (address) {
                return address(unauthorizedRelay);
        }

        function authorizedAddress() public returns (address) {
                return address(authorizedRelay);
        }

        mapping (bytes32 => bool) accountAuthorizations;

        function addAuthorization(address schedulerAddress) public {
                accountAuthorizations[sha3(schedulerAddress, msg.sender)] = true;
        }

        function removeAuthorization(address schedulerAddress) public {
                accountAuthorizations[sha3(schedulerAddress, msg.sender)] = false;
        }

        function checkAuthorization(address schedulerAddress, address contractAddress) public returns (bool) {
                return accountAuthorizations[sha3(schedulerAddress, contractAddress)];
        }

        /*
         *  Call Information API
         */
        bytes32 lastCallKey;

        function getLastCallKey() public returns (bytes32) {
                return lastCallKey;
        }

        struct Call {
                address contractAddress;
                address scheduledBy;
                uint calledAtBlock;
                uint targetBlock;
                uint8 gracePeriod;
                uint nonce;
                uint baseGasPrice;
                uint gasPrice;
                uint gasUsed;
                uint gasCost;
                uint payout;
                uint fee;
                address executedBy;
                bytes4 abiSignature;
                bool isCancelled;
                bool wasCalled;
                bool wasSuccessful;
                bytes32 dataHash;
        }

        mapping (bytes32 => Call) key_to_calls;

        /*
         *  Getter methods for `Call` information
         */
        function getCallContractAddress(bytes32 callKey) public returns (address) {
                return key_to_calls[callKey].contractAddress;
        }

        function getCallScheduledBy(bytes32 callKey) public returns (address) {
                return key_to_calls[callKey].scheduledBy;
        }

        function getCallCalledAtBlock(bytes32 callKey) public returns (uint) {
                return key_to_calls[callKey].calledAtBlock;
        }

        function getCallGracePeriod(bytes32 callKey) public returns (uint) {
                return key_to_calls[callKey].gracePeriod;
        }

        function getCallTargetBlock(bytes32 callKey) public returns (uint) {
                return key_to_calls[callKey].targetBlock;
        }

        function getCallBaseGasPrice(bytes32 callKey) public returns (uint) {
                return key_to_calls[callKey].baseGasPrice;
        }

        function getCallGasPrice(bytes32 callKey) public returns (uint) {
                return key_to_calls[callKey].gasPrice;
        }

        function getCallGasUsed(bytes32 callKey) public returns (uint) {
                return key_to_calls[callKey].gasUsed;
        }

        function getCallABISignature(bytes32 callKey) public returns (bytes4) {
                return key_to_calls[callKey].abiSignature;
        }

        function checkIfCalled(bytes32 callKey) public returns (bool) {
                return key_to_calls[callKey].wasCalled;
        }

        function checkIfSuccess(bytes32 callKey) public returns (bool) {
                return key_to_calls[callKey].wasSuccessful;
        }

        function checkIfCancelled(bytes32 callKey) public returns (bool) {
                return key_to_calls[callKey].isCancelled;
        }

        function getCallDataHash(bytes32 callKey) public returns (bytes32) {
                return key_to_calls[callKey].dataHash;
        }

        function getCallPayout(bytes32 callKey) public returns (uint) {
                return key_to_calls[callKey].payout;
        }

        function getCallFee(bytes32 callKey) public returns (uint) {
                return key_to_calls[callKey].fee;
        }

        /*
         *  Data Registry API
         */
        bytes lastData;
        uint lastDataLength;
        bytes32 lastDataHash;

        //function getLastDataHash() public returns (bytes32) {
        //        return lastDataHash;
        //}

        //function getLastDataLength() public returns (uint) {
        //        return lastDataLength;
        //}

        //function getLastData() public returns (bytes) {
        //        return lastData;
        //}

        function getCallData(bytes32 callKey) public returns (bytes) {
                return hash_to_data[key_to_calls[callKey].dataHash];
        }

        mapping (bytes32 => bytes) hash_to_data;

        /*
         *  Data registration API
         */
        //event DataRegistered(bytes32 indexed dataHash);

        function registerData() public {
                bytes trunc;
                if (msg.data.length > 4) {
                        trunc.length = msg.data.length - 4;
                        for (uint i = 0; i < trunc.length; i++) {
                                trunc[trunc.length - 1 - i] = msg.data[msg.data.length - 1 - i];
                        }
                }
                hash_to_data[sha3(trunc)] = trunc;
                lastDataHash = sha3(trunc);
                lastDataLength = trunc.length;
                lastData = trunc;

                // Log it.
                //DataRegistered(lastDataHash);
        }

        /*
         *  Call execution API
         */
        CallerPool callerPool;

        function getCallerPoolAddress() public returns (address) {
                return address(callerPool);
        }

        // This number represents the constant gas cost of the addition
        // operations that occur in `doCall` that cannot be tracked with
        // msg.gas.
        //
        // NOTE: Currently this value seems to vary between 151761 and 151697.
        // Until I can understand why this is happening, or account for it, we
        // use the higher value.
        uint constant EXTRA_CALL_GAS = 151761;
        // uint constant EXTRA_CALL_GAS = 151697;

        // This number represents the overall overhead involved in executing a
        // scheduled call.
        uint constant CALL_OVERHEAD = 145601;

        //event CallExecuted(address indexed executedBy, bytes32 indexed callKey);
        //event CallAborted(address indexed executedBy, bytes32 indexed callKey, bytes18 reason);

        function doCall(bytes32 callKey) public {
                uint gasBefore = msg.gas;

                var call = key_to_calls[callKey];

                if (call.wasCalled) {
                        // The call has already been executed so don't do it again.
                        //CallAborted(msg.sender, callKey, "ALREADY CALLED");
                        return;
                }

                if (call.isCancelled) {
                        // The call was cancelled so don't execute it.
                        //CallAborted(msg.sender, callKey, "CANCELLED");
                        return;
                }

                if (call.contractAddress == 0x0) {
                        // This call key doesnt map to a registered call.
                        //CallAborted(msg.sender, callKey, "UNKNOWN");
                        return;
                }

                if (block.number < call.targetBlock) {
                        // Target block hasnt happened yet.
                        //CallAborted(msg.sender, callKey, "TOO EARLY");
                        return;
                }

                if (block.number > call.targetBlock + call.gracePeriod) {
                        // The blockchain has advanced passed the period where
                        // it was allowed to be called.
                        //CallAborted(msg.sender, callKey, "TOO LATE");
                        return;
                }

                uint heldBalance = getCallMaxCost(callKey);

                if (accountBalances[call.scheduledBy] < heldBalance) {
                        // The scheduledBy's account balance is less than the
                        // current gasLimit and thus potentiall can't pay for
                        // the call.

                        // Mark it as called since it was.
                        call.wasCalled = true;
                        
                        // Log it.
                        //CallAborted(msg.sender, callKey, "INSUFFICIENT_FUNDS");
                        return;
                }

                // Check if this caller is allowed to execute the call.
                if (callerPool.getPoolSize(callerPool.getActivePoolKey()) > 0) {
                        address poolCaller = callerPool.getDesignatedCaller(callKey, call.targetBlock, call.gracePeriod, block.number);
                        if (poolCaller != 0x0 && poolCaller != msg.sender) {
                                // This call was reserved for someone from the
                                // bonded pool of callers and can only be
                                // called by them during this block window.
                                //CallAborted(msg.sender, callKey, "WRONG_CALLER");
                                return;
                        }

                        uint blockWindow = (block.number - call.targetBlock) / 4;
                        if (blockWindow > 0) {
                                // Someone missed their call so this caller
                                // gets to claim their bond for picking up
                                // their slack.
                                callerPool.awardMissedBlockBonus(msg.sender, callKey, call.targetBlock, call.gracePeriod);
                        }
                }

                // Log metadata about the call.
                call.gasPrice = tx.gasprice;
                call.executedBy = msg.sender;
                call.calledAtBlock = block.number;

                // Fetch the call data
                var data = getCallData(callKey);

                // During the call, we need to put enough funds to pay for the
                // call on hold to ensure they are available to pay the caller.
                _deductFunds(call.scheduledBy, heldBalance);

                // Mark whether the function call was successful.
                if (checkAuthorization(call.scheduledBy, call.contractAddress)) {
                        call.wasSuccessful = authorizedRelay.relayCall.gas(msg.gas - CALL_OVERHEAD)(call.contractAddress, call.abiSignature, data);
                }
                else {
                        call.wasSuccessful = unauthorizedRelay.relayCall.gas(msg.gas - CALL_OVERHEAD)(call.contractAddress, call.abiSignature, data);
                }

                // Add the held funds back into the scheduler's account.
                _addFunds(call.scheduledBy, heldBalance);

                // Mark the call as having been executed.
                call.wasCalled = true;

                // Log the call execution.
                //CallExecuted(msg.sender, callKey);

                // Compute the scalar (0 - 200) for the fee.
                uint feeScalar = getCallFeeScalar(call.baseGasPrice, call.gasPrice);

                // Log how much gas this call used.  EXTRA_CALL_GAS is a fixed
                // amount that represents the gas usage of the commands that
                // happen after this line.
                call.gasUsed = (gasBefore - msg.gas + EXTRA_CALL_GAS);
                call.gasCost = call.gasUsed * call.gasPrice;

                // Now we need to pay the caller as well as keep fee.
                // callerPayout -> call cost + 1%
                // fee -> 1% of callerPayout
                call.payout = call.gasCost * feeScalar * 101 / 10000;
                call.fee = call.gasCost * feeScalar / 10000;

                _deductFunds(call.scheduledBy, call.payout + call.fee);

                _addFunds(msg.sender, call.payout);
                _addFunds(owner, call.fee);
        }

        function getCallMaxCost(bytes32 callKey) public returns (uint) {
                /*
                 *  tx.gasprice * block.gaslimit
                 *  
                 */
                // call cost + 2%
                var call = key_to_calls[callKey];

                uint gasCost = tx.gasprice * block.gaslimit;
                uint feeScalar = getCallFeeScalar(call.baseGasPrice, tx.gasprice);

                return gasCost * feeScalar * 102 / 10000;
        }

        function getCallFeeScalar(uint baseGasPrice, uint gasPrice) public returns (uint) {
                /*
                 *  Return a number between 0 - 200 to scale the fee based on
                 *  the gas price set for the calling transaction as compared
                 *  to the gas price of the scheduling transaction.
                 *
                 *  - number approaches zero as the transaction gas price goes
                 *  above the gas price recorded when the call was scheduled.
                 *
                 *  - the number approaches 200 as the transaction gas price
                 *  drops under the price recorded when the call was scheduled.
                 *
                 *  This encourages lower gas costs as the lower the gas price
                 *  for the executing transaction, the higher the payout to the
                 *  caller.
                 */
                if (gasPrice > baseGasPrice) {
                        return 100 * baseGasPrice / gasPrice;
                }
                else {
                        return 200 - 100 * baseGasPrice / (2 * baseGasPrice - gasPrice);
                }
        }

        /*
         *  Call Scheduling API
         */

        // The result of `sha()` so that we can validate that people aren't
        // looking up call data that failed to register.
        bytes32 constant emptyDataHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        function getCallKey(address scheduledBy, address contractAddress, bytes4 abiSignature, bytes32 dataHash, uint targetBlock, uint8 gracePeriod, uint nonce) public returns (bytes32) {
                return sha3(scheduledBy, contractAddress, abiSignature, dataHash, targetBlock, gracePeriod, nonce);
        }

        // Ten minutes into the future.
        uint constant MAX_BLOCKS_IN_FUTURE = 40;

        //event CallScheduled(bytes32 indexed callKey);
        //event CallRejected(bytes32 indexed callKey, bytes15 reason);

        function scheduleCall(address contractAddress, bytes4 abiSignature, bytes32 dataHash, uint targetBlock, uint8 gracePeriod, uint nonce) public {
                /*
                 * Primary API for scheduling a call.  Prior to calling this
                 * the data should already have been registered through the
                 * `registerData` API.
                 */
                bytes32 callKey = getCallKey(msg.sender, contractAddress, abiSignature, dataHash, targetBlock, gracePeriod, nonce);

                if (dataHash != emptyDataHash && hash_to_data[dataHash].length == 0) {
                        // Don't allow registering calls if the data hash has
                        // not actually been registered.  The only exception is
                        // the *emptyDataHash*.
                        //CallRejected(callKey, "NO_DATA");
                        return;
                }

                if (targetBlock < block.number + MAX_BLOCKS_IN_FUTURE) {
                        // Don't allow scheduling further than
                        // MAX_BLOCKS_IN_FUTURE
                        //CallRejected(callKey, "TOO_SOON");
                        return;
                }
                var call = key_to_calls[callKey];

                if (call.contractAddress != 0x0) {
                        //CallRejected(callKey, "DUPLICATE");
                        return;
                }

                if (gracePeriod < 16) {
                        //CallRejected(callKey, "GRACE_TOO_SHORT");
                        return;
                }

                lastCallKey = callKey;

                call.contractAddress = contractAddress;
                call.scheduledBy = msg.sender;
                call.nonce = nonce;
                call.abiSignature = abiSignature;
                call.dataHash = dataHash;
                call.targetBlock = targetBlock;
                call.gracePeriod = gracePeriod;
                call.baseGasPrice = tx.gasprice;

                placeCallInTree(lastCallKey);
                rotateTree();

                //CallScheduled(lastCallKey);
        }

        //event CallCancelled(bytes32 indexed callKey);

        // Two minutes
        uint constant MIN_CANCEL_WINDOW = 8;

        function cancelCall(bytes32 callKey) public {
                var call = key_to_calls[callKey];
                if (call.scheduledBy != msg.sender) {
                        // Nobody but the scheduler can cancel a call.
                        return;
                }
                if (call.wasCalled) {
                        // No need to cancel a call that already was executed.
                        return;
                }
                if (call.targetBlock - MIN_CANCEL_WINDOW <= block.number) {
                        // Call cannot be cancelled this close to execution.
                        return;
                }
                call.isCancelled = true;
                //CallCancelled(callKey);
        }

        function __throw() internal {
                int[] x;
                x[1];
        }
}
