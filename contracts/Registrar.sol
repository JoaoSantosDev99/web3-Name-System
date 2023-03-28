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

    string public parentDomain;
    address public registryContractAddr;

    Data public ownerInfo;

    mapping(string => Data) public subDomainData;
    mapping(address => bool) public hasSubDomain;
    mapping(string => bool) public registered;
    mapping(string => bool) public isDomainActive;
    string[] public subDomainsList;


    modifier onlySubDomainOwner (string memory _domain) {
        require(subDomainData[_domain].owner == msg.sender, "You are not the owner of this sub-domain");
        _;
    }

    constructor(string memory _domain, address _domainOwner) {
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
    function getAllSubDomains() public view returns(string[] memory) {
        string[] memory allDomains = new string[](subDomainsList.length);
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

    function addToSubDomainsList(string memory _subDomain) internal {
        if(!registered[_subDomain]) {

            registered[_subDomain] = true;
            isDomainActive[_subDomain] = true;
            subDomainsList.push(_subDomain);
        }
    }

    // owner issues a new domain
    function setNewSubdomain(string memory _subDomain) public onlyOwner {
        require(!registered[_subDomain], "This subdomain already exists!");
        require(validateName(_subDomain), "This is not a valid domain name!");

        subDomainData[_subDomain] = Data({owner: owner(), description: "_", website: "_", email: "_", avatar:"_"});
        addToSubDomainsList(_subDomain);
    }

    // transfering a subdomain; sending to owner will reset all the info.
    function transferSubDomain(string memory _subDomain, address _newOwner) public onlySubDomainOwner(_subDomain) {
        // require(hasSubDomain[msg.sender] = false)
        // owner cannot send to himself
        // cant send to somebody that already has a subdomain


        if (_newOwner == owner()) {
            hasSubDomain[msg.sender] = false;
            isDomainActive[_subDomain] = false;
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
        ownerInfo.description =  _description;
        ownerInfo.website =  _website;
        ownerInfo.email = _email;
        ownerInfo.avatar = _avatar;
    }

    //  maybe a backwards resolver?
    function changeSubDomainData(string memory _subDomain, string memory _description, string memory _website, string memory _email, string memory _avatar) public onlySubDomainOwner(_subDomain) {
        subDomainData[_subDomain].description =  _description;
        subDomainData[_subDomain].website =  _website;
        subDomainData[_subDomain].email = _email;
        subDomainData[_subDomain].avatar = _avatar;
    }

    // resets all info and tranfers to zero address
    function deleteSubDomain(string memory _subDomain) public onlySubDomainOwner(_subDomain) {
        transferSubDomain(_subDomain, owner());
    }

    function validateName(string memory str) internal pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length < 1) return false;
        if (b.length > 40) return false;
        if (b[0] == 0x20) return false;
        if (b[b.length - 1] == 0x20) return false;

        for (uint i; i < b.length; i++) {
            bytes1 char = b[i];

            if (char == 0x20) return false;

            if (
                !(char >= 0x30 && char <= 0x39) &&
                !(char >= 0x61 && char <= 0x7A) &&
                !(char == 0x2D)
            ) return false;
        }
        return true;
    }

}
