const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("EarthERC20Token", function () {
  let earthToken;
  let admin;
  let minter;
  let recipient;

  before(async function () {
    [admin, minter, recipient] = await ethers.getSigners();

    const EarthERC20Token = await ethers.getContractFactory("EarthERC20Token");
    earthToken = await EarthERC20Token.deploy();
    await earthToken.deployed();
  });

  it("should deploy the EarthERC20Token contract", async function () {
    expect(earthToken.address).to.not.equal(0);
  });

  it("should have the correct name and symbol", async function () {
    expect(await earthToken.name()).to.equal("Earth");
    expect(await earthToken.symbol()).to.equal("EARTH");
  });

  it("should allow the admin to add and remove a minter", async function () {
    await earthToken.connect(admin).addMinter(minter.address);
    expect(await earthToken.hasRole(earthToken.CAN_MINT(), minter.address)).to.be.true;

    await earthToken.connect(admin).removeMinter(minter.address);
    expect(await earthToken.hasRole(earthToken.CAN_MINT(), minter.address)).to.be.false;
  });

  it("should allow the minter to mint tokens", async function () {
    const amountToMint = ethers.utils.parseEther("100");

    await earthToken.connect(admin).addMinter(minter.address);
    await earthToken.connect(minter).mint(recipient.address, amountToMint);

    const recipientBalance = await earthToken.balanceOf(recipient.address);
    expect(recipientBalance).to.equal(amountToMint);
  });

  it("should prevent non-minters from minting tokens", async function () {
    const amountToMint = ethers.utils.parseEther("100");

    try {
      await earthToken.connect(admin).mint(recipient.address, amountToMint);
      expect.fail("Should have thrown an error");
    } catch (error) {
      expect(error.message).to.include("Caller cannot mint");
    }
  });
  it("should allow the admin to remove a minter", async function () {
    await earthToken.connect(admin).addMinter(minter.address);
    expect(await earthToken.hasRole(earthToken.CAN_MINT(), minter.address)).to.be.true;

    await earthToken.connect(admin).removeMinter(minter.address);
    
    expect(await earthToken.hasRole(earthToken.CAN_MINT(), minter.address)).to.be.false;
  });

  it("should prevent non-admin from removing a minter", async function () {
    await earthToken.connect(admin).addMinter(minter.address);
    const nonAdmin = (await ethers.getSigners())[2];

    try {
      await earthToken.connect(nonAdmin).removeMinter(minter.address);
      expect.fail("Should have thrown an error");
    } catch (error) {
      expect(error.message).to.include("Caller must be admin");
    }
  });
});
