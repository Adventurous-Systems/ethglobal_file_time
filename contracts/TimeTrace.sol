// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TimeTrace is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply/*, ReentrancyGuard*/ {

////// TOKEN DATA
    // token id => block.timestamp
    mapping(uint => uint) public timestamp;
    // token id => cid
    mapping(uint => string) public uniqueCid;

////// TOKEN CREATOR MAPPINGS
    // token id => creator address
    mapping(uint => address) public tokenCreator;
    // 
    mapping(address => uint[]) public tokenCreatorOwnedIds;
    //
    mapping(address => uint) public amountOfTokensOwned;

////// TOKEN VERIFIERS MAPPINGS
    // token id => verfiers array
    mapping(uint => address[]) public tokenVerifiers;
    // token id => addresses that have verified the token
    mapping(uint => address[]) public addressThatVerifiedToken;
    //
    mapping(address => mapping(uint => bool)) public isVerified;
    //
    mapping(address => mapping(uint => bool)) public isTokenVerifier;
    //
    mapping(address => mapping(uint => uint)) public verifiedTokenTimestamp;

    bool isTransferrable = false;

    constructor(address initialOwner) ERC1155("ipfs://") Ownable(initialOwner) {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data, string memory _uniqueCid)
        public
        // onlyOwner
    {
        require(exists(id) == false, "This token already exists");
        timestamp[id] = block.timestamp;
        uniqueCid[id] = _uniqueCid;
        tokenCreator[id] = msg.sender;
        tokenCreatorOwnedIds[msg.sender].push(id);

        uint totalTokensOwned = amountOfTokensOwned[msg.sender];
        amountOfTokensOwned[msg.sender] = totalTokensOwned + 1;

        _mint(account, id, amount, data);

        // emit token minted
    }

    function addVerifiers(uint id, address[] memory _tokenVerifiers ) public /*onlyTokenCreator*/ {
        require(tokenCreator[id] == msg.sender, "Must be token creator to add verifiers"); 
        require(tokenVerifiers[id].length < 11, "can't have more than 10 verifiers");

        for (uint256 i = 0; i < _tokenVerifiers.length; i++) {
            require(isTokenVerifier[_tokenVerifiers[i]][id], "Is already a verifier");
            //require verifier not to be in the same slot if added a second or third round of verifiers. 

            tokenVerifiers[id].push(_tokenVerifiers[i]);
            isVerified[_tokenVerifiers[i]][id] = false;
            isTokenVerifier[_tokenVerifiers[i]][id] = true;

        //mint tokens to verifier addresses
        _mint(_tokenVerifiers[i], id, 1, "0x");
        }

        // emit verifiers addresses

        // potential to add timelock so that verifiers need to verify within a timeframe
    }

//should be able to overwrite verifiers or remove

    function verifyToken(uint id /*, uint placementInArray*/) public {
        // require(msg.sender == tokenVerifiers[id][placementInArray], "Must be on verifiers list to be able to verify");
        require(!isVerified[msg.sender][id], "Token already verified by this address");
        require(msg.sender != tokenCreator[id], "This address is the Token Creator and cannot be a verifier");
        require(isTokenVerifier[msg.sender][id], "Not authorized to verify this token");
        
        isVerified[msg.sender][id] = true;

        //mapping for timestamp
        verifiedTokenTimestamp[msg.sender][id] = block.timestamp;

        addressThatVerifiedToken[id].push(msg.sender);

        // emit address that verified
    } 

    function getVerifiers(uint256 id) public view returns (address[] memory) {
        return tokenVerifiers[id];
    }

    function getVerifiersLength(uint256 id) public view returns (uint) {
        return tokenVerifiers[id].length;
    }

    function getAddressesThatVerifiedToken(uint256 id) public view returns (address[] memory) {
        return addressThatVerifiedToken[id];
    }

    function getTokenCreatorOwnedIds() public view returns (uint[] memory) {
        return tokenCreatorOwnedIds[msg.sender];
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._update(from, to, ids, values);
    }

    // Override _safeTransferFrom to make tokens non-transferable
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes memory data) public override(ERC1155) {
        require(isTransferrable, "Tokens are not transferrable");
        //if creatorm token can be transferred

        super.safeTransferFrom(from, to, id, value, data);
    }

    // Override _safeBatchTransferFrom to make tokens non-transferable
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory values, bytes memory data) public override(ERC1155) {
        require(isTransferrable, "Tokens are not transferrable");
        //if creatorm token can be transferred

        super.safeBatchTransferFrom(from, to, ids, values, data);
    }

// function to create project smart contract ERC1155 (and stake token)
// project creator mus be token creator
// verifiers are now stakeholders which receive their own escrow smart contract wallet
// use cid to get json data of each element
// batch mint initial element portions for each stake holder where they receive either NFT or ERC20 token depending on element, each with own cid
    
}

/* 
Project ERC1155 Contract

enum Phases:
- procured
- delivered
- installed
- validated
- paymentReceived
- maintained (additional)

uint numElementStructs;
mapping (uint => ElementStruct) elementStructMapping;

struct ElementStruct {
  uint guid 
  address stakeholder 
  Phases currentPhase
  mapping(Phases => mapping(uint => string) pictureUriOfIssue //also timestamp
  // custom data
  bool paymentReceived
}

function MintBatch (as the project creator)
- to (stakeholder with verified token) stakeholder is the person/ team/ company that takes reponsibility for specific task/ elemet installation
- ids[] (guid id's) 
- amounts[] total of each guid item
- bytes 

function tokenElementProcured(id/guid) onlyStakeholder
procured = no, yes, partly

function tokenElementDelivered(id/guid) onlyStakeholder
delivered = no, yes, partly

function tokenElementInstalled(id/guid) onlyStakeholder
installed = no, yes, partly

function tokenElementValidated(id/guid) onlyStakeholder
validated = no, yes, partly

*/