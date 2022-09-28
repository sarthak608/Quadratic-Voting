// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface proposalEvents{
    event VoteCasted(address voter, uint256 ProposalID, uint256[] _tokens);
// _voters,_creator,_startTime,_expirationTime,_disc,_cand
    event ProposalCreated(
        uint proposalId,
        address[] voters,
        address creator,
        uint256 startTime,
        uint256 expirationTime,
        string description,
        string[] _cand
    );
}