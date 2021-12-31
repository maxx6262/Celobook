// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC20.sol";
import "./utils/IERC20.sol";

    //Interface ERC20

interface IERC20Token {
  function transfer(address, uint256) external returns (bool);
  function approve(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);

 function  _createAccount(address) external;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Celobook
 * @author M.LECOUSTE
 * @notice - This contract allowes users to make public posts
 *      and to like posts through ERC20 token with fairly regular distribution to users
 * @dev Accounts are stored to manage fair distribution of ERC20 implementation
 *      contract is ownable to manage debug during beta period
*/

contract Celobook {
    address  payable _owner;

    string      public   _nameToken      = "CeloBookToken";
    string      public   _symbolToken    = "CBT";
    uint256     public   _maxSupplyToken = 1000000 * ( 1 * 10 ^ 18);
    uint256     public   _initialSupply  = _maxSupplyToken / 4;

    uint256     public   _newUserReward  = 100 * (1 * 10 ^ 18);
    uint256     public   _dailyReward    = 5 * (1 * 10 ^ 18);

    ERC20     _bookTokenContract;
   
    uint      _newPostFee     =       10 * (1 * 10 ^ 18)  ;
    uint256   _newLikeFee     =       1 * (1 * 10 ^ 18) ;
    uint256   _saleFee        =       10; // sale fee %


    constructor()  {
        _owner  =   payable(msg.sender);
        _bookTokenContract = new ERC20(
            _nameToken,
            _symbolToken,
            _maxSupplyToken,
            _initialSupply,
            _newUserReward,
            _dailyReward
        );
    }
        //Manage ownability
    modifier onlyOwner() {
        require(_owner == msg.sender, "Only owner");
        _;
    }
    function _setOwner(address payable _newOwner) public onlyOwner {
        _owner = _newOwner;
    }
    function getOwner() public view returns(address) {
        return _owner;
    }
    function _setPostFee(uint newPostFee_) public onlyOwner {
        _newPostFee =      newPostFee_ ;
    }
    function _setLikeFee(uint256 newLikeFee_) public onlyOwner {
        _newLikeFee     =   newLikeFee_ ;
    }
    function _setSalefeeLevel(uint256 newSaleFee_) public onlyOwner {
        require(newSaleFee_ > 0 && newSaleFee_ < 1, "Sale fee must be in ]0;1[");
    }
            //Modify Token contract address
    function _setNewTokenContract(ERC20 _newContract) public onlyOwner {
        _bookTokenContract = _newContract;
    }

            //Getter fees
    function    getNewPostFee() public returns(uint256) {
        return _newPostFee;
    }
    function    getNewLikeFee() public returns(uint256) {
        return _newLikeFee;
    }
    function    getSaleFeeLevel() public returns(uint256) {
        return _saleFee * 100;
    }

            //get ERC20 token address 
    function getTokenContract() public view returns(ERC20) {
        return _bookTokenContract;
    }

    
    uint internal productsLength = 0;
    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    uint256 internal nbUsers    =   0;

    struct User {
        address payable userAddress;
        uint256         userId;
        string          pseudo;
        uint64          nbPosts;
        uint64          nbLikes;
        bool            isActive;
    }

    mapping(address => User) users;
        //Create both user account and token wallet
    function createUser(string memory _pseudo) public {
        require(!(users[msg.sender].userId > 0), "User already stored");
        users[msg.sender] = User(
            payable(msg.sender),
            nbUsers,
            _pseudo,
            0,
            0,
            true);
        ERC20(_bookTokenContract)._createAccount(msg.sender);
        nbUsers++;
    }
        //get all user data
    function readUser(address _address) public view returns(
        uint256,        //userId 
        string memory,  //pseudo 
        uint64,         //nbUserPosts
        uint64,         //nbUserLikes
        uint256,        //tokenBalance
        bool            //isActiveUser
        ) {
            require(users[_address].userId > 0, "User not found");
            return(
                users[_address].userId,
                users[_address].pseudo,
                users[_address].nbPosts,
                users[_address].nbLikes,
                _bookTokenContract.balanceOf(_address),
                users[_address].isActive
            );
        }

    modifier onlyUser()  {
        require(users[msg.sender].userId > 0, "Only registered user can process");
        _;
    }

//**************************************************************************************************************************/

//**************************************************************************************************************************/
        // Post Management
    uint256     nbPosts     =   0;

    struct Post {
        uint256             postId;
        address payable     owner;
        string              content;
        uint64              nbLikes;
        bool                isOnSale;
        uint                price;
    }

    event NewPost(uint postId, address owner);
    event OnSale(uint posstId, uint256 price);
    event PostSale(uint postId, address buyer, uint256 price);

    mapping(uint256 => Post) internal posts;

    function newPost(string memory _content) public onlyUser {
        require(ERC20(_bookTokenContract).transferFrom(
            msg.sender,
            address(this),
            _newPostFee * (1 * 10 ^ 18)),
            "Error during transaction");
        nbPosts++;
        posts[nbPosts] = Post(nbPosts, payable(msg.sender), _content, 0, false, 0);
        emit NewPost(nbPosts, msg.sender);
        users[msg.sender].nbPosts++;
        if (!users[msg.sender].isActive) {
            users[msg.sender].isActive = true;
        }
    }

    function putOnSale(uint256 _postId, uint256 _price) public onlyUser {
        require(posts[_postId].owner == msg.sender, "Only post owner can sell");
        require(_price > 0, "Price must be > 0");
        posts[_postId].price = _price * (1 * 10 ^ 18);
        posts[_postId].isOnSale = true;
        emit OnSale(_postId, _price);    
    }

    function buyPost(uint256 _postId) public onlyUser {
        require(ERC20(_bookTokenContract).transferFrom(
                msg.sender,
                payable(address(this)),
                posts[_postId].price * _saleFee / 100
                ),
            "Error during fees payment");
        require(ERC20(_bookTokenContract).transferFrom(
                msg.sender,
                payable(posts[_postId].owner),
                posts[_postId].price * (100 - _saleFee) / 100
                ), "Error during transaction");
        users[posts[_postId].owner].nbPosts--;
        posts[_postId].owner = payable(msg.sender);
        posts[_postId].isOnSale = false;
        users[msg.sender].nbPosts++;
        emit PostSale(_postId, msg.sender, posts[_postId].price);
        if (!users[msg.sender].isActive) {
            users[msg.sender].isActive = true;
        }
    }

    function removeFromSale(uint256 _postId) public onlyUser {
        require(posts[_postId].owner == msg.sender, "only owner can cancel sale");
        posts[_postId].isOnSale = false;
    }

    function likePost(uint256 _postId) public onlyUser {
        require(ERC20(_bookTokenContract).transferFrom(
            msg.sender,
            payable(address(this)),
            _newLikeFee
        ), "Error during fee payment");
        require(ERC20(_bookTokenContract).transferFrom(
            msg.sender,
            payable(posts[_postId].owner),
            1 * 10 ^ 18), "Error during transaction"
        );
        posts[_postId].nbLikes++;
        if (!users[msg.sender].isActive) {
            users[msg.sender].isActive = true;
        }
    }

    function claimReward() public onlyUser {
        require(users[msg.sender].isActive, "Only active users can claim");
        _bookTokenContract.claim(msg.sender);
    }

//****************************************************************************************/

            //Token Management private functions
    function _transferToken(address _to, uint256 _amount) private {
        ERC20(_bookTokenContract).transfer(_to, _amount);
    }
}   
