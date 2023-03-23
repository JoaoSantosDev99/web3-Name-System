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
    // mapping(address => bool) public registered;

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

    function getSubDomainsCounter() public view returns (uint256) {
        return subDomainsList.length;
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
        subDomainData[_subDomain] = Data({owner: owner(), description: "_", website: "_", email: "_", avatar:"_"});
        addToSubDomainsList(_subDomain);
    }

    // transfering a subdomain; sending to owner will reset all the info.
    function transferSubDomain(string memory _subDomain, address _newOwner) public onlySubDomainOwner(_subDomain) {

        if (_newOwner == owner()) {
            isDomainActive[_subDomain] = false;
        }

        if (msg.sender == owner() && !isDomainActive[_subDomain]) {
            isDomainActive[_subDomain] = true;
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

    function getOwnerData() public view returns(Data memory) {
        return ownerInfo;
    }

}

// jay.inu

// test.jay.inu 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
// sub.jay.inu  0x617F2E2fD72FD9D5503197092aC168c91465E7f2
// jessica.jay.inu  owner