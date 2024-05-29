const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Booking Contract", function () {
  let Airbnb;
  let airbnb;
  let Booking;
  let booking;
  let owner;
  let addr1;
  let addr2;
  let addrs;

  beforeEach(async function () {
    // Deploy Airbnb contract
    Airbnb = await ethers.getContractFactory("Airbnb");
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    airbnb = await Airbnb.deploy();

    // Mint an accommodation token
    await airbnb.createAccomodationToken("uri1", 100);

    // Deploy Booking contract
    Booking = await ethers.getContractFactory("Booking");
    booking = await Booking.deploy(airbnb.target);
  });

  describe("Create Booking", function () {
    it("Should create a new booking", async function () {
      const start = Math.floor(Date.now() / 1000) + 1000; // Start date in the future
      const end = start + 86400; // End date 1 day later

      await expect(booking.connect(addr1).createBookingToAccommodation(1, start, end, { value: 100 }))
        .to.emit(booking, "BookingCreated")
        .withArgs(1, addr1.address, start, end, false);

      const bookings = await booking.connect(addr1).getBookedAccommodations();
      expect(bookings.length).to.equal(1);
      expect(bookings[0].tokenId).to.equal(1);
      expect(bookings[0].startAccomodationTimestamp).to.equal(start);
      expect(bookings[0].endAccomodationTimestamp).to.equal(end);
      expect(bookings[0].checkedIn).to.equal(false);
    });

    it("Should fail if the owner tries to book their own accommodation", async function () {
      const start = Math.floor(Date.now() / 1000) + 1000; // Start date in the future
      const end = start + 86400; // End date 1 day later

      await expect(
        booking.createBookingToAccommodation(1, start, end, { value: 100 })
      ).to.be.revertedWith("Error: You are the owner of this accomodation.");
    });
  });

  describe("Check In Booking", function () {
    it("Should check in to a booking", async function () {
      const start = Math.floor(Date.now() / 1000) + 1000; // Start date in the future
      const end = start + 86400; // End date 1 day later

      await booking.connect(addr1).createBookingToAccommodation(1, start, end, { value: 100 });

      const bookingsBefore = await booking.connect(addr1).getBookedAccommodations();
      expect(bookingsBefore[0].checkedIn).to.equal(false);

      await booking.connect(addr1).checkInBookingToAccommodation(1);

      const bookingsAfter = await booking.connect(addr1).getBookedAccommodations();
      expect(bookingsAfter[0].checkedIn).to.equal(true);
    });

    it("Should fail if the booking ID doesn't exist", async function () {
      await expect(booking.checkInBookingToAccommodation(1)).to.be.revertedWith("Error: This booking ID doesn't exists.");
    });

    it("Should fail if another user tries to check in", async function () {
      const start = Math.floor(Date.now() / 1000) + 1000; // Start date in the future
      const end = start + 86400; // End date 1 day later

      await booking.connect(addr1).createBookingToAccommodation(1, start, end, { value: 100 });

      await expect(
        booking.connect(addr2).checkInBookingToAccommodation(1)
      ).to.be.revertedWith("Error: You are not the correct user for this accomodation.");
    });
  });

  describe("Get Booked Accommodations", function () {
    it("Should return the user's booked accommodations", async function () {
      const start = Math.floor(Date.now() / 1000) + 1000; // Start date in the future
      const end = start + 86400; // End date 1 day later

      await booking.connect(addr1).createBookingToAccommodation(1, start, end, { value: 100 });

      const bookings = await booking.connect(addr1).getBookedAccommodations();
      expect(bookings.length).to.equal(1);
      expect(bookings[0].tokenId).to.equal(1);
    });

    it("Should fail if the user has no bookings", async function () {
      await expect(booking.getBookedAccommodations()).to.be.revertedWith("Error: You don't have any bookings.");
    });
  });

  describe("Get Unavailable Days", function () {
    it("Should return the unavailable days for an accommodation", async function () {
      const start = Math.floor(Date.now() / 1000) + 1000;
      const end = start + 86400;

      await booking.connect(addr1).createBookingToAccommodation(1, start, end, { value: 100 });

      const unavailableDays = await booking.getUnavailableDays(1);
      expect(unavailableDays.length).to.equal(1);
      expect(unavailableDays[0].startAccomodationTimestamp).to.equal(start);
      expect(unavailableDays[0].endAccomodationTimestamp).to.equal(end);
    });
  });
});
