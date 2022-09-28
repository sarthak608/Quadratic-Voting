// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// import "VoterLibrary.sol";


library proposalLibrary{

    struct proposal{
        // uint256 proposalId;
        address creator;
        uint8 status;
        string disc;
        // address[] voters;
        uint256 startTime;
        uint256 expirationTime;
        uint16 numOfOptions;
        uint voteRight;
        mapping(address => bool) voters;
        uint winnerCount;
        // mapping(address => voter) voterInfo;
        
        // option -> option || replace 
        // create proposal props
        mapping(string => bool) option;
        mapping(uint256 => string) optionHash;

        // respose proposal props
        mapping(uint => string) result;
        mapping(string => uint) votes;
    }
    // create proposal
     function createProposal(proposal storage self, uint8 _status, address[] memory _voters, address _creator,
      uint256 _startTime, uint256 _expirationTime, string memory _disc, uint _voteRight, string[] calldata _option) internal returns(bool){
                                self.creator = _creator;
                                self.status = _status;
                                self.disc = _disc;
                                self.startTime = _startTime;
                                self.expirationTime = _expirationTime;
                                self.numOfOptions = uint16(_option.length);
                                self.voteRight = _voteRight;
                                for(uint256 i=0;i<_option.length;i++){
                                    self.option[_option[i]] = true;
                                    self.optionHash[i+1] =  _option[i];
                                }
                                for(uint256 i=0;i<_voters.length;i++){
                                    self.voters[_voters[i]] = true;
                                }
                                self.winnerCount=3;
                                return true;

                            }
    
    // take response 
    function responseProposal(proposal storage self, address _voter, string[] memory _hash, uint[] memory v) internal returns(bool){
        require(self.status == 2, "Proposal: inactive");
        require(block.timestamp >= self.startTime, "proposal not started yet");
        if(block.timestamp > self.expirationTime){ 
            return false;
        }

        // if active 
        require(self.voters[_voter], "Not a valid voter for this proposal");
        for(uint16 i=0;i<self.numOfOptions;i++){
        require(self.option[_hash[i]], "Proposal: invalid optionHash");
        self.votes[_hash[i]]+=v[i];
        }
        return true;
    }
    function proposalresult(proposal storage self) internal returns(bool){
        require(block.timestamp > self.expirationTime, "Proposal hasn't ended yet!");
            // answer || result aayega
            self.status = 3;
            uint largestCount = self.votes[self.optionHash[1]];
            uint _winnerCount = 1;
            self.result[1] = self.optionHash[1];
            // this for loop is used to find the winner count
            for(uint16 i = 2; i <= self.numOfOptions; i++){
                if(self.votes[self.optionHash[i]] > largestCount){
                    largestCount = self.votes[self.optionHash[i]];
                    _winnerCount = 1;
                    self.result[1] = self.optionHash[i];
                }else if(self.votes[self.optionHash[i]] == largestCount){
                    _winnerCount++;
                    self.result[_winnerCount] = self.optionHash[i];
                }
            }
        self.winnerCount = _winnerCount; 
        return true;
    }    
    

}