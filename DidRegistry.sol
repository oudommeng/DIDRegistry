// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DIDRegistry {
    struct DID {
        string identifier;
        address owner;
    }

    struct Metadata {
        string name;
        string email;
        string profilePicture;
    }

    struct RoleCredential {
        string role;
        address issuer;
        uint256 issuedAt;
    }

    mapping(address => DID) private dids;
    mapping(address => Metadata) private metadata;
    mapping(address => string) private roles;
    mapping(address => RoleCredential[]) private roleHistory;

    address private admin;

    event DIDCreated(address indexed owner, string identifier);
    event DIDUpdated(address indexed owner, string oldIdentifier, string newIdentifier);
    event MetadataSet(address indexed user, string name, string email, string profilePicture);
    event RoleAssigned(address indexed user, string role);
    event RoleCredentialIssued(address indexed user, string role, address indexed issuer);

    constructor() {
        admin = msg.sender; // Contract deployer becomes the initial admin
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    // Function to create a DID
    function createDID(string memory _identifier) public {
        require(bytes(_identifier).length > 0, "Identifier cannot be empty");
        require(dids[msg.sender].owner == address(0), "DID already exists for this address");
        dids[msg.sender] = DID(_identifier, msg.sender);

        emit DIDCreated(msg.sender, _identifier);
    }

    // Function to get the DID
    function getDID() public view returns (string memory) {
        require(dids[msg.sender].owner != address(0), "No DID found for this address");
        return dids[msg.sender].identifier;
    }

    // Function to update the DID
    function updateDID(string memory _newIdentifier) public {
        require(bytes(_newIdentifier).length > 0, "New identifier cannot be empty");
        require(dids[msg.sender].owner != address(0), "No DID found for this address");

        string memory oldDID = getDID();
        require(
            keccak256(bytes(oldDID)) != keccak256(bytes(_newIdentifier)),
            "New identifier must not be the same as the current one"
        );

        dids[msg.sender].identifier = _newIdentifier;

        emit DIDUpdated(msg.sender, oldDID, _newIdentifier);
    }

    // Function to assign a role to a user
    function assignRole(address _user, string memory _role) public onlyAdmin {
        require(bytes(_role).length > 0, "Role cannot be empty");
        roles[_user] = _role;

        // Track role assignment history
        roleHistory[_user].push(RoleCredential({
            role: _role,
            issuer: msg.sender,
            issuedAt: block.timestamp
        }));

        emit RoleAssigned(_user, _role);
    }

    // Function to get the role of a user
    function getRole(address _user) public view returns (string memory) {
        require(bytes(roles[_user]).length > 0, "No role assigned to this user");
        return roles[_user];
    }

    // Function to set user metadata
    function setMetadata(string memory _name, string memory _email, string memory _profilePicture) public {
        require(dids[msg.sender].owner != address(0), "Create a DID before setting metadata");
        metadata[msg.sender] = Metadata(_name, _email, _profilePicture);

        emit MetadataSet(msg.sender, _name, _email, _profilePicture);
    }

    // Function to get user metadata
    function getMetadata(address _user) public view returns (Metadata memory) {
        require(dids[_user].owner != address(0), "No metadata found for this user");
        return metadata[_user];
    }


    // Function to verify role credentials
    function verifyRoleCredential(address _user, string memory _role) public view returns (bool) {
        RoleCredential[] memory history = roleHistory[_user];
        for (uint256 i = 0; i < history.length; i++) {
            if (
                keccak256(bytes(history[i].role)) == keccak256(bytes(_role)) &&
                history[i].issuer != address(0)
            ) {
                return true;
            }
        }
        return false;
    }
}