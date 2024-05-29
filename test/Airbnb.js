const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Airbnb Contract", function () {
  let Airbnb;
  let airbnb;
  let owner;
  let addr1;
  let addr2;
  let addrs;

  beforeEach(async function () {
    Airbnb = await ethers.getContractFactory("Airbnb");
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    airbnb = await Airbnb.deploy();
  });

  describe("Create Accomodation Token", function () {
    it("Should create a new accomodation token", async function () {
      await expect(airbnb.createAccomodationToken("uri1", 100))
        .to.emit(airbnb, "AccomodationTokenCreated")
        .withArgs(1, owner.address, 100, false);

      const accomodation = await airbnb._accomodations(1);
      expect(accomodation.owner).to.equal(owner.address);
      expect(accomodation.pricePerNight).to.equal(100);
      expect(accomodation.currentlyListed).to.equal(false);
    });
  });

  describe("Update Accomodation Price", function () {
    it("Should update the price of an accomodation token", async function () {
      await airbnb.createAccomodationToken("uri1", 100);
      await airbnb.updateAccomodationPrice(1, 200);

      const accomodation = await airbnb._accomodations(1);
      expect(accomodation.pricePerNight).to.equal(200);
    });

    it("Should fail if not the owner tries to update price", async function () {
      await airbnb.createAccomodationToken("uri1", 100);
      await expect(airbnb.connect(addr1).updateAccomodationPrice(1, 200)).to.be.revertedWith("Error: You are not the owner of the accomodation.");
    });
  });

  describe("Update Currently Listed", function () {
    it("Should update the listing status of an accomodation token", async function () {
      await airbnb.createAccomodationToken("uri1", 100);
      await airbnb.updateCurrentlyListed(1, true);

      const accomodation = await airbnb._accomodations(1);
      expect(accomodation.currentlyListed).to.equal(true);
    });

    it("Should fail if not the owner tries to update listing status", async function () {
      await airbnb.createAccomodationToken("uri1", 100);
      await expect(airbnb.connect(addr1).updateCurrentlyListed(1, true)).to.be.revertedWith("Error: You are not the owner of the accomodation.");
    });
  });

  describe("Get Accomodations", function () {
    it("Should return all accomodations", async function () {
      await airbnb.createAccomodationToken("uri1", 100);
      await airbnb.createAccomodationToken("uri2", 200);

      const accomodations = await airbnb.getAccomodations();
      expect(accomodations.length).to.equal(2);
    });
  });

  describe("Get Current Accomodations", function () {
    it("Should return current user's accomodations", async function () {
      await airbnb.createAccomodationToken("uri1", 100);
      await airbnb.connect(addr1).createAccomodationToken("uri2", 200);

      const accomodations = await airbnb.getCurrentAccomodations();
      expect(accomodations.length).to.equal(2);
    });
  });

  describe("Get Owner of Accomodation", function () {
    it("Should return the owner of an accomodation", async function () {
      await airbnb.createAccomodationToken("uri1", 100);

      const ownerAddress = await airbnb.getOwnerOfAccomodation(1);
      expect(ownerAddress).to.equal(owner.address);
    });

    it("Should fail if accomodation doesn't exist", async function () {
      await expect(airbnb.getOwnerOfAccomodation(1)).to.be.revertedWith("Error: This accomodation doesn't exists.");
    });
  });

  describe("Get Price of Accomodation", function () {
    it("Should return the price of an accomodation", async function () {
      await airbnb.createAccomodationToken("uri1", 100);

      const price = await airbnb.getPriceOfAccomodation(1);
      expect(price).to.equal(100);
    });

    it("Should fail if accomodation doesn't exist", async function () {
      await expect(airbnb.getPriceOfAccomodation(1)).to.be.revertedWith("Error: This accomodation doesn't exists.");
    });
  });
});
