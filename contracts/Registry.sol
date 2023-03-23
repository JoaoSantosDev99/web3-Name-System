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
    // mapping(address => string) public primaryDomain;
    // mapping(address => string[]) public domainsOwned;
    mapping(uint256 => string) public tokenToDomain;


    constructor() ERC721("Registry", "INU") {}

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        address registrarAddr = registry[tokenToDomain[tokenId]].registrar;
        Registrar(registrarAddr).transfer(to);
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
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

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);

        tokenToDomain[tokenId] = _domain;

        Registrar newRegistrar = new Registrar(_domain, msg.sender);
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
        return registry[_domain].owner == address(0);
    }
}