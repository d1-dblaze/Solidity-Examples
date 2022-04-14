pragma solidity >=0.4.22 <=0.6.0;

/*
    This is an airline consortium that enables peer-to-peer transactions of flight seats among participating airlines.
 */
contract Airlines {
    address chairPerson; //address of the consortium monitorer that is periodically rotated;
    struct reqStruct{
        uint reqID; //a unique id created for every request.
        uint fID;   //flight ID
        uint numSeats;  //num of seat requested;
        uint passengerID; //Passenger ID
        address toAirline;  //Airline you are sending the request to. This is not a broadcast system.
    }

    struct respStruct{
        uint reqID; //The unique ID of the request
        bool status;  //The answer to the request made
        address fromAirline; // Airline that made the request.
    }

    mapping (address => uint) public escrow; //Address mapping to amount deposited.
    mapping (address => uint) membership; //Address mapping to permanent, static members id
    mapping (address => reqStruct) request; //Address mapping to request made
    mapping (address => respStruct) response;   //Address mapping to response made
    mapping (address => uint)   settledReqID;    //Address mapping to reqId as proof of payment.

    //If the Invocator of the function is the chairperson, execute the called function.
    modifier onlyChairPerson(){
        require(msg.sender==chairPerson);
        _;
    }
    /*If the Invocator of the function is a member of the consortium 
    (1 is the id of members), execute the called function.*/
    modifier onlyMember (){
        require(membership[msg.sender] == 1);
        _;
    }

    constructor () public payable{
        chairPerson = msg.sender;   //Anyone that deploys this contract is the chairperson which doesn't make sense.
        membership[msg.sender] = 1; //Becomes a member on deployment
        //The value of the 'balanceDetails[msg.sender]' returns and is assigned the value (amount of ether or wei sent)
        escrow[msg.sender] = msg.value;
    }

    function register() public payable{
        address airlineAddress = msg.sender;
        membership[airlineAddress] =1;
        escrow[msg.sender] = msg.value;
    }

    function unregister(address payable airlineAddress) onlyChairPerson public {
        //Revoke the membership
        membership[airlineAddress] = 0;
        //Transfer the initially deposited escrow by the address to the address back.
        airlineAddress.transfer(escrow[airlineAddress]);
        //update the airline balanceDetails with 0 since all asset has been transferred back
        escrow[airlineAddress] = 0;
    }

    function ASKrequest(uint reqID, uint flightID, uint numSeats, uint custID, address toAirlineAddress) onlyMember public{
        /*If the address you are sending the request to is not a member of the consortium
        raise and exception and return the unused gas back to the caller */
        require (membership[toAirlineAddress] == 1);
        //create a request structure and map to the address that called this function.
        request[msg.sender] = reqStruct(reqID, flightID, numSeats, custID, toAirlineAddress);
    }

    function ASKresponse(uint reqID, bool answer, address fromAirlineAddress) onlyMember public {
        /*If the address you are sending the response to is not a member of the consortium
        raise and exception and return the unused gas back to the caller */
        require (membership[fromAirlineAddress] == 1);
        /*The answer variable is the status of the transactions e.g available*/
        response[msg.sender].status = answer;
        response[msg.sender].fromAirline = fromAirlineAddress;
        response[msg.sender].reqID = reqID;
    }

    function settlePayment(uint reqID, address payable toAirline, uint numOfSeats) onlyMember payable public{
        address fromAirlineAddress = msg.sender;
        uint amt = msg.value;
        //update the mapping
        escrow[toAirline] = escrow[toAirline] + numOfSeats * amt;
        escrow[fromAirlineAddress] = escrow[fromAirlineAddress] - numOfSeats * amt;
        //request ID is stored as proof of payment.
        settledReqID[fromAirlineAddress] = reqID;
    }

    //for if your escrow balance is low. you need to replenish it.
    function replenishEscrow () payable public {
        escrow[msg.sender] = escrow[msg.sender] + msg.value;
    }
}
