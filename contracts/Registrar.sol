// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Registrar is Ownable {

    struct Data {
        address owner;
        string name;
        uint256 age;
        bool isMarried;
    }

    Data public ownerInfo;

    mapping(string => Data) public subDomainData;
    // mapping(address => bool) public registered;

    modifier onlySubDomainOwner (string memory _domain, address _caller) {
        require(subDomainData[_domain].owner == _caller, "You are not the owner of this sub-domain");
        _;
    }

    constructor(address _domainOwner, string memory _name, uint256 _age, bool _isMarried) {
        ownerInfo = Data({owner: msg.sender, name: _name, age: _age, isMarried: _isMarried});
        _transferOwnership(_domainOwner);
    }

    function setNewSubdomain(string memory _name) public onlyOwner {
        subDomainData[_name] = Data({owner: owner(), name: "_", age: 0, isMarried: false});
    }

    function transferSubDomain(string memory _subDomain, address _newOwner) public onlySubDomainOwner(_subDomain, msg.sender) {
        subDomainData[_subDomain].owner = _newOwner;
    }

    // needs a backwards resolver
    function changeSubDomainData(string memory _subDomain, string memory _name, uint256 _age, bool _isMarried) public onlySubDomainOwner(_subDomain, msg.sender) {
        subDomainData[_subDomain].name = _name;
        subDomainData[_subDomain].age = _age;
        subDomainData[_subDomain].isMarried = _isMarried;
    }

    function getOwnerData() public view returns(Data memory) {
        return ownerInfo;
    }
}