pragma solidity 0.4.8;
/**
    This is a smart contract that proves a file existence, integrity, and ownership
    Proof of ownership is achieved by storing the file hash and owner name as pairs.
    Proof of existence is achieved by storing the file hash and block stamp
    The hash of the file serves a proof of integrity.
 */
contract Proof{
    //Contains details about the file. More like metadata
    struct fileDetails{
        uint timestamp;
        address owner;
    }

    //a mapping between the file hash and the file details
    mapping (string => fileDetails) files;
    //an event to notify us if a file was added or not with helpful data
    event logFileAddedStatus (bool status, uint timestamp, address owner, string fileHash);

    //function to store the owner of a file , hash and block timestamp
    function set (address owner, string fileHash) public{
        //There is no proper way to check if a key already exists or not so we check for the default value
        if (files[fileHash].timestamp == 0){
            //add the file hash and its details.
            files[fileHash] = fileDetails(block.timestamp, owner);
            //log out that the file was added successfully
            logFileAddedStatus(true, block.timestamp, owner, fileHash);
        }else {
            //if the file already exist, log out that the file was not added.
            logFileAddedStatus(false, block.timestamp, owner, fileHash);
        }
    }
    //function to retrieve the details of a file.
    function get(string fileHash) public returns (uint timestamp, address owner) {
        return (files[fileHash].timestamp, files[fileHash].owner);
    }
}