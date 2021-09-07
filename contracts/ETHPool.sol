//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title ETHPool Challenge
/// @author Luciano De Giorgi
/// @notice Service where people can deposit ETH and they will receive weekly rewards

contract ETHPool is ReentrancyGuard {
    enum TransactionTypes{ DEPOSIT, REWARD }

    event Deposit(address indexed _address, uint _value, string indexed _txType);
    event Withdraw(address indexed _address, uint _value);

    // ToDo: We can define the team as an address array to allow more than one user to fulfill that role
    address private team;
    address private owner;

    uint private startDate;
    uint private totalAccounts = 0;
    uint private constant DAY_IN_SECONDS = 86400;
    uint private constant PRECISION = 10**4;
    bool private autocompound = false;
    
    struct Transaction {
        uint timestamp;
        uint amount;
        TransactionTypes txType;
    }

    mapping (uint => address) private accounts;
    mapping (address => Transaction[]) private poolTransactions;

    constructor() {
        startDate = block.timestamp-1;
        owner = msg.sender;
        team = msg.sender;
    }

    function getDays(uint timestamp) public pure returns (uint) {
        return (timestamp / DAY_IN_SECONDS);
    }
    
    modifier onlyTeam() {
        require(msg.sender == team, "Caller is not the team");
        _;
    }

    function changeTeam(address _newTeam) public onlyTeam {
        team = _newTeam;
    }

	/**
	 * @notice Toggle Autocompound feature
     * @param _active true/false to activate or inactive Autocompund.
	 * */
    function setAutocompound(bool _active) public onlyTeam {
        autocompound = _active;
    }

	/**
	 * @notice Deposit amount to ETHPool
	 * */
    function deposit() public payable {
        require(msg.value != 0, "Amount must be greater than zero");
        
        if(poolTransactions[msg.sender].length == 0) {
            accounts[totalAccounts] = msg.sender;
            totalAccounts++;
        }

        _addTransaction(msg.sender, msg.value, TransactionTypes.DEPOSIT);
    }

    function _addTransaction(address _account, uint _amount, TransactionTypes _txType) internal {
        Transaction[] storage transactions = poolTransactions[_account];
        transactions.push(Transaction(block.timestamp, _amount, _txType));

        string memory typeDesc = _txType == TransactionTypes.DEPOSIT ? "Deposit" : "Reward";
        
        emit Deposit(_account, _amount, typeDesc);
    }

	/**
	 * @notice Withdraw the input amount of ETH. It will be withdrawn from oldest to newest
	 * @param _amount The number of ETH to withdraw. 
	 * */
    function withdraw(uint _amount) public nonReentrant {
        require(_amount != 0, "The amount must be greater than zero");

        uint totalAmount = _amount;

        Transaction[] storage transactions = poolTransactions[msg.sender];
        for (uint idx = 0; idx < transactions.length; idx++) {

            if(totalAmount == 0)
                break;

            if(transactions[idx].amount <= totalAmount){
                totalAmount -= transactions[idx].amount;
                transactions[idx].amount = 0;
            }
            else {
                transactions[idx].amount -= totalAmount;  
                totalAmount = 0;                                     
            }               
        }

        require(totalAmount == 0, "Insufficient funds");

        emit Withdraw(msg.sender, _amount);
    }

	/**
	 * @notice Deposit the rewards sent by the team
	 * */
    function depositRewards() public payable onlyTeam {
        require(totalAccounts != 0, "There are no accounts to distribute the reward");
        require(msg.value != 0, "The reward amount must be greater than zero");

        uint[] memory weighted = new uint[](totalAccounts);
        uint totalWeightedAcum = 0;
        uint totalDays = getDays(block.timestamp - startDate);

        // Get the weighted average of deposits by user
        for (uint idxUsr = 0; idxUsr < totalAccounts; idxUsr++) {
            address account = accounts[idxUsr];

            Transaction[] memory transactions = poolTransactions[account];
            uint totalWeighted = 0;
            
            for (uint index = 0; index < transactions.length; index++) {
                if((transactions[index].txType == TransactionTypes.DEPOSIT) || 
                   (autocompound && (transactions[index].txType == TransactionTypes.REWARD))){

                    uint permanenceDays = getDays(block.timestamp - transactions[index].timestamp);
                    totalWeighted += transactions[index].amount * permanenceDays;            
                }
            }

            // total weighted according to the number of days elapsed
            weighted[idxUsr] = totalWeighted / totalDays;          
            totalWeightedAcum += weighted[idxUsr];

        }

        if(totalWeightedAcum > 0) {
            for (uint idxUsr = 0; idxUsr < totalAccounts; idxUsr++) {
                address account = accounts[idxUsr];

                // The PRECISION const is used as workaround to calculate percentages with acceptable precision (related to division problems with uint)
                uint percent = (weighted[idxUsr] * (100 * PRECISION) / totalWeightedAcum);
                uint rewardAmount =  (msg.value * percent) / (100 * PRECISION);

                _addTransaction(account, rewardAmount, TransactionTypes.REWARD);        
            }
        }
    }    

    function getTotalBalance() public view returns (uint) {
        uint totalDeposit = 0;
        uint totalReward = 0;        
        (totalDeposit, totalReward) = _getTotalBalanceByType(msg.sender);

        return totalDeposit + totalReward;
    }

    function getTotalBalanceByType() public view returns (uint, uint)  { 
        return _getTotalBalanceByType(msg.sender);
    }

    function _getTotalBalanceByType(address _account) internal view returns (uint, uint) {
        Transaction[] memory transactions = poolTransactions[_account];
        uint totalDeposit = 0;
        uint totalReward = 0;
        for (uint index = 0; index < transactions.length; index++) {
            if(transactions[index].txType == TransactionTypes.DEPOSIT) 
                totalDeposit += transactions[index].amount;
            else
               totalReward += transactions[index].amount;
                
        }

        return (totalDeposit, totalReward);
    }

}
