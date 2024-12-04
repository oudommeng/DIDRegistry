// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DIDRegistry{
    // Contract will store and manage DIDs
    struct DID{
        string identifier;
        address owner;
    }
    
    // Link each Ethereum address to a DID struct
    // private: Ensure that the data cannot be directly accessed out.
    mapping (address => DID) private dids;

    // Event to log the creation and update of a DID
    event DIDCreated(address indexed owner, string identifier);

    // Function to create a DID
    function createDID(string memory _identifier) public {
        require(bytes(_identifier).length > 0, "Identifier cannot be empty");
        require(dids[msg.sender].owner == address(0), "DID already exists for this address");

        dids[msg.sender] = DID(_identifier, msg.sender);
        emit DIDCreated(msg.sender, _identifier);
    }

    // Function to get the DID of the caller
    function getDID() public view returns (string memory) {
        require(dids[msg.sender].owner != address(0), "No DID found for this address");
        return dids[msg.sender].identifier;
    }

    // Function to update the DID
    function updateDID(string memory _newIdentifier, string memory _identifier) public {
        // Ensure the new identifier is not empty
        require(bytes(_newIdentifier).length > 0, "New identifier cannot be empty");
        // Ensure the address already has an existing DID
        require(dids[msg.sender].owner != address(0), "No DID found for this address");
        // Replace the DID identifier with the new identifier
        require(keccak256(bytes(_newIdentifier)) == keccak256(bytes(_identifier)), "New identifier cannot be equal to the old one");
        dids[msg.sender].identifier = _newIdentifier;
        // Emit event to log the update
        emit DIDCreated(msg.sender, _newIdentifier);
    }
}
