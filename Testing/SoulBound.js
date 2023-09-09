const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SoulBound contract", function () {
  let soulBound;
  let owner;
  let user;
  let earthToken;

  const uri = "https://example.com/token/";
  const mintedAmount = ethers.utils.parseEther("1");

  beforeEach(async function () {
    [owner, user] = await ethers.getSigners();

    // Deploy the EarthERC20Token contract
    const EarthERC20Token = await ethers.getContractFactory("EarthERC20Token");
    earthToken = await EarthERC20Token.deploy();
    await earthToken.deployed();

    // Mint some EARTH tokens for the owner (who has the minter role)
    await earthToken.addMinter(owner.address);

    // Deploy the SoulBound contract
    const SoulBound = await ethers.getContractFactory("SoulBound");
    soulBound = await SoulBound.deploy(earthToken.address, uri);
    await soulBound.deployed();
  });

  it("Should mint tokens", async function () {
    // Add user to the whitelist
    await soulBound.connect(owner).addToWhiteList(user.address);

    // Mint tokens
    await soulBound.connect(user).safeMint();

    // Check if the user has a token
    const hasToken = await soulBound.connect(user).hasToken();
    expect(hasToken).to.be.true;
  });

  it("Should prevent non-owners from updating URI", async function () {
    const newURI = "https://new-uri.com/token/";

    // Try to update URI as a non-owner (should fail)
    try {
      await soulBound.connect(user).updateUri(newURI);
      expect.fail("Should have thrown an error");
    } catch (error) {
      expect(error.message).to.include("Not the owner");
    }
  });

  it("Should prevent non-whitelisted users from minting", async function () {
    // Try to mint as a non-whitelisted user (should fail)
    try {
      await soulBound.connect(user).safeMint();
      expect.fail("Should have thrown an error");
    } catch (error) {
      expect(error.message).to.include("Could not mint the token");
    }
  });

  it("Should prevent non-owners from revoking tokens", async function () {
  // Add user to the whitelist
  await soulBound.connect(owner).addToWhiteList(user.address);

  // Mint tokens
  await soulBound.connect(user).safeMint();
  
  const hasToken = await soulBound.connect(user).hasToken();
  expect(hasToken).to.be.true;

  // Try to revoke a token as a non-owner (should fail)
  const tokenId = 0; // Assuming it's the first token minted
  try {
    await soulBound.connect(user).revoke(tokenId);
    expect.fail("Should have thrown an error");
  } catch (error) {
    expect(error.message).to.include("Not the owner");
  }
});

  it("Should prevent non-owners from adding addresses to the whitelist", async function () {
    // Try to add an address to the whitelist as a non-owner (should fail)
    try {
      await soulBound.connect(user).addToWhiteList(owner.address);
      expect.fail("Should have thrown an error");
    } catch (error) {
      expect(error.message).to.include("Not the owner");
    }
  });

  it("Should allow the owner to add addresses to the whitelist", async function () {
    // Owner adds an address to the whitelist
    await soulBound.connect(owner).addToWhiteList(user.address);

    // Try to mint as the newly whitelisted user
    await soulBound.connect(user).safeMint();

    // Check if the user has a token
    const hasToken = await soulBound.connect(user).hasToken();
    expect(hasToken).to.be.true;

  });

});
