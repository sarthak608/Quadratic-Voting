// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library voterLibrary{
      struct voter {
        uint proposalId; 
        address voterAddress;
        bool hasVoted;
        uint256 voteNum;

    }
    // hasVoted - direct check by self.hasVoted
    // function hasVoted(voter storage self) internal returns(bool){
    //   require(self.proposalId!=0,"Invalid voter!");
    //   return self.hasVoted;
    // }
    // hasEnoughToken - direct use karega
    // function hasEnoughToken(voter storage self, uint256 _voteCast) internal returns(bool){
    //   require(self.proposalId!=0,"Invalid voter!");
    //   require(!self.hasVoted, "already voted");
    //   require(self.voteNum >=_voteCast, "not have enough token");
    //   return true;
    // }
    // updatevoteNum after vote_Cast
    function updateVoteNum(voter storage self) internal returns(bool){
      require(self.proposalId!=0,"Invalid voter for proposalId!");
      require(!self.hasVoted, "not voted");
      self.voteNum = 0;
      return true;
    }
    // createVoter
     function createVoter(voter storage self, uint _proposalId, address _voterAddress, bool _hasVoted, uint _voteNum) internal returns(bool){
                                self.proposalId = _proposalId;
                                self.voterAddress = _voterAddress;
                                self.hasVoted = _hasVoted;
                                self.voteNum = _voteNum;
                                return true;
}


    

}
