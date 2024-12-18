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
    }
    struct credential
    {
        address issuer;
        string role;
        uint256 issueAt;

        bytes32 hashes;
    }
    

    mapping(address => DID) private dids;
    mapping(address => string) private roles;
    mapping(address => string[]) private roleHistory;
    mapping(address => MetaData) private metadatas;
    mapping (address => credential[]) private credentials;

    constructor()
    {
        roles[msg.sender] = "super admin";
        roleHistory[msg.sender].push("super admin");
    }

    event DIDCreated(address indexed owner, string identifier);
    event SetMetaData(address indexed owner, string name,string email,string profilePicture);
    event RoleAssign(address indexed user, string role);
    event RoleIssued(address indexed user, address receiver, string role, bytes32 hash);

    function assignRole(address _user, string memory _role) public 
    {
        require(dids[msg.sender].owner != address(0) ,"Issuer must have a DID");
        require(bytes(_role).length > 0 , "Role cannot be empty");
        roles[_user] = _role;
        //test if the user have permission to assign role
        roleHistory[_user].push(_role);
        emit RoleAssign(_user, _role);

    }
    function issueRole(address _user, string memory _role ) public 
    {
        require(dids[msg.sender].owner != address(0), "Issuer must have a DID");
        require(bytes(_role).length > 0, "Role cannot be empty");

        bytes32 roleHash = keccak256(abi.encodePacked(msg.sender, _user, _role, block.timestamp));

        credentials[_user].push(
            credential(msg.sender, _role, block.timestamp, roleHash)
        );

        roleHistory[_user].push(_role);

        emit RoleIssued(msg.sender, _user, _role, roleHash);
    }

    //verify role
    // function isRoleAssigned(string memory _role) public view returns (bool){
    //     require(bytes(_role).length > 0 , "Role cannot be empty");
        
    //     string[] memory userRoles = roleHistory[msg.sender]; 
    //         for(uint i = 1;i <userRoles.length ; ++i ){
    //             if (keccak256(abi.encodePacked(_role, msg.sender)) == keccak256(abi.encodePacked(userRoles[i]))) return true; 
    //         }
    //      return false;
    // }
    
    function verifyRole(address _user, string memory _role) public view returns (bool) {
        require(bytes(_role).length > 0, "Role cannot be empty");
        
        string[] memory userRoles = roleHistory[_user];
        for (uint256 i = 0; i < userRoles.length; i++) {
            if (keccak256(abi.encodePacked(userRoles[i])) == keccak256(abi.encodePacked(_role))) {
                return true;
            }
        }
        return false;
    }
    function createDID(string memory _identifier) public {
        require(bytes(_identifier).length > 0, "Identifier cannot be empty");
        require(dids[msg.sender].owner == address(0), "DID already exists");
        dids[msg.sender] = DID(_identifier, msg.sender, block.timestamp);
        emit DIDCreated(msg.sender, _identifier);
    }

    function getDID() public view returns (string memory) {
        require(dids[msg.sender].owner != address(0), "No DID found for this address");

        return dids[msg.sender].identifier;
    }

    function setMetadata(string memory name, string memory email, string memory profilePicture)public{
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(email).length > 0, "Email cannot be empty");
        require(bytes(profilePicture).length > 0, "Profile picture cannot be empty");
        require(dids[msg.sender].owner != address(0), "No DID found for this address");
        metadatas[msg.sender] = MetaData(name, email, profilePicture);

        emit SetMetaData(msg.sender, name, email, profilePicture);
    }

    function getMetadata() public view returns (MetaData memory){
        require(dids[msg.sender].owner != address(0), "Data does not exist");
        return metadatas[msg.sender];
    }

    // function getRole() public view returns (string[] memory) {
    //     require(dids[msg.sender].owner != address(0), "No DID found for this address");
            //get userdid to find in array.
            //if you got 0, it mean u dont have role yet
            //if you didn't get 0, return that array.

    //     return roles[msg.sender];
    // }

}