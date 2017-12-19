pragma solidity ^0.4.19;

import './IERC20.sol';
import './SafeMath.sol';

    contract owned {
        address public owner;

        function owned() public {
            owner = msg.sender;
        }

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }

        function transferOwnership(address newOwner) public onlyOwner {
            owner = newOwner;
        }
    }

contract CCoin is IERC20, owned {
    using SafeMath for uint256;
    
    uint256 public sellPrice;
    //1 ether = 35 C$
    uint256 public buyPrice = 35;
    
    uint public _totalSupply = 300000000;  //60% to iCarriage
    
    string public constant symbol = "C$";
    string public constant name = "CCoin";
    uint8 public constant decimals = 18;
    
  
    
    bool crowdSaleClosed = false;
    
    address public owner;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
   
    
    function crowdSaleOpenClosed() onlyOwner public returns (bool success) {
        if(crowdSaleClosed){
            crowdSaleClosed = false;
            CrowdSaleOpenedClosed(owner);
            return true;
        }
        else if(!crowdSaleClosed){
            crowdSaleClosed = true;
            CrowdSaleOpenedClosed(owner);
            return true;
        }
    }
    
    /// @notice Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
    /// @param newSellPrice Price the users can sell to the contract
    /// @param newBuyPrice Price users can buy from the contract
    function setPrices(uint256 newBuyPrice, uint256 newSellPrice) onlyOwner public {
        buyPrice = newBuyPrice;
        sellPrice = newSellPrice;
        PriceChanged(owner, buyPrice, sellPrice);
        
    }
    
    
    /// @notice Sell `amount` tokens to contract
    /// @param amount amount of tokens to be sold
    function sell(uint256 amount) public {
        require(this.balance >= amount * sellPrice);      // checks if the contract has enough ether to buy
        Transfer(msg.sender, this, amount);              // makes the transfers
        msg.sender.transfer(amount * sellPrice);          // sends ether to the seller. It's important to do this last to avoid recursion attacks
    }
    
    function () external payable {
        //require(!crowdSaleClosed);
        require(msg.value >= .25 ether);  //Minimum coin purchase for ICO
        if(crowdSaleClosed) revert();
    
        createCoins();
    }
    
    
    function CCoin() public {
        owner = msg.sender;
    }
    
    function createCoins() public payable{
        require(msg.value > 0);
        
        uint256 coins = msg.value.mul(buyPrice);
        balances[msg.sender] = balances[msg.sender].add(coins);
        _totalSupply = _totalSupply.add(coins);
        
        owner.transfer(msg.value);
        if(_totalSupply >= 500000000) {  //cap on coin max supply
            crowdSaleClosed = true; 
        }
    }
    
    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        //balances[_to] = balances[_to].add(_value);
        balances[target] = balances[target].add(mintedAmount);
        _totalSupply = _totalSupply.add(mintedAmount);
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }
    
    function totalSupplyCCoins() public view returns (uint256 totalSupply){
        return _totalSupply;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance){
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
       require(
           balances[msg.sender] >= _value
           && _value > 0
           );
           balances[msg.sender] = balances[msg.sender].sub(_value);
           balances[_to] = balances[_to].add(_value);
           Transfer(msg.sender, _to, _value);
           return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
       require(
           allowed[_from][msg.sender] >= _value
           && balances[_from] >= _value
           && _value > 0
           );
           balances[_from] = balances[_from].sub(_value);
           balances[_to] = balances[_to].add(_value);
           allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
           Transfer(_from, _to, _value);
           return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
       allowed[msg.sender][_spender] = _value;
       Approval(msg.sender, _spender, _value);
       return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowed[_owner][_spender];
    }
    
    /* Function to recover the funds on the contract */
    function kill() onlyOwner() public{
        selfdestruct(owner);
    }
    
   
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event CrowdSaleOpenedClosed(address indexed _owner);
    event PriceChanged(address indexed _owner, uint256 indexed newBuyPrice, uint256 indexed newSellPrice);
    
   
}