// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {FunctionsClient} from "@chainlink/contracts@1.1.0/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts@1.1.0/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts@1.1.0/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IGuruSeasonPassV2NFT} from "./interfaces.sol";


contract GuruSeason2PassNFT is ERC721, ERC721Enumerable, FunctionsClient, ConfirmedOwner {
    using FunctionsRequest for FunctionsRequest.Request;

    uint256 private _nextTokenId;
    uint256 private constant MINTING_START_TIME = 1648656000;      // 03/30/2022 @ 9:00am (PST)
    uint256 private constant MINTING_END_TIME = 1748018270;     // 04/01/2022 @ 9:00am (PST)
    uint256 private constant NFT_PER_ADDRESS_LIMIT = 1;
    bytes32 public MERKLE_ROOT = 0x85c99f9ed408529a8e32d19f1606c0783273722f7a42ae71ef5f7345b0e62870;
    address private immutable season1Address;
    IGuruSeasonPassV2NFT IGURU_SEASON_1_PASS_NFT = IGuruSeasonPassV2NFT(0x9bF88fAe8CF8BaB76041c1db6467E7b37b977dD7);


    // ChainLink functions vars
    bytes32 public s_lastRequestId;
    string public baseURI;
    bytes public s_lastError;

    error UnexpectedRequestID(bytes32 requestId);
    event Response(bytes32 indexed requestId, bytes response, bytes err);

    constructor(address initialOwner, address router, address _season1Address)
            ERC721("GuruSeason2PassNFT", "GURUV2") FunctionsClient(router) ConfirmedOwner(initialOwner)
    {
        season1Address = _season1Address;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://flow.gurunetwork.ai/seasons/2";
    }

    function safeMint(bytes32[] calldata proof) public {
        require(balanceOf(msg.sender) < NFT_PER_ADDRESS_LIMIT, "You have reached max number of NFT!");
        require(block.timestamp >= MINTING_START_TIME, "SeasonPass is not yet available!");
        require(block.timestamp <= MINTING_END_TIME, "SeasonPass has been sold out!");
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender))));
        require(MerkleProof.verify(proof, MERKLE_ROOT, leaf), "Invalid proof");
        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


    function sendRequest(
        string memory source,
        bytes memory encryptedSecretsUrls,
        uint8 donHostedSecretsSlotID,
        uint64 donHostedSecretsVersion,
        string[] memory args,
        bytes[] memory bytesArgs,
        uint64 subscriptionId,
        uint32 gasLimit,
        bytes32 donID
    ) external onlyOwner returns (bytes32 requestId) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source);
        if (encryptedSecretsUrls.length > 0)
            req.addSecretsReference(encryptedSecretsUrls);
        else if (donHostedSecretsVersion > 0) {
            req.addDONHostedSecrets(
                donHostedSecretsSlotID,
                donHostedSecretsVersion
            );
        }
        if (args.length > 0) req.setArgs(args);
        if (bytesArgs.length > 0) req.setBytesArgs(bytesArgs);
        s_lastRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donID
        );
        return s_lastRequestId;
    }

    function sendRequestCBOR(
        bytes memory request,
        uint64 subscriptionId,
        uint32 gasLimit,
        bytes32 donID
    ) external onlyOwner returns (bytes32 requestId) {
        s_lastRequestId = _sendRequest(
            request,
            subscriptionId,
            gasLimit,
            donID
        );
        return s_lastRequestId;
    }

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (s_lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId);
        }
        if (err.length == 0) {
            updateMerkleRoot(response);
         }
        s_lastError = err;
        emit Response(requestId, response, s_lastError);
    }

    function updateMerkleRoot(bytes memory newRoot) internal {
        MERKLE_ROOT = bytes32(newRoot);
    }

}