// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ERC20 Token Interface for Reward System
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract MentorshipProgram {
    address public owner;
    IERC20 public rewardToken; // Token for rewarding users
    
    // Struct for storing mentorship details
    struct Mentorship {
        address mentor;
        address mentee;
        uint256 startTime;
        uint256 progress;
        uint256 reward;
    }
    
    // Mapping to store active mentorships
    mapping(uint256 => Mentorship) public mentorships;
    mapping(address => uint256[]) public menteeMentorships; // Keeps track of mentorships per mentee
    
    // Mapping to store mentor and mentee ratings
    mapping(address => uint256) public mentorRatings;
    mapping(address => uint256) public menteeRatings;
    
    // Event declarations
    event MentorshipCreated(address indexed mentor, address indexed mentee, uint256 mentorshipId);
    event ProgressUpdated(address indexed mentee, uint256 mentorshipId, uint256 progress);
    event RewardClaimed(address indexed user, uint256 mentorshipId, uint256 rewardAmount);
    
    // Modifier to restrict access to the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    // Constructor to initialize the contract
    constructor(address _rewardToken) {
        owner = msg.sender;
        rewardToken = IERC20(_rewardToken);
    }

    // Function to start a mentorship program
    function startMentorship(address _mentor, address _mentee) public returns (uint256 mentorshipId) {
        mentorshipId = uint256(keccak256(abi.encodePacked(_mentor, _mentee, block.timestamp)));
        mentorships[mentorshipId] = Mentorship({
            mentor: _mentor,
            mentee: _mentee,
            startTime: block.timestamp,
            progress: 0,
            reward: 0
        });
        menteeMentorships[_mentee].push(mentorshipId);

        emit MentorshipCreated(_mentor, _mentee, mentorshipId);
        return mentorshipId;
    }

    // Function to update mentorship progress
    function updateProgress(uint256 mentorshipId, uint256 _progress) public {
        Mentorship storage mentorship = mentorships[mentorshipId];
        require(msg.sender == mentorship.mentee, "Only mentee can update progress");

        mentorship.progress = _progress;

        // Calculate rewards based on progress (e.g., 1 token per 10% progress)
        uint256 rewardAmount = (_progress / 10) * 1 ether;  // Rewarding 1 token for every 10% progress
        mentorship.reward = rewardAmount;

        emit ProgressUpdated(msg.sender, mentorshipId, _progress);
    }

    // Function for mentors and mentees to claim their rewards
    function claimReward(uint256 mentorshipId) public {
        Mentorship storage mentorship = mentorships[mentorshipId];
        require(msg.sender == mentorship.mentor || msg.sender == mentorship.mentee, "Only mentor or mentee can claim reward");
        require(mentorship.reward > 0, "No reward available");

        uint256 rewardAmount = mentorship.reward;
        mentorship.reward = 0;

        require(rewardToken.transfer(msg.sender, rewardAmount), "Reward transfer failed");

        emit RewardClaimed(msg.sender, mentorshipId, rewardAmount);
    }

    // Function to rate mentor
    function rateMentor(address _mentor, uint256 rating) public {
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");
        mentorRatings[_mentor] = (mentorRatings[_mentor] + rating) / 2;
    }

    // Function to rate mentee
    function rateMentee(address _mentee, uint256 rating) public {
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");
        menteeRatings[_mentee] = (menteeRatings[_mentee] + rating) / 2;
    }

    // Function for the owner to change the reward token
    function changeRewardToken(address newRewardToken) public onlyOwner {
        rewardToken = IERC20(newRewardToken);
    }

    // Function to withdraw any remaining tokens by the owner
    function withdrawTokens(uint256 amount) public onlyOwner {
        require(rewardToken.transfer(owner, amount), "Withdrawal failed");
    }
}
