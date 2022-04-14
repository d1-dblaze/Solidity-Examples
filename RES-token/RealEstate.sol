pragma solidity ^0.8.12;

import "./helper_contracts/ERC721.sol";

/**
    This is a real estate token smart contract.
    A supervisor can adda a piece of real estate as an asset(token) and at the same time
    assign it to an owner.
    The owner of the token can add value to the token by building on it as well as approve
    sale to a buyer. An approved buyer can buy the asset.
    The real estate asset may also appreciate or depreciate as determined by a town's supervisor.
    
 */
//contract RES is inheriting from ERC721
contract RES is ERC721 {

    struct Asset {
        uint256 assetId;
        uint256 price;
    }

    uint256 public assetsCount;
    address public supervisor; // The one who deploys the contract.
    mapping(uint256 => Asset) assetMap;
    mapping (uint256 => address) private assetOwner; //map asset ids to owner's address.
    mapping (address => uint256) private ownedAssetsCount; //map address to number of unique assets owned.
     //mapping between assetId and addressess. Used internally for the process of transferring ownership
    mapping (uint256 => address) public assetApprovals;

    constructor() {
        supervisor = msg.sender;
    }

    //Events
    //According to the ERC721 protocol, we have to list this 2 events.
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    //-----------------------------------------------------------//
        //ERC721 Functions Needed
    //----------------------------------------------------------//
    function balanceOf() public view returns (uint256) {
        //if the address is not equal to the uninitialized address (address(0)), proceed, 
        //else return the custom error.
        require(msg.sender != address(0), "ERC721: balance query for the zero address");
        //return the number of asset owned by the address.
        return ownedAssetsCount[msg.sender];
    }

    //Function to return the owner(address) of an asset.
    function ownerOf(uint256 assetId) public view returns (address) {
        //check the assetOwner mapper to return the address of a particular asset
        address owner = assetOwner[assetId];
        //make sure the owner address is not an uninitialized address (address(0))
        require(owner != address(0), "No Asset Exists");
        return owner;
    }

    /*A function to transfer an asset (assetId) from an address(former owner) to 
    another address(new owner)*/
    function transferFrom(address payable _from, uint256 assetId) public payable {
        //require that the person invoking this function is approved to do so
        require(isApprovedOrOwner(msg.sender, assetId), "NotAnApprovedOwner");
        //check if the _from address is truly the owner of the asset to
        //prevent any fraudulent activity like an imposter approving an asset.
        require(ownerOf(assetId) == _from, "Not The Asset Owner");
        clearApproval(assetId, getApproved(assetId));
        //The former owner's asset count reduces by 1
        ownedAssetsCount[_from]--;
        //The new owner's asset count increases by 1
        ownedAssetsCount[msg.sender]++;
        //The asset new owner becomes the msg.sender address
        assetOwner[assetId] == msg.sender;
        //Transfers the asset price to the former owner (The price the asset was sold for)
        _from.transfer(assetMap[assetId].price);
        //Emit the transfer event.
        emit Transfer(_from, msg.sender, assetId);
    }

    //Approve an address for the transfer of ownership to the approved address
    function approve(address _to, uint256 assetId) public {
        //get the owner of the asset
        address owner = ownerOf(assetId);
        //require that the new owner should not be the current owner
        require(_to != owner, "Current owner Approval");
        //require that the address invoking this function is the owner of the asset
        require(msg.sender == owner, "Not Asset Owner");
        //update the mapper indicating this asset(assetId) has been approved 
        //to be transfered to the new address (_to)
        assetApprovals[assetId] == _to;
        //emit the approval event.
        emit Approval(owner, _to, assetId);
    }

    //Return the approved address for a particular asset 
    function getApproved(uint256 assetId) public view returns (address) {
        //check if the asset exists and have a valid owner (not a zero address)
        require(exists(assetId), "ERC721: approved query for nonexistence token");
        //return the address that was approved for an asset
        return assetApprovals[assetId];
    }

    //----------------------------------------------------------------------------//
                // Additional functions added to the  token //
   //----------------------------------------------------------------------------//

    function addAsset(uint256 price, address to) public {
        //Only the supervisor can add an asset.
        require(supervisor == msg.sender, "NOt a Manager");
        //create an asset and add to the asset mapper.
        assetMap[assetsCount] = Asset(assetsCount,price);
        //sort of assigning owner to the new asset (mint function)
        mint(to, assetsCount);
        assetsCount = assetsCount+1;
    }

    //Helper function for the transfer function.
    function clearApproval(uint256 assetId, address approved) public {
        //First check the address supplied(approved) has truly been approved. 
        //if it has, update the approval list and continue with the main function
        if (assetApprovals[assetId] == approved){
            assetApprovals[assetId] = address(0);
        }
    }

    //the owner of an asset should be able to build/increase-the-value-of his/her asset.
    function build(uint256 assetId, uint256 value) public payable {
        require(isApprovedOrOwner (msg.sender, assetId), "Not an Approved Owner");
        Asset memory oldAsset = assetMap[assetId];
        assetMap[assetId] = Asset(oldAsset.assetId, oldAsset.price+value);
    }

    /**
    Since it is a real estate property, the nft tends to appreciate or depreciate in value and 
    this appreciation/depreciation value is assigned after it has been assessed by a supervisor.
     */
    function appreciate (uint256 assetId, uint256 value) public {
        require(msg.sender == supervisor, "Not a Manager");
        Asset memory oldAsset = assetMap[assetId];
        assetMap[assetId] = Asset(oldAsset.assetId, oldAsset.price+value);
    }

    function depreciate (uint256 assetId, uint256 value) public {
        require(msg.sender == supervisor, "Not a Manager");
        Asset memory oldAsset = assetMap[assetId];
        assetMap[assetId] = Asset(oldAsset.assetId, oldAsset.price-value);
    }

    //Return the number of asset that has been issued or created.
    function getAssetSize() public view returns (uint) {
        return assetsCount;
    }

    function mint (address _to, uint256 assetId) internal {
        //require that who you are assigning the asset to isn't a zero address.
        require(_to != address(0), "Zero Address Minting");
        //require that the asset exist and has a valid address owner.
        require(!exists(assetId), "Already Minted");
        //update the assetOwner mapper
        assetOwner[assetId] = _to;
        //update the owned asset count.
        ownedAssetsCount[_to]++;
        //emit the transfer event
        emit Transfer(address(0), _to, assetId);
    }

    function exists(uint256 assetId) internal view returns (bool) {
        //return true if the asset has a valid address that is, 
        //the asset exist or has been minted.
        return assetOwner[assetId] != address(0);
    }

    function isApprovedOrOwner (address spender, uint256 assetId) internal view returns (bool){
        //make sure the asset exist.
        require(exists(assetId), "Query for nonexistence token");
        //get the owner of the asset.
        address owner = ownerOf(assetId);
        //return if the spender is the owner or 
        //check if the spender has been approved.
        return (spender == owner || getApproved(assetId) == spender);
    }

}