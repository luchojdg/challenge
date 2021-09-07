## Solution of the ETHPool Challenge

To solve this challenge, we are going to consider two important variables in our calculations, which are: the amount deposited and the number of days this amount was deposited. On the other hand, for greater flexibility and precision, we must be able to identify each deposit / day since surely the same user will want to deposit more than once over time, so each of their deposits must be weighted to obtain a accumulated total weighted that allows us to calculate the incidence percent of your deposits within the pool.

**Advantages:**
  
 - It benefits users who stay longer in the pool but also is consider
   the amounts deposited. 
 - Possibility of making multiple deposits at different times The team is not limited to depositing the reward on a specific day 
 - Possibility of making partial withdrawals (withdrawal is made through FIFO, which discourages withdrawal due to loss of antique in the pool) 
 - Possibility of performing Autocompound 

**Explanation of the applied methodology:**

We start by putting together a list of the amounts deposited by each user for which we want to find the weighted average.

Then we must determine how much each of them weighs based on the number of days of deposit as part of the final average.

For example: **A** deposited *150 ETH* on *day 1* and on *day 5* deposited *200 ETH*, while **B** deposited *300 ETH* on *day 3* and **T** deposited *60 ETH* on *day 7*.
  

*Note: As each user can make more than one deposit over time, first we are going to obtain the weighted total per user and we will accumulate it and then calculate the percentage of participation in the pool. In our case, we will multiply each amount deposited by the number of days of permanence (weighting factor).*

In our example we must do:

For **A**:
(150 * (7-1) + 200 * (7-5)) / 7 = **185.71 ETH**

For **B**:
(300 * (7-3)) / 7 = **171.43 ETH**

Accumulated weighted total: 185.71 + 171.43 = **357.14 ETH**.

Then we calculate the percentage of participation of each of the users in the pool

A: 185.71 * 100 / 357.14 = **52%**
B: 171.43 * 100 / 357.14 = **48%**

As a final result, we have that **A** will receive a reward of **31.2 ETH** and **B** will receive a reward of **28.8 ETH**.

## The Precision workaround
The PRECISION const (4 decimals -> 10**4) is used to calculate percentages and division with acceptable precision. This is a problem related to the divisions with uint types.
The workaround is to multiply the amounts by the desired precision before performing the division and once the calculation is done, divide by that precision. In this way we can minimize the loss of decimals caused by truncation of uint cast.

## Transaction Struct
It allows us to identify each deposit made by the user
Each deposit and send of rewards to the user is stored using the following mapping:

mapping (address => Transaction []) private poolTransactions;

Where the new transaction is inserted into the array using the following parameters:

 - **timestamp**: the date the new transaction was added. 
 - **amount**: The amount of the transaction
 -  **txType**: The type of movement (it can be DEPOSIT or REWARD)

## Mapping Accounts

Since it is not possible to iterate through the poolTransactions mapping, we need to store the total number of users that are added to the pool and assign a unique position using the following mapping:

mapping (uint => address) private accounts;

The user will be added on that map when they submit their first deposit.


## Main Functions
#### Deposit

deposit() is a payable function that receives the amount (msg.value) from the user (msg.sender) and adds a new transaction in ** poolTransactions **

#### Withdraw

withdraw(uint _amount) is a nonReentrant function that receives the amount to withdraw and decreases the amount deposited/rewarded using FIFO (First input, first output)

#### Deposit Reward

depositRewards() is a payable function that receives the reward amount (msg.value) from the team (msg.sender) and distributes the reward to each user calculating the weighted average according to the amount deposited and the days of permanence

#### Get Total Balance

getTotalBalance() is a function that gets the total amount of deposit+reward from the user (msg.sender). Internally it uses the _getTotalBalanceByType() function that returns the totals broken down by transaction type

#### Get Total Balance by Type

getTotalBalanceByType() is a function that gets the totals broken down by transaction type (deposit and reward). Internally it uses the function _getTotalBalanceByType()

## Other Functions

### Get Days

getDays (uint timestamp) is a function that gets the total days from unix epoch.

### Set Autocompound

setAutocompound() alows the team to switch on/off the autocompound function

### Add Transaction

_addTransaction (address _account, uint _amount, TransactionTypes _txType) is an internal function that adds a new type of transaction to the pool and emits a deposit event.

 
## Events

- **Deposit**: Emmited when a new transaction (deposit or reward) is added to the pool
- **Withdraw**: Emmited when a user withdraws funds from the pool


