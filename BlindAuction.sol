pragma solidity >=0.4.22 <=0.6.0;

contract BlindAuction{
    /*An auction system where people bid without other participant
    having an idea of their bid amount*/

    struct Bid {
        bytes32 blindedBid; //hashed version of the bid
        uint deposit;   //A deposit significantly higher than the bid amount
    }

    //Auction state
    enum phase {
        init,
        bidding,
        reveal,
        done
    }

    phase public currentState = phase.init;
    address payable beneficiary; //owner of the item to be auctioned
    address public highestBidder;
    uint public highestBid = 0;
    mapping (address => uint) depositReturns; //return of deposits for nonwinners
    mapping(address => Bid) bids; //Only one bid per address.

    event AuctionEnded(address winner, uint highestBid);
    event BiddingStarted();
    event RevealStarted();

    modifier validPhase (phase reqPhase) {
        require(currentState == reqPhase);
        _;
    }
    modifier onlyBeneficiary (){
        require(msg.sender == beneficiary);
        _;
    }

    constructor() public {
        //beneficiary becomes the address that deployed the contract.
        beneficiary = msg.sender;
    }

    function changeState() onlyBeneficiary public {
        //If already in the done phase, reset to init phase say for another auction item.
         if (currentState == phase.done){
             currentState = phase.init;
         }else {
             //else move to an higher state.
             uint newState = uint(currentState) + 1;
             currentState = phase(newState);
         }
        //emitting events (notification) for each phase
         if (currentState == phase.reveal) emit RevealStarted();
         if (currentState == phase.bidding) emit BiddingStarted();
    }

    function bid(bytes32 blindBid) public payable validPhase(phase.bidding){
        /** 
            Function to place blind bid. The blindBid variable is an hash of the value of the bid.
         */
        bids[msg.sender] = Bid({
            blindedBid: blindBid,
            deposit: msg.value
        });
    }

    //check if the blind bid == the open bid
    //check if the deposited amount is grater than the bid amount
    //check if your bid is the highst (by callinng placeBid)
    //refund the remainder after subracting the bid amount from the deposit
    function reveal(uint bidAmt, bytes32 secret) public validPhase(phase.reveal) {
        uint refund = 0;
        Bid storage bidToCheck = bids[msg.sender];
        //if the initially sent blindedBid is the same as the manually computed hash of the open bid amount, proceed
        if (bidToCheck.blindedBid == keccak256(abi.encodePacked(bidAmt,secret))){
            //The money to be refunded is equal to the deposit
            refund += bidToCheck.deposit;
            //check if the originally deposited money is greater than the open bid amt sent
            if (bidToCheck.deposit >= bidAmt) {
                //If this user is the highest bidder, subtract the bid amt from the money to be refunded
                if (placeBid(msg.sender, bidAmt))
                refund -= bidAmt;
            }
        }
        //Transfer the reaminder to the user
        msg.sender.transfer(refund);
    }

    function placeBid(address bidder, uint value) internal returns (bool success){
        //If the bid amount is less than the highest bid, return false
        if (value <= highestBid) {
            return false;
        }
        /*currently, the highestBidder variable is an uninitialized address - '0x0'
        address(0) means an uninitialized address = '0x0'
        so, if the current highest bidder is not an uninitialized account and the 
        new bid amount is greater than the the current highest bid (the first if stmt)
        refund the previously highest bidder */
        if (highestBidder != address(0)) {
            // Refund the previously highest bidder
            depositReturns[highestBidder] += highestBid;
        }
        //The new highest bidder and highest bid
        highestBid = value;
        highestBidder = bidder;
        return true;
    }
    
    function withdraw() public {
        /** Function to withdraw a non winning bid and it is invocked by losers. */
        uint amount = depositReturns[msg.sender];
        require (amount > 0);
        depositReturns[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function auctionEnd() public validPhase(phase.done){
        //ends auction by changing the phase to done and transfer the highest bid to the beneficiary
        beneficiary.transfer(highestBid);
        emit AuctionEnded(highestBidder, highestBid);
    }

}