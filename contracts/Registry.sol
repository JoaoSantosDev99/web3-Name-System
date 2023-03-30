// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4;

import "./Registrar.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Registry is ERC721, ERC721Enumerable, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

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
    mapping(address => string) public primaryDomain;
    mapping(uint256 => string) public tokenToDomain;


    constructor() ERC721("Registry", "INU") {}

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        address registrarAddr = registry[tokenToDomain[tokenId]].registrar;
        Registrar(registrarAddr).transfer(to);
        registry[tokenToDomain[tokenId]].owner = to;
        super._beforeTokenTransfer(from, to, tokenId, batchSize);


        if (balanceOf(to) == 0) {
            primaryDomain[to] = tokenToDomain[tokenId];

            if ( keccak256(abi.encodePacked(primaryDomain[from])) == keccak256(abi.encodePacked(tokenToDomain[tokenId]))) {
                primaryDomain[from] = "";
            }
        }

        if (keccak256(abi.encodePacked(primaryDomain[from])) == keccak256(abi.encodePacked(tokenToDomain[tokenId])) ) {
            primaryDomain[from] = "";
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function newDomain(string memory _domain) public {
        require(checkAvailable(_domain), "This domain is not available");
        require(validateName(_domain), "This is not a valid domain name!");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        tokenToDomain[tokenId] = _domain;

        Registrar newRegistrar = new Registrar(_domain, msg.sender);
        registry[_domain] = Pointer({owner: msg.sender, registrar: address(newRegistrar)});

        _safeMint(msg.sender, tokenId);

    }
    function setPrimaryDomain(string memory _domain) public {
        require(registry[_domain].owner == msg.sender, "You are not the onwer of this domain!");
        require(keccak256(abi.encodePacked(primaryDomain[msg.sender])) != keccak256(abi.encodePacked(_domain)), "This is already your primary domain!");
        primaryDomain[msg.sender] = _domain;
    }

    function checkAvailable(string memory _domain) public view returns(bool available) {
        return registry[_domain].owner == address(0);
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