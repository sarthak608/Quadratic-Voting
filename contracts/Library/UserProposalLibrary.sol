// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library UserProposalLibrary{
    struct UserProposal{
    
    // createCount
    uint128 proposalCount;

    // resposeCount
    uint128 responseCount;

     // poll creation property
    mapping(uint128 => uint) proposalCreated; 
    
    // poll response property
    mapping(uint128 => uint) proposalResponsed; // response kis pollId par aaya hain
    mapping(uint => mapping(uint => string)) proposalAnswer; //pollId => answerHash  
    mapping(uint => bool) responsedProposal; 

    }
    function updateProposalList(UserProposal storage self, uint _proposalId) internal returns(bool){
        self.proposalCount++;
        self.proposalCreated[self.proposalCount] = _proposalId;
        return true;
    }

    function updateResponseList(UserProposal storage self, uint _proposalId, string[] memory _hash) internal returns(bool){
        self.responseCount++;  
        self.proposalResponsed[self.responseCount] = _proposalId;
        // uint len =_hash.length();
        // for(uint i=0;i<len;i++){
        //     self.proposalAnswer[_proposalId][i+1] = _hash[i];
        // }
        for(uint16 i=0;i<_hash.length;i++){
            self.proposalAnswer[_proposalId][i+1] = _hash[i];
        }
        self.responsedProposal[_proposalId] = true;
        return true;
    }


}