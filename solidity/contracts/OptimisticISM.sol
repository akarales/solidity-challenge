//license identifier
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // Specifies the Solidity version

// Define the ISM interface
// This is used to interact with other contracts that implement this interface
interface ISM {
    // The verify function signature that other contracts should implement
    function verify(
        bytes calldata message,
        bytes calldata metadata
    ) external returns (bool);
}

// Define the OptimisticISM contract
contract OptimisticISM {
    // Define the submodule variable to hold the ISM contract
    ISM public submodule;

    // Define the fraud window variable
    uint public fraudWindow;

    // Define the owner of the contract
    address public owner;

    // Define mappings to store the watchers and their votes
    mapping(address => bool) public watchers;
    mapping(address => uint) public watcherVotes;

    // Define a mapping to store the compromised submodules
    mapping(ISM => bool) public compromisedSubmodules;

    // Define mappings to store the pre-verified messages and their timestamps
    mapping(bytes => bool) public preVerifiedMessages;
    mapping(bytes => uint) public preVerificationTimestamps;

    // Define the constructor which is called once when the contract is deployed
    constructor(ISM _submodule, uint _fraudWindow) {
        submodule = _submodule;
        fraudWindow = _fraudWindow;
        owner = msg.sender; // Set the contract deployer as the owner
    }

    // Define the preVerify function
    // This function verifies the message using the submodule and stores the verification status
    function preVerify(
        bytes calldata message,
        bytes calldata metadata
    ) external {
        require(
            submodule.verify(message, metadata),
            "Submodule verification failed"
        );
        bytes32 messageHash = keccak256(message); // Hash of the message
        preVerifiedMessages[messageHash] = true;
        preVerificationTimestamps[messageHash] = block.timestamp; // Store the current timestamp
    }

    // Define the function to flag compromised submodules
    // Only watchers can call this function
    function flagCompromisedSubmodule(ISM _submodule) external {
        require(watchers[msg.sender], "Caller is not a watcher");
        compromisedSubmodules[_submodule] = true; // Mark the submodule as compromised
    }

    // Define the verify function
    // This function checks whether a pre-verified message is valid and the submodule is not compromised
    function verify(
        bytes calldata message,
        bytes calldata metadata
    ) external returns (bool) {
        bytes32 messageHash = keccak256(message); // Hash of the message
        require(
            preVerifiedMessages[messageHash],
            "Message has not been pre-verified"
        );
        require(
            !compromisedSubmodules[submodule],
            "Submodule has been compromised"
        );
        require(
            block.timestamp >=
                preVerificationTimestamps[messageHash] + fraudWindow,
            "Fraud window has not elapsed"
        );
        return true; // Return true if the checks pass
    }
}
