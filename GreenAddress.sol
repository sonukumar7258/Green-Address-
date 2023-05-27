//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract GreenAddress
{
    address  manager;
    uint256  rewardAmount;

    // mappings
    mapping(address => bool)  subordinatedNodes;
    mapping(address => uint256) public balanceAmounts;
    mapping(bytes32 => address)  transactionHash;
    mapping(bytes32 => uint256) hashedAmount;

    //events
    event deposit(address indexed sender,uint256 amount);
    event AmountSent(address indexed sender, uint256 amount);
    event rewardManager(address indexed poolmanager,uint256 amount);


    constructor(){
    manager = msg.sender;
    }

    modifier onlyManager(){
        require(msg.sender == manager, "Only Pool Manager Can Perform this");
        _;
    }

    modifier onlySubordinatedNodes(){
        require(subordinatedNodes[msg.sender],"Only subordinates Can Perform this");
        _;
    }

    function addSubordinatedNodes(address node) public onlyManager {
       subordinatedNodes[node]  = true;
    }

    function verifySubordinateIsConnected(address node) public view returns(bool){
        return subordinatedNodes[node];
    }

    function setRewardAmount(uint256 _reward) public onlyManager{
        rewardAmount = _reward;
    }

    function depositAmount(uint256 amount) public payable onlySubordinatedNodes{
        require(amount > 0, "Amount must be greater than 0");
        balanceAmounts[msg.sender] += amount;
        emit deposit(msg.sender,amount);
    }

    function calculateHash(uint256 amount, address addr) public pure returns (bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(amount, addr));
        return hash;
    }

    function sendMoneytoPoolManager(uint256 amount) public payable onlySubordinatedNodes returns(bytes32) {
        require(verifySubordinateIsConnected(msg.sender), "Only Connected Subordinates Can send");
        require(amount > 0,"Amount must be greater than 0!!");
        require(balanceAmounts[msg.sender] >= amount,"Insufficient Balance!!");

        bytes32 Hash = calculateHash(amount,msg.sender);
        transactionHash[Hash] = msg.sender;
        hashedAmount[Hash] = amount;
        emit AmountSent(msg.sender,amount);
        return Hash;
    }

    
    function verifyTransaction(bytes32 _transactionHash) public view returns (address) {
        return transactionHash[_transactionHash];
    }


    function SendToAnotherUser(address _reciver,bytes32 hash)public payable onlyManager{
        require(verifySubordinateIsConnected(transactionHash[hash]), "Given Hash is not connected to any of the Connected Subordinates");
        require(verifySubordinateIsConnected(_reciver), "Only Connected Subordinates Can send");
        
        balanceAmounts[_reciver] += hashedAmount[hash];
        balanceAmounts[transactionHash[hash]] -= hashedAmount[hash];
        balanceAmounts[manager] += rewardAmount;
        emit rewardManager(manager,rewardAmount);
    }
}