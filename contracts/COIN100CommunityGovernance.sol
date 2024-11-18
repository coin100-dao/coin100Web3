// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract COIN100CommunityGovernance is Ownable {
    IERC20 public coin100;
    address public communityTreasury;

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    uint256 public requiredVotes;

    struct Proposal {
        address proposer;
        string description;
        uint256 voteCount;
        bool executed;
    }

    mapping(uint256 => mapping(address => bool)) public votes;

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(address indexed voter, uint256 indexed proposalId);
    event ProposalExecuted(uint256 indexed proposalId);

    constructor(address _coin100, address _communityTreasury, uint256 _requiredVotes) {
        require(_coin100 != address(0) && _communityTreasury != address(0), "Invalid address");
        coin100 = IERC20(_coin100);
        communityTreasury = _communityTreasury;
        requiredVotes = _requiredVotes;
    }

    function createProposal(string memory description) external returns (uint256) {
        proposalCount += 1;
        proposals[proposalCount] = Proposal({
            proposer: msg.sender,
            description: description,
            voteCount: 0,
            executed: false
        });
        emit ProposalCreated(proposalCount, msg.sender, description);
        return proposalCount;
    }

    function vote(uint256 proposalId) external {
        require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal ID");
        require(!votes[proposalId][msg.sender], "Already voted");
        votes[proposalId][msg.sender] = true;
        proposals[proposalId].voteCount += 1;
        emit VoteCast(msg.sender, proposalId);
    }

    function executeProposal(uint256 proposalId) external onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal ID");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.voteCount >= requiredVotes, "Not enough votes");

        // Implement the logic to utilize Community Treasury funds
        // Example: Transfer a certain amount to a specified address
        // coin100.transfer(someAddress, amount);

        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }

    function setRequiredVotes(uint256 _requiredVotes) external onlyOwner {
        requiredVotes = _requiredVotes;
    }
}
