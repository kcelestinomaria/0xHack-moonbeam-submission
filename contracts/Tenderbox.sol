// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Tenderbox {
    Tender[] public tenders; 
   
    function createTender (
        string memory _tenderproposal,
        uint _startPrice,
        string memory _description
        ) public{
        require(_startPrice > 0);
        // set a new instance of a tender
        Tender newTender = new Tender(msg.sender, _tenderproposal, _startPrice, _description);
        // push the tender address to tendering sessions array
        tenders.push(newTender);
    }
    
    function returnAllTenders() public view returns(Tender[] memory){
        return tenders;
    }
}

contract Tender {
    
        
    address payable private owner; // Ideally the owner is usually the merchant 
    string tenderproposal;
    uint startPrice;
    string description;

    enum State{Default, InSession, Finalized}
    State public tenderingsessionState;

    uint public highestPrice; // will change to a definite set price
    address payable public highestBidder; // Bidders are ideally suppliers
    mapping(address => uint) public bids;
    
    /** @dev constructor to create a tender
      * @param _owner who call createTender() in a Tenderbox contract
      * @param _tenderproposal is the definition of the tender
      * @param _startPrice the start price of the tender's product
      * @param _description the description of the tender
      */
      
    constructor(
        address payable _owner,
        string memory _tenderproposal,
        uint _startPrice,
        string memory _description
        
        ) public {
        // initialize tender
        owner = _owner;
        tenderproposal = _tenderproposal;
        startPrice = _startPrice;
        description = _description;
        tenderingsessionState = State.InSession;
    }
    
    modifier notOwner(){
        require(msg.sender != owner);
        _;
    }
    
    /** @dev Function to place a bid
      * @return true
      */
    
    function placeBid() public payable notOwner returns(bool) {
        require(tenderingsessionState == State.InSession);
        require(msg.value > 0);
        // update the current bid
        uint currentBid = bids[msg.sender] + msg.value;
        //uint currentBid = bids[msg.sender].add(msg.value);
        require(currentBid > highestPrice);
        // set the currentBid links with msg.sender
        bids[msg.sender] = currentBid;
        // update the highest price
        highestPrice = currentBid;
        highestBidder = msg.sender;
        
        return true;
    }
    
    function finalizeTenderingSession() public{
        //the owner and bidders can finalize the tendering session.
        require(msg.sender == owner || bids[msg.sender] > 0);
        
        address payable recipient;
        uint value;
        
        // owner can get highestPrice
        if(msg.sender == owner){
            recipient = owner;
            value = highestPrice;
        }
        // highestBidder can get no money
        else if (msg.sender == highestBidder){
            recipient = highestBidder;
            value = 0;
        }
        // Other bidders can get back the money 
        else {
            recipient = msg.sender;
            value = bids[msg.sender];
        }
        // initialize the value
        bids[msg.sender] = 0;
        recipient.transfer(value);
        tenderingsessionState = State.Finalized;
    }
    
    /** @dev Function to return the contents of the tendering session
      * @return the tender proposal of the tender
      * @return the start price of the tender
      * @return the description of the tender
      * @return the state of the tendering session 
      */    
    
    function returnContents() public view returns(        
        string memory,
        uint,
        string memory,
        State
        ) {
        return (
            tenderproposal,
            startPrice,
            description,
            tenderingsessionState
        );
    }
    
}