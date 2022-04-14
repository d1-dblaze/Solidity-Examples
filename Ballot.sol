pragma solidity >=0.6.0;

/**
    A decentralized voting system where people vote to choose a proposal from a set of proposal
    Voters can only vote once. Chairperson's vote is weighted twice as heavy as regular people's votes.
 */
contract Ballot {

    struct Voter{
        uint weight;
        bool voted;
        uint vote;
    }
    struct Proposal{
        uint voteCount;
    }
    enum Phase {
        init,
        regs,
        vote,
        done
    }

    address chairPerson;
    //map address to their vote details.
    mapping(address => Voter) voters;
    //creating an array of proposals users would vote for
    Proposal[] proposals;
    //Initializing the state variable with init phase.
    Phase public state = Phase.init;


    modifier validPhase(Phase reqPhase) {
        //if the current state is equal to the sent phase, proceed to the desired func.
        require(state == reqPhase);
        _;
    }
    modifier onlyChair (){
        require(msg.sender == chairPerson);
        _;
    }

    constructor (uint numProposals) public{
        //constructor function is called on deployment.
        //whoever who called the constructor function is the chairperson
        chairPerson = msg.sender;
        //The vote of the chairperson is x2 that of normal voters.
        voters[chairPerson].weight = 2;
        for (uint prop = 0; prop < numProposals; prop++){
            proposals.push(Proposal(0));
        }
        //once the contract has been deployed, change phase to registration phase.
        state = Phase.regs;
    }

    function changeState (Phase newState) onlyChair public{
        //Only the chairPerson can invoke this function

        /*state is an enum internally represented by numbers 0-3, we want to change state
        from init to done (0-3), that means each newState must be higher than previous state */
        require(newState < state);
           
        state = newState;
    }

    function register(address voterAddress) public validPhase(Phase.regs) onlyChair{
        /*if the caller of this function is not the chairPerson (can self-register) or
        if the voter calling this function has already voted, revert.*/
        require(! voters[voterAddress].voted);
        //vote weight of ordinary voters is 1
        voters[voterAddress].weight = 1;
        voters[voterAddress].voted = false;
    }

    function vote(uint forThisProposal) public validPhase(Phase.vote){
       ///create a variable of type Voter and assign the value of the voters address mapping to it
        Voter memory sender = voters[msg.sender];
        /*if the function invocator has already voted or vote for a proposal that is not
        on the proposals list, revert*/
        require(! sender.voted);
        require(forThisProposal < proposals.length);
        sender.voted = true;
        //set the proposal index the user voted for.
        sender.vote = forThisProposal;
        //update the proposal vote count
        proposals[forThisProposal].voteCount += sender.weight;
    }

    function reqWinner () public validPhase(Phase.done) view returns (uint winningProposal){
        //view modifier makes the transaction not recorded on the chain.
        uint winningVotecount = 0;
        //loop through the list of proposals
        for (uint prop = 0; prop < proposals.length; prop++){
            //if the current proposal voteCount is greater than the winningVoteCount
            //set the winningVotecount and the winningProposal
            if (proposals[prop].voteCount > winningVotecount){                
                winningVotecount = proposals[prop].voteCount;
                winningProposal = prop;
            }
        }
    }


    

}