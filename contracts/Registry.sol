// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4;

import "./Registrar.sol";

contract Registry {

    struct Data {
        address owner;
        string description;
        string website;
        string email;
        string avatar;
    }

    struct Pointer {
        address owner;
        address registrar;
    }

    string constant public TLD = "inu";

    mapping(string => Pointer) public registry;
    // mapping(address => string) public primaryDomain;
    // mapping(address => string[]) public domainsOwned;
    mapping(uint256 => string) public tokenToDomain;

    function newDomain(string memory _domain) public {
        require(checkAvailable(_domain), "This domain is not available");

        Registrar newRegistrar = new Registrar(_domain, msg.sender, TLD);
        registry[_domain] = Pointer({owner: msg.sender, registrar: address(newRegistrar)});
    }

    function resolveName(string memory _domain) public view returns(address _owner, string memory _description, string memory _website, string memory _email, string memory _avatar) {
        address owner = registry[_domain].owner;
        address registrarAddr = registry[_domain].registrar;

        Registrar registrar = Registrar(registrarAddr);
        Registrar.Data memory userData = registrar.getOwnerData();

        return(owner, userData.description, userData.website, userData.email, userData.avatar);
    }

    function checkAvailable(string memory _domain) public view returns(bool available) {
        return registry[_domain].owner == 0x0000000000000000000000000000000000000000;
    }
}