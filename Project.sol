// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DIDRegistryWithRoles {
    struct DID {
        string identifier;
        address owner;
        uint256 createdAt;
    }

    struct MetaData {
        string name;
        string email;
        string profilePicture;
        uint256 totalTestsSubmitted; // Track total tests submitted
        uint256 lastTestScore; // Last test score
    }

    struct TestSubmission {
        string answersHash; // Hash of the submitted answers
        uint256 submissionTime; // Time of submission
        uint256 grade; // Grade awarded (0 if not graded yet)
        bool graded; // Whether the test has been graded
    }

    struct credential {
        address issuer;
        string role;
        uint256 issueAt;
        bytes32 hashes;
    }

    mapping(address => DID) private dids;
    mapping(address => string) private roles;
    mapping(address => string[]) private roleHistory;
    mapping(address => MetaData) private metadatas;
    mapping(address => credential[]) private credentials;
    mapping(address => TestSubmission[]) private testSubmissions;

    constructor() {
        roles[msg.sender] = "super admin";
        roleHistory[msg.sender].push("super admin");
    }

    event DIDCreated(address indexed owner, string identifier);
    event SetMetaData(
        address indexed owner,
        string name,
        string email,
        string profilePicture
    );
    event RoleAssign(address indexed user, string role);
    event RoleIssued(
        address indexed user,
        address receiver,
        string role,
        bytes32 hash
    );
    event TestSubmitted(
        address indexed user,
        string answersHash,
        uint256 submissionTime
    );
    event TestGraded(
        address indexed user,
        uint256 grade,
        uint256 gradedTime
    );

    function assignRole(address _user, string memory _role) public {
        require(dids[msg.sender].owner != address(0), "Issuer must have a DID");
        require(bytes(_role).length > 0, "Role cannot be empty");
        roles[_user] = _role;
        //test if the user have permission to assign role
        roleHistory[_user].push(_role);
        emit RoleAssign(_user, _role);
    }

    function issueRole(address _user, string memory _role) public {
        require(dids[msg.sender].owner != address(0), "Issuer must have a DID");
        require(bytes(_role).length > 0, "Role cannot be empty");

        bytes32 roleHash = keccak256(
            abi.encodePacked(msg.sender, _user, _role, block.timestamp)
        );

        credentials[_user].push(
            credential(msg.sender, _role, block.timestamp, roleHash)
        );

        roleHistory[_user].push(_role);

        emit RoleIssued(msg.sender, _user, _role, roleHash);
    }

    function createDID(string memory _identifier) public {
        require(bytes(_identifier).length > 0, "Identifier cannot be empty");
        require(dids[msg.sender].owner == address(0), "DID already exists");
        dids[msg.sender] = DID(_identifier, msg.sender, block.timestamp);
        emit DIDCreated(msg.sender, _identifier);
    }

    function getDID() public view returns (string memory) {
        require(
            dids[msg.sender].owner != address(0),
            "No DID found for this address"
        );

        return dids[msg.sender].identifier;
    }

    function setMetadata(
        string memory name,
        string memory email,
        string memory profilePicture
    ) public {
        require(
            dids[msg.sender].owner != address(0),
            "No DID found for this address"
        );
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(email).length > 0, "Email cannot be empty");
        require(
            bytes(profilePicture).length > 0,
            "Profile picture cannot be empty"
        );

        metadatas[msg.sender] = MetaData(name, email, profilePicture, 0, 0);

        emit SetMetaData(msg.sender, name, email, profilePicture);
    }

    function getMetadata() public view returns (MetaData memory) {
        require(dids[msg.sender].owner != address(0), "Data does not exist");
        return metadatas[msg.sender];
    }

    function getRole() public view returns (string[] memory) {
        // get userdid to find in array.
        // if you got 0, it mean u dont have role yet
        // if you didn't get 0, return that array.
        require(
            dids[msg.sender].owner != address(0),
            "No DID found for this address"
        );

        require(roleHistory[msg.sender].length > 0, "No roles assigned yet");
        return roleHistory[msg.sender];
    }

    // Allows users to submit test answers (stored as a hash).
    function submitTest(string memory answersHash) public {
        require(dids[msg.sender].owner != address(0), "No DID found for this address");
        require(bytes(answersHash).length > 0, "Answers hash cannot be empty");

        testSubmissions[msg.sender].push(
            TestSubmission(answersHash, block.timestamp, 0, false)
        );

        metadatas[msg.sender].totalTestsSubmitted += 1;

        emit TestSubmitted(msg.sender, answersHash, block.timestamp);
    }

    // Allows issuers to grade submitted tests.
    function gradeTest(
        address user,
        uint256 testIndex,
        uint256 grade
    ) public {
        require(dids[msg.sender].owner != address(0), "Issuer must have a DID");
        require(testIndex < testSubmissions[user].length, "Invalid test index");
        require(!testSubmissions[user][testIndex].graded, "Test already graded");

        testSubmissions[user][testIndex].grade = grade;
        testSubmissions[user][testIndex].graded = true;
        metadatas[user].lastTestScore = grade;

        emit TestGraded(user, grade, block.timestamp);
    }

    function getTestSubmissions() public view returns (TestSubmission[] memory) {
        require(dids[msg.sender].owner != address(0), "No DID found for this address");
        return testSubmissions[msg.sender];
    }
}