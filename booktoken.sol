// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;



/**
 * @title bookToken
 * @dev ERC-20 token for Celobook usage
 */

interface IERC20Token {
  function transfer(address, uint256) external returns (bool);
  function approve(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 contract BookToken {
        //Tokens parms
    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;
    

        //max Supply of token
     uint maxSupply     =   1000000;
     uint totalSupply   =   0;

        //Reward params
    uint    newUserReward   =   100;
    uint    dailyReward     =   5;

        //User's address are stored to manage rewarding
    uint    nbUsers     =   0;

    struct User {
        uint        userId;
        address     userAddress;
        uint        nextRewardTime;
        uint        totalReward;
    }

    mapping(uint => User)       internal users;
    mapping(address => uint)    internal userIdFromAddress;

    event newUser(uint userId, address userAddress)  external;

            //New User creation
    function createUser() external {
        require(userIdFromAddress[msg.sender] >= 0, "User already stored");
        userIdFromAddress[msg.sender] = nbUsers;
        users[nbUsers] = User(nbUsers, msg.sender, block.timestamp, 0);
        if (totalSupply - maxSupply > newUserReward) {
            _transferToken(nbUsers, newUSerReward);
            users[nbUsers].lastReward = block.timestamp;
        }
        emit newUser(nbUsers, msg.sender);
        nbUsers++;
    }

            //Daily Reward claim
    function claimDailyReward() external {
        require(totalSupply - maxSupply >= dailyReward, "All tokens already sent");
        require(isClaimable(users[usersIdFromAddress[msg.sender]), "No reward claimable");
        _transferToken(msg.sender, dailyReward);
        users[userIdFromAddress[msg.sender]].nextRewardTime = block.timestamp + (1 days);
        users[userIdFromAddress[msg.sender]].totalSupply += dailyReward;
    }

    function isClaimable(uint _userId) public view returns(bool) {
        require(userId < nbUsers, "User not found");
        return (users[_userId].newUserReward < block.timestamp);
    }

            //Private function to manage distribution
    function _transferToken(uint _userId) private {
        require(_userId <= nbUsers, "User not found");
            //TODO => ERC20 Transfer      
    }
 }