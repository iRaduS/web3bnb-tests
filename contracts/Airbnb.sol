// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract Airbnb is ERC721URIStorage {
    using Counters for Counters.Counter;

    struct AccomodationTokenStruct {
        uint256 tokenId;
        address payable owner;
        uint256 pricePerNight;
        bool currentlyListed;
    }

    event AccomodationTokenCreated(
        uint256 indexed tokenId,
        address owner,
        uint256 pricePerNight,
        bool currentlyListed
    );

    // _tokenIds has the most recent minted tokenId.
    Counters.Counter private _tokenIds;

    // _accomodations has the mapping from tokenId to an accomodation.
    mapping(uint256 => AccomodationTokenStruct) public _accomodations;
    mapping(uint256 => bool) public _accomodationExists;

    // modifier used to check positive price.
    modifier positivePrice(uint256 price) {
        require(price > 0, "Error: The price should be positive, above 0.");
        _;
    }

    modifier ownerAccomodation(uint256 accomodationTokenId) {
        require(
            _accomodationExists[accomodationTokenId],
            "Error: This accomodation doesn't exists."
        );
        require(
            msg.sender == _accomodations[accomodationTokenId].owner,
            "Error: You are not the owner of the accomodation."
        );
        _;
    }

    constructor() ERC721("Airbnb", "AIR") {}

    function createAccomodationToken(
        string memory tokenURI,
        uint256 pricePerNight
    ) public payable returns (uint256) {
        _tokenIds.increment();
        uint256 currentAccomodationToken = _tokenIds.current();

        _safeMint(msg.sender, currentAccomodationToken);
        _setTokenURI(currentAccomodationToken, tokenURI);

        _populateAccomodationToken(
            msg.sender,
            currentAccomodationToken,
            pricePerNight
        );
        return currentAccomodationToken;
    }

    function _populateAccomodationToken(
        address owner,
        uint256 tokenId,
        uint256 pricePerNight
    ) private positivePrice(pricePerNight) {
        _accomodations[tokenId] = AccomodationTokenStruct(
            tokenId,
            payable(owner),
            pricePerNight,
            false
        );
        _accomodationExists[tokenId] = true;

        emit AccomodationTokenCreated(tokenId, owner, pricePerNight, false);
    }

    function updateAccomodationPrice(uint256 tokenId, uint256 pricePerNight)
        public
        payable
        ownerAccomodation(tokenId)
        positivePrice(pricePerNight)
    {
        _accomodations[tokenId].pricePerNight = pricePerNight;
    }

    function updateCurrentlyListed(uint256 tokenId, bool currentlyListed)
        public
        payable
        ownerAccomodation(tokenId)
    {
        require(
            _accomodations[tokenId].currentlyListed != currentlyListed,
            "Error: Listing status should differ from the actual one."
        );

        _accomodations[tokenId].currentlyListed = currentlyListed;
    }

    function getCurrentAccomodations()
        public
        view
        returns (AccomodationTokenStruct[] memory)
    {
        uint256 accomodationSize = _tokenIds.current();

        AccomodationTokenStruct[]
            memory accomodations = new AccomodationTokenStruct[](
                accomodationSize
            );
        for (uint256 i = 0; i < accomodationSize; i++) {
            if (_accomodations[i + 1].owner != msg.sender) {
                continue;
            }

            AccomodationTokenStruct storage currentItem = _accomodations[i + 1];
            accomodations[i] = currentItem;
        }

        return accomodations;
    }

    function getAccomodations()
        public
        view
        returns (AccomodationTokenStruct[] memory)
    {
        uint256 accomodationSize = _tokenIds.current();

        AccomodationTokenStruct[]
            memory accomodations = new AccomodationTokenStruct[](
                accomodationSize
            );
        for (uint256 i = 0; i < accomodationSize; i++) {
            AccomodationTokenStruct storage currentItem = _accomodations[i + 1];
            accomodations[i] = currentItem;
        }

        return accomodations;
    }

    function getOwnerOfAccomodation(uint256 accomodationTokenId)
        public
        view
        returns (address)
    {
        require(
            _accomodationExists[accomodationTokenId],
            "Error: This accomodation doesn't exists."
        );

        return _accomodations[accomodationTokenId].owner;
    }

    function getPriceOfAccomodation(uint256 accomodationTokenId)
        public
        view
        returns (uint256)
    {
        require(
            _accomodationExists[accomodationTokenId],
            "Error: This accomodation doesn't exists."
        );

        return _accomodations[accomodationTokenId].pricePerNight;
    }
}