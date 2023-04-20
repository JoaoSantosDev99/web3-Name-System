// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Registrar is Ownable {

    struct Data {
        address owner;
        string description;
        string website;
        string email;
        string avatar;
    }

    bytes32 public parentDomain;
    address public registryContractAddr;

    Data public ownerInfo;

    mapping(bytes32 => Data) public subDomainData;
    mapping(address => bool) public hasSubDomain;
    mapping(bytes32 => bool) public registered;
    mapping(bytes32 => bool) public isDomainActive;
    bytes32[] public subDomainsList;


    modifier onlySubDomainOwner (bytes32 _domain) {
        require(subDomainData[_domain].owner == msg.sender, "You are not the owner of this sub-domain");
        _;
    }

    constructor(bytes32 _domain, address _domainOwner) {
        parentDomain = _domain;
        registryContractAddr = msg.sender;
        _transferOwnership(_domainOwner);
        ownerInfo.owner = _domainOwner;
    }

    function transfer(address _newOwner) public {
        require(msg.sender == registryContractAddr, "Caller is not Registry");
        _transferOwnership(_newOwner);
    }

    // Gets all the subdomains in use
    function getAllSubDomains() public view returns(bytes32[] memory) {
        bytes32[] memory allDomains = new bytes32[](subDomainsList.length);
        uint256 localCounter;

        for(uint256 i; i < subDomainsList.length; i++) {

            if(isDomainActive[subDomainsList[i]]) {
                allDomains[localCounter] = subDomainsList[i];
                allDomains[localCounter] = subDomainsList[i];
                localCounter ++;
            }
        }

        return allDomains;
    }

    function addToSubDomainsList(bytes32 _subDomain) internal {
        if(!registered[_subDomain]) {

            registered[_subDomain] = true;
            isDomainActive[_subDomain] = true;
            subDomainsList.push(_subDomain);
        }
    }

    // owner issues a new domain
    function setNewSubdomain(bytes32 _subDomain, address _target) public onlyOwner {
        require(!registered[_subDomain], "This subdomain already exists!");
        require(validateName(_subDomain), "This is not a valid domain name!");

        addToSubDomainsList(_subDomain);
        transferSubDomain(_subDomain, _target);
    }

    // transfering a subdomain; sending to owner will reset all the info.
    function transferSubDomain(bytes32 _subDomain, address _newOwner) public onlySubDomainOwner(_subDomain) {
        require(_newOwner != msg.sender, "Can't send domain to yourself!");

        if (_newOwner == owner()) {
            hasSubDomain[msg.sender] = false;
            isDomainActive[_subDomain] = false;
        } else {
            require(!hasSubDomain[_newOwner], "This address already have a subdomain!");
            hasSubDomain[_newOwner] = true;
            hasSubDomain[msg.sender] = false;
        }

        if (msg.sender == owner() && !isDomainActive[_subDomain]) {
            isDomainActive[_subDomain] = true;
            hasSubDomain[_newOwner] = true;
        }

        subDomainData[_subDomain].owner = _newOwner;
        subDomainData[_subDomain].description = "";
        subDomainData[_subDomain].website = "";
        subDomainData[_subDomain].email = "";
        subDomainData[_subDomain].avatar = "";
    }

    // owner changes its own data
    function setOwnerData(string memory _description, string memory _website, string memory _email, string memory _avatar) public onlyOwner {        
        setOwnerDescription(_description);
        setOwnerWebsite(_website);
        setOwnerEmail(_email);
        setOwnerAvatar(_avatar);     
    }

    function setOwnerDescription(string memory _description) public onlyOwner {
        ownerInfo.description =  _description;
    }

    function setOwnerWebsite(string memory _website) public onlyOwner {
        ownerInfo.website =  _website;
    }

    function setOwnerEmail(string memory _email) public onlyOwner {
        ownerInfo.email =  _email;
    }

    function setOwnerAvatar(string memory _avatar) public onlyOwner {
        ownerInfo.avatar =  _avatar;
    }

    //  maybe a backwards resolver?
    function changeSubDomainData(bytes32 _subDomain, string memory _description, string memory _website, string memory _email, string memory _avatar) public onlySubDomainOwner(_subDomain) {
        changeSubdomainDescription(_subDomain, _description);
        changeSubdomainWebsite(_subDomain, _website);
        changeSubdomainEmail(_subDomain, _email);
        changeSubdomainAvatar(_subDomain, _avatar);      
    }

    function changeSubdomainDescription(bytes32 _subDomain, string memory _description) public onlySubDomainOwner(_subDomain) {
        subDomainData[_subDomain].description = _description;
    }

    function changeSubdomainWebsite(bytes32 _subDomain, string memory _website) public onlySubDomainOwner(_subDomain) {
        subDomainData[_subDomain].website = _website;
    }

    function changeSubdomainEmail(bytes32 _subDomain, string memory _email) public onlySubDomainOwner(_subDomain) {
        subDomainData[_subDomain].email = _email;
    }

    function changeSubdomainAvatar(bytes32 _subDomain, string memory _avatar) public onlySubDomainOwner(_subDomain) {
        subDomainData[_subDomain].avatar = _avatar;
    }

    // resets all info and tranfers to zero address
    function deleteSubDomain(bytes32 _subDomain) public onlySubDomainOwner(_subDomain) {
        transferSubDomain(_subDomain, owner());
    }

    function validateName(bytes32 _name) internal pure returns (bool) {        
        if (_name == "") return false;

        for (uint i; i < 32; i++) {
            bytes1 char = _name[i];

            if (char == 0x20) return false;

            if (
                !(
                (char >= 0x30 && char <= 0x39) ||
                (char >= 0x61 && char <= 0x7A) || 
                (char == 0x00)
                )                    
            ) return false;
        }
        return true;
    }

}
