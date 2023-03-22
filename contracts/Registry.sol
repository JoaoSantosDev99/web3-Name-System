// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4;

import "./Registrar.sol";

contract Registry {

    struct Data {
        address owner;
        string name;
        uint256 age;
        bool isMarried;
    }

    struct Pointer {
        address owner;
        address registrar;
    }

    mapping(string => Pointer) public registry;
    // mapping(address => bool) public registered;

    function newDomain(string memory _domain, string memory _name, uint256 _age, bool _isMarried) public {
        // require(!registered[msg.sender], "This addres is already registered");
        require(checkAvailable(_domain), "This domain is not available");

        Registrar newRegistrar = new Registrar(msg.sender, _name, _age, _isMarried);
        registry[_domain] = Pointer({owner: msg.sender, registrar: address(newRegistrar)});
    }

    function resolveName(string memory _domain) public view returns(address _owner, string memory _name, uint256 _age, bool _isMarried, address _registrar) {
        address owner = registry[_domain].owner;
        address registrarAddr = registry[_domain].registrar;

        Registrar registrar = Registrar(registrarAddr);
        Registrar.Data memory userData = registrar.getOwnerData();

        return(owner, userData.name, userData.age, userData.isMarried, registrarAddr);
    }

    function checkAvailable(string memory _domain) public view returns(bool available) {
        return registry[_domain].owner == 0x0000000000000000000000000000000000000000;
    }
}