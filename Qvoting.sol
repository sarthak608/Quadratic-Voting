// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EventsQv/ProposalEvents.sol";
import "./Library/VoterLibrary.sol";
import "./Library/ProposalLibrary.sol";
import "./Library/UserProposalLibrary.sol";
import "./QvToken/QvToken.sol";
import "./QvToken/ERC20.sol";
import "./QvToken/Context.sol";
import "./QvToken/IERC20.sol";
import "./QvToken/IERC20Metadata.sol";


// why Poll is inheriting from ReentrancyGuard, CustomOwnable, brainchainEvents ?
contract Qvoting is proposalEvents, QVtoken{
    // what is the use of pollLibrary and UserPollLibrary : difference b/w them?
    using proposalLibrary for proposalLibrary.proposal;
    using UserProposalLibrary for UserProposalLibrary.UserProposal;
    using voterLibrary for voterLibrary.voter;
    //this is not understandable?? SafeERC20 ?? 
    // using SafeERC20 for IERC20;  // how do you think ki lets use this here and what does safeERC20 signifies?

    
    // Iadmin public admin;   // use of admin here !!  interface se instance ku bnaya .. new karke bhi toh bna sakte tha 
    // bool internal isInitialized;
    uint private proposalId;
    // address public root; // root signifies ??
    mapping(address => UserProposalLibrary.UserProposal) public userProposal; //address => userPolls 
    mapping(uint => proposalLibrary.proposal) public proposals; //pollId => pool Detail object
    mapping(address => mapping(uint => voterLibrary.voter)) public allVoters;
    mapping(uint => bool) validProposals;
    // proposals[_proposalId].creator;

    // mapping(uint => bool) public poll_NFT;


    // ye tha is function mai 3rd argument : address _user
    // function initialize(address _root, address _admin) public {
    //     require(!isInitialized,"initialized");
    //     isInitialized = true;
    //     _setOwner(_root);
    //     root = _root;
    //     admin = Iadmin(_admin);
    // }

    // _badgeID,and _token ??
    // why does it have only 1 ques ??

    function createProposal(uint8 _status, address[] memory _voters, address _creator,
      uint256 _startTime, uint256 _expirationTime, string memory _disc, string[] calldata _option,uint _voteRight) external { 
        // start time and end time should be greater than current time ye hona chahiye but what does mean by "pool not started"?
        require(block.timestamp < _startTime,"proposal not started");
        require(block.timestamp < _expirationTime,"End time should be greater than current time");
        require(_startTime < _expirationTime,"End time should be greater than start time");  
        proposalId++;
        proposals[proposalId].createProposal(_status,_voters,_creator,_startTime,_expirationTime,_disc,_voteRight,_option);
        emit ProposalCreated(proposalId, _voters,_creator,_startTime,_expirationTime,_disc,_option);
        validProposals[proposalId] = true;
// 1 -> a=1 b=1 c=1 d=1
// 10 -> a=10 b=10 c=10 d=10

        for(uint256 i=0;i<_voters.length;i++){
            mint(_voters[i],_voteRight);
            allVoters[_voters[i]][proposalId].createVoter(proposalId, _voters[i], false, _voteRight);
            emit mintAndburn("mint",_voters[i],_voteRight);
            }

        userProposal[_msgSender()].updateProposalList(proposalId);
    }

    function responseProposal(uint _proposalId, address _voter, string[] memory _hash, uint[] memory v) external {
        // require(Iuser(admin.userContract()).isUserExist(_msgSender()),"User not exist");

        require(validProposals[_proposalId],"invalid proposalId");
        require(allVoters[_voter][_proposalId].proposalId == _proposalId, "not a valid voter for this proposal");
        
        // ye chaya proposal voter[]!! // access 
        require(!allVoters[_voter][_proposalId].hasVoted, "already voted");
        require(proposals[_proposalId].numOfOptions ==_hash.length, "not a valid length of hash response!");
        uint sum=0;
        for(uint i=0;i<v.length;i++){
            sum+=v[i]*v[i];
        }
        require(allVoters[_voter][_proposalId].voteNum >= sum, "not sufficient balance to cast vote");

        proposals[_proposalId].responseProposal(_voter,_hash, v);
        userProposal[_msgSender()].updateResponseList(_proposalId, _hash);

        allVoters[_voter][_proposalId].updateVoteNum();
        allVoters[_voter][_proposalId].hasVoted = true;
        // burn(_voter,proposals[proposalId].voteRight);
        // emit mintAndburn("burn", _voter, proposals[proposalId].voteRight);
        
    }
    // mint corresponding to proposal Id
    // burn corresponding to proposal Id

    function resultOfProposal(uint _proposalId) public view returns(uint, string memory){
        require(validProposals[_proposalId],"not a valid proposal");
        // require(proposals[proposalId].status ==3,"not completed yet");
        return (proposals[_proposalId].votes[proposals[_proposalId].result[1]],proposals[_proposalId].result[1]);

    }
    // function mintOwner(uint _proposalId, address[] memory _voters) external returns(bool)
    // {
    //     require(validProposals[_proposalId],"Proposal do not exist");
    //     // require(_voteRight >0, "credits should be greater than zero");
    //     uint _voteRight = proposals[_proposalId].voteRight;
    //     for(uint256 i=0;i<_voters.length;i++){
    //         mint(_voters[i],_voteRight);
    //         allVoters[_voters[i]][proposalId].createVoter(proposalId, _voters[i], false, _voteRight);
    //         emit mintAndburn("mint",_voters[i],_voteRight);
    //         }
    //     return true;
    // }
    function burnOwner(uint _proposalId, address _voter) external returns(bool){
        require(allVoters[_voter][_proposalId].hasVoted, "not voted yet");
        require(allVoters[_voter][_proposalId].proposalId == _proposalId, "not a valid voter for this proposal");
        burn(_voter,proposals[_proposalId].voteRight);
        emit mintAndburn("burn", _voter, proposals[_proposalId].voteRight);
        return true;
    }
    
    function burnOwner(uint _proposalId, address[] memory _voters) external returns(bool){
        require(block.timestamp > proposals[_proposalId].expirationTime, "proposal is not completed yet");
        for(uint i=0;i<_voters.length;i++){
        if(!allVoters[_voters[i]][_proposalId].hasVoted && allVoters[_voters[i]][_proposalId].proposalId == _proposalId){
            burn(_voters[i],proposals[_proposalId].voteRight);
            emit mintAndburn("burn", _voters[i], proposals[_proposalId].voteRight);
        }
        else continue;
        }
        return true;
    }
    function winCountLen(uint _proposalId) public view returns(uint){
        return proposals[_proposalId].winnerCount;
    }

    // function resultOfProposalId(uint _proposalId) external returns(bool){
    //     require(validProposals[_proposalId],"not a valid proposal");
    //     proposals[_proposalId].proposalresult();
    //     uint winnerCounts = proposals[_proposalId].winnerCount;
    //     for(uint i =1; i<=winnerCounts;i++)
    //     {
    //         results[_proposalId][i] = proposals[_proposalId].result[i];
    //     }
    //     return true;
    // }

    function resultOfProposalbyId(uint _proposalId) public returns(string[] memory){
        require(validProposals[_proposalId],"not a valid proposal");
        proposals[_proposalId].proposalresult();
        uint _winnerCounts = proposals[_proposalId].winnerCount;
        string[] memory _result = new string[](_winnerCounts);
        for(uint i=1; i<=_winnerCounts;i++)
        {
            _result[i-1] = proposals[_proposalId].result[i];
        }
        return _result;
    }

    function resultOf(uint _proposalId) external returns(string memory){
        require(validProposals[_proposalId],"not a valid proposal");
        proposals[_proposalId].proposalresult();
        return proposals[_proposalId].result[1];
    }
    
    function optionById(uint _proposalId) external view returns(string[] memory){
        require(validProposals[_proposalId],"not a valid proposal");
        uint16 _numOfOptions = proposals[_proposalId].numOfOptions;
        string[] memory _option = new string[](_numOfOptions);
        for(uint16 i=0;i<_numOfOptions;i++){
            _option[i] = proposals[_proposalId].optionHash[i+1];
        }
        return _option;
    }
    function votesArrayById(uint _proposalId) external view returns(uint256[] memory){
        require(validProposals[_proposalId],"not a valid proposal");
        uint16 _numOfOptions = proposals[_proposalId].numOfOptions;
        uint256[] memory _vote = new uint256[](_numOfOptions);
        for(uint16 i=0;i<_numOfOptions;i++){
            _vote[i] = proposals[_proposalId].votes[proposals[_proposalId].optionHash[i+1]];
        }
        return _vote;
    }




}