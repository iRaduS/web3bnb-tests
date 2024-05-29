// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Airbnb.sol";

contract Booking {
    using Counters for Counters.Counter;

    struct TemporaryUserStruct {
        uint256 id;
        uint256 tokenId;
        address user;
        uint256 startAccomodationTimestamp;
        uint256 endAccomodationTimestamp;
        bool checkedIn;
    }

    struct UnavailableStruct {
        uint256 startAccomodationTimestamp;
        uint256 endAccomodationTimestamp;
    }

    Airbnb public airbnbToken;

    Counters.Counter private _bookingIds;

    // _temporaryUsers has the mapping from a userId to an accomodation
    mapping(uint256 => TemporaryUserStruct[])
        private _temporaryUsersOnAccomodation;
    mapping(uint256 => TemporaryUserStruct) private _temporaryUsersOnId;
    mapping(address => TemporaryUserStruct[]) private _temporaryUsers;
    mapping(address => bool) private _temporaryUsersExists;
    mapping(uint256 => bool) private _temporaryUsersOnAccomodationExists;

    event BookingCreated(
        uint256 indexed tokenId,
        address user,
        uint256 startAccomodationTimestamp,
        uint256 endAccomodationTimestamp,
        bool checkedIn
    );

    event CheckInAccomodation(address user, uint256 bookingId);

    constructor(address _contractAirbnbAddress) {
        airbnbToken = Airbnb(_contractAirbnbAddress);
    }

    modifier notOwnerAccomodation(uint256 tokenId) {
        require(
            msg.sender != airbnbToken.getOwnerOfAccomodation(tokenId),
            "Error: You are the owner of this accomodation."
        );
        _;
    }

    modifier noBookingsForUser() {
        require(
            _temporaryUsersExists[msg.sender],
            "Error: You don't have any bookings."
        );
        _;
    }

    function createBookingToAccommodation(
        uint256 tokenId,
        uint256 startAccomodationTimestamp,
        uint256 endAccomodationTimestamp
    ) public payable notOwnerAccomodation(tokenId) {
        bool conditionDays = availableDaysInPeriod(
            tokenId,
            startAccomodationTimestamp,
            endAccomodationTimestamp
        );
        require(conditionDays == true, "Error: The period of time is invalid.");
        uint256 amountToPay = _computeDays(
            startAccomodationTimestamp,
            endAccomodationTimestamp
        ) * airbnbToken.getPriceOfAccomodation(tokenId);
        require(msg.value >= amountToPay, "Error: Insufficient founds.");

        _bookingIds.increment();
        uint256 currentBookingId = _bookingIds.current();
        TemporaryUserStruct memory dataToBeInserted = TemporaryUserStruct(
            currentBookingId,
            tokenId,
            msg.sender,
            startAccomodationTimestamp,
            endAccomodationTimestamp,
            false
        );

        _temporaryUsersOnId[currentBookingId] = dataToBeInserted;
        _temporaryUsersOnAccomodation[tokenId].push(dataToBeInserted);
        _temporaryUsers[msg.sender].push(dataToBeInserted);
        _temporaryUsersExists[msg.sender] = true;
        _temporaryUsersOnAccomodationExists[tokenId] = true;

        payable(airbnbToken.getOwnerOfAccomodation(tokenId)).transfer(msg.value);

        emit BookingCreated(
            tokenId,
            msg.sender,
            startAccomodationTimestamp,
            endAccomodationTimestamp,
            false
        );
    }

    function checkInBookingToAccommodation(uint256 bookingId) public payable {
        require(
            bookingId <= _bookingIds.current(),
            "Error: This booking ID doesn't exists."
        );
        require(
            _temporaryUsersOnId[bookingId].user == msg.sender,
            "Error: You are not the correct user for this accomodation."
        );

        _temporaryUsersOnId[bookingId].checkedIn = true;

        uint256 tokenId = _temporaryUsersOnId[bookingId].tokenId;
        for (
            uint256 i = 0;
            i < _temporaryUsersOnAccomodation[tokenId].length;
            i++
        ) {
            if (bookingId != _temporaryUsersOnAccomodation[tokenId][i].id) {
                continue;
            }

            _temporaryUsersOnAccomodation[tokenId][i].checkedIn = true;
        }
        for (uint256 i = 0; i < _temporaryUsers[msg.sender].length; i++) {
            if (bookingId != _temporaryUsers[msg.sender][i].id) {
                continue;
            }

            _temporaryUsers[msg.sender][i].checkedIn = true;
        }

        emit CheckInAccomodation(msg.sender, bookingId);
    }

    function getBookedAccommodations()
        public
        view
        noBookingsForUser
        returns (TemporaryUserStruct[] memory)
    {
        return _temporaryUsers[msg.sender];
    }

    function availableDaysInPeriod(
        uint256 tokenId,
        uint256 start,
        uint256 end
    ) internal view returns (bool) {
        UnavailableStruct[] memory unavailableDays = getUnavailableDays(
            tokenId
        );

        bool checkFreeInterval = true;
        for (uint256 i = 0; i < unavailableDays.length; i++) {
            if (
                unavailableDays[i].startAccomodationTimestamp <= start &&
                unavailableDays[i].endAccomodationTimestamp >= start
            ) {
                checkFreeInterval = false;
                break;
            }

            if (
                unavailableDays[i].startAccomodationTimestamp <= end &&
                unavailableDays[i].endAccomodationTimestamp >= end
            ) {
                checkFreeInterval = false;
                break;
            }
        }

        return checkFreeInterval;
    }

    function getUnavailableDays(uint256 tokenId)
        public
        view
        returns (UnavailableStruct[] memory)
    {
        UnavailableStruct[] memory unavailableDays = new UnavailableStruct[](
            _temporaryUsersOnAccomodation[tokenId].length
        );

        for (
            uint256 i = 0;
            i < _temporaryUsersOnAccomodation[tokenId].length;
            i++
        ) {
            unavailableDays[i] = UnavailableStruct(
                _temporaryUsersOnAccomodation[tokenId][i]
                    .startAccomodationTimestamp,
                _temporaryUsersOnAccomodation[tokenId][i]
                    .endAccomodationTimestamp
            );
        }

        return unavailableDays;
    }

    function _computeDays(uint256 startTimestamp, uint256 endTimestamp)
        internal
        pure
        returns (uint256)
    {
        require(
            startTimestamp <= endTimestamp,
            "Start timestamp must be before end timestamp"
        );
        uint256 difference = endTimestamp - startTimestamp;
        uint256 daysCount = difference / (86400 * 1000);

        return daysCount;
    }
}