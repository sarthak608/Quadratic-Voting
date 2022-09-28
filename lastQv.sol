// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Voting is Ownable, AccessControl {
    using SafeMath for uint256;
    uint256 private _totalSupply;
    string public symbol;
    string public name;
    mapping(address => uint256) private _balances;
    uint256 public ProposalCount;

    event VoteCasted(address voter, uint256 ProposalID, uint256[] _tokens);

    event ProposalCreated(
        address creator,
        string description,
        string[] _options,
        uint256 votingTimeInHours
    );

    struct Proposal {
        address creator;
        ProposalStatus status;
        string description;
        address[] voters;
        uint256 expirationTime;
        uint256 numOfOptions;
        mapping(address => Voter) voterInfo;
        mapping(uint256 => option) options;
    }
    enum ProposalStatus {
        IN_PROGRESS,
        TALLY,
        ENDED
    }
    struct Voter {
        bool hasVoted;
        uint256[] _tokens;
    }

    struct option {
        string optionName;
        uint256 totalWeight;
    }
    mapping(uint256 => Proposal) public Proposals;

    address private Owner;

    constructor() public {
        symbol = "V";
        name = "Voting";
        Owner = msg.sender;
    }

    function checkAdmin() public view returns (bool) {
        if (msg.sender == Owner) {
            return true;
        }
        return false;
    }

    function createProposal(
        string calldata _description,
        string[] calldata _options,
        uint256 _voteExpirationTime
    ) external onlyOwner returns (uint256) {
        require(_voteExpirationTime > 0, "The voting period cannot be 0");
        ProposalCount++;
        Proposal storage curProposal = Proposals[ProposalCount];
        curProposal.creator = msg.sender;
        curProposal.status = ProposalStatus.IN_PROGRESS;
        curProposal.expirationTime =
            block.timestamp +
            60 *
            _voteExpirationTime *
            1 seconds;
        curProposal.description = _description;
        curProposal.numOfOptions = _options.length;
        for (uint256 i = 0; i < _options.length; i++) {
            curProposal.options[i + 1] = option({
                optionName: _options[i],
                totalWeight: 0
            });
        }

        emit ProposalCreated(
            msg.sender,
            _description,
            _options,
            _voteExpirationTime
        );
        return ProposalCount;
    }

    function getProposalCount() public view returns (uint256) {
        return ProposalCount;
    }

    function setProposalToTally(uint256 _ProposalID)
        external
        validProposal(_ProposalID)
        onlyOwner
    {
        require(
            Proposals[_ProposalID].status == ProposalStatus.IN_PROGRESS,
            "Vote is not in progress"
        );
        require(
            block.timestamp >= getProposalExpirationTime(_ProposalID),
            "voting period has not expired"
        );
        Proposals[_ProposalID].status = ProposalStatus.TALLY;
    }

    function getDetails(uint256 _ProposalID)
        external
        view
        returns (
            string memory,
            string[] memory,
            uint256,
            ProposalStatus
        )
    {
        string[] memory _options = new string[](
            Proposals[_ProposalID].numOfOptions
        );
        for (uint256 i = 1; i <= Proposals[_ProposalID].numOfOptions; i++) {
            _options[i - 1] = Proposals[_ProposalID].options[i].optionName;
        }
        return (
            Proposals[_ProposalID].description,
            _options,
            Proposals[_ProposalID].expirationTime,
            Proposals[_ProposalID].status
        );
    }

    function setProposalToEnded(uint256 _ProposalID)
        external
        validProposal(_ProposalID)
        onlyOwner
    {
        require(
            Proposals[_ProposalID].status == ProposalStatus.TALLY,
            "Proposal should be in tally"
        );
        require(
            block.timestamp >= getProposalExpirationTime(_ProposalID),
            "voting period has not expired"
        );
        Proposals[_ProposalID].status = ProposalStatus.ENDED;
    }

    function getProposalStatus(uint256 _ProposalID)
        public
        view
        validProposal(_ProposalID)
        returns (ProposalStatus)
    {
        return Proposals[_ProposalID].status;
    }

    function getProposalExpirationTime(uint256 _ProposalID)
        public
        view
        validProposal(_ProposalID)
        returns (uint256)
    {
        return Proposals[_ProposalID].expirationTime;
    }

    modifier validProposal(uint256 _ProposalID) {
        require(
            _ProposalID > 0 && _ProposalID <= ProposalCount,
            "Not a valid Proposal Id"
        );
        _;
    }

    function userHasVoted(uint256 _ProposalID, address _user)
        public
        view
        validProposal(_ProposalID)
        returns (bool)
    {
        return (Proposals[_ProposalID].voterInfo[_user].hasVoted);
    }

    /**
     * @dev to get winner of poll.
     * @param _ProposalID the proposal id
     * returns index of options, total weight of option and name of option
     */

    function countVotes(uint256 _ProposalID)
        public
        view
        returns (
            uint256,
            uint256,
            string memory
        )
    {
        uint256 len = Proposals[_ProposalID].numOfOptions;
        uint256 maxWeight;
        uint256 index;
        for (uint256 i = 1; i <= len; i++) {
            if (Proposals[_ProposalID].options[i].totalWeight >= maxWeight) {
                maxWeight = Proposals[_ProposalID].options[i].totalWeight;
                index = i;
            }
        }
        string memory n = Proposals[_ProposalID].options[index].optionName;
        return (index, maxWeight, n);
    }

    function getWeight(uint256 _ProposalID, uint256 optionNum)
        public
        view
        returns (uint256)
    {
        return Proposals[_ProposalID].options[optionNum].totalWeight;
    }

    function castVote(uint256 _ProposalID, uint256[] memory _tokens)
        external
        validProposal(_ProposalID)
    {
        require(
            getProposalStatus(_ProposalID) == ProposalStatus.IN_PROGRESS,
            "proposal has expired."
        );
        require(
            !userHasVoted(_ProposalID, msg.sender),
            "user already voted on this proposal"
        );
        require(
            getProposalExpirationTime(_ProposalID) > block.timestamp,
            "for this proposal, the voting time expired"
        );
        Proposal storage curproposal = Proposals[_ProposalID];
        uint256 total = 0;
        for (uint256 i = 1; i <= _tokens.length; i++) {
            curproposal.options[i].totalWeight += _tokens[i - 1];
            total = total + (_tokens[i - 1] * _tokens[i - 1]);
        }

        _balances[msg.sender] = _balances[msg.sender].sub(total);

        curproposal.voterInfo[msg.sender] = Voter({
            hasVoted: true,
            _tokens: _tokens
        });

        curproposal.voters.push(msg.sender);

        emit VoteCasted(msg.sender, _ProposalID, _tokens);
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /**
     * @dev minting more tokens for an account
     */
    function mint(address account, uint256 amount) public onlyOwner {
        require(account != address(0), " mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
    }

    /**
     * @dev returns the balance of an account
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
}
