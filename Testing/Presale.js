const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Presale contract", function () {
  let owner;
  let user;
  let STABLEC;
  let EARTH;
  let STAKING;
  let TREASURY;
  let SOULBOUND;
  let presale;

  beforeEach(async function () {
    [owner, user] = await ethers.getSigners();

    // Deploy mock contracts (you should replace these with actual contract deployments)
    const STABLECFactory = await ethers.getContractFactory("StableCoin");
    STABLEC = await STABLECFactory.deploy();

    const EarthERC20TokenFactory = await ethers.getContractFactory("EarthERC20Token");
    EARTH = await EarthERC20TokenFactory.deploy();
    await EARTH.deployed();

    const EarthStakingFactory = await ethers.getContractFactory("EarthStaking");
    STAKING = await EarthStakingFactory.deploy(EARTH.address, 3600, Math.floor(Date.now() / 1000) - (24 * 3600));

    const EarthTreasuryFactory = await ethers.getContractFactory("EarthTreasury");
    TREASURY = await EarthTreasuryFactory.deploy(EARTH.address, STABLEC.address);

    const SoulBoundFactory = await ethers.getContractFactory("SoulBound");
    SOULBOUND = await SoulBoundFactory.deploy(STABLEC.address, "uri_here");

    // Deploy the Presale contract
    const PresaleFactory = await ethers.getContractFactory("Presale");
    presale = await PresaleFactory.deploy(
      STABLEC.address,
      EARTH.address,
      STAKING.address,
      TREASURY.address,
      100, // Replace with an actual 'mintMultiple' value
      SOULBOUND.address
    );

    await presale.deployed();

    // Add the user to the whitelist in the SoulBound contract
    await SOULBOUND.connect(owner).addToWhiteList(user.address);
  });

  it("Should allow the owner to update the NFT address", async function () {
    const newSoulBoundAddress = "0x9u3v052u50u423i92vuv092u50u"; // New NFT address

    // Check the initial NFT address
    const initialSoulBoundAddress = await presale.SOULBOUND();
    expect(initialSoulBoundAddress).to.not.equal(newSoulBoundAddress);
  });

  it("Should allow the owner to update the mint multiple", async function () {
    const newMintMultiple = 200; // New mint multiple value

    // Check the initial mint multiple
    const initialMintMultiple = await presale.mintMultiple();
    expect(initialMintMultiple).to.equal(100); // Assuming the initial mint multiple is 100

    // Update the mint multiple as the owner
    await presale.connect(owner).updateMintMultiple(newMintMultiple);

    // Check the updated mint multiple
    const updatedMintMultiple = await presale.mintMultiple();
    expect(updatedMintMultiple).to.equal(newMintMultiple);
  });

  it("Should allow the owner to pause and unpause the contract", async function () {
    // Check if the contract is initially not paused
    const isPaused = await presale.paused();
    expect(isPaused).to.equal(false);

    // Pause the contract as the owner
    await presale.connect(owner).pause();

    // Check if the contract is paused
    const isPausedAfterPause = await presale.paused();
    expect(isPausedAfterPause).to.equal(true);

    // Unpause the contract as the owner
    await presale.connect(owner).unpause();

    // Check if the contract is not paused again
    const isPausedAfterUnpause = await presale.paused();
    expect(isPausedAfterUnpause).to.equal(false);
  });

  it("Should not allow a user to mint tokens without owning NFTs", async function () {
    const contributionAmount = ethers.utils.parseEther("10"); // Adjust the amount as needed

    // Mint stablecoin tokens for the user
    await STABLEC.mint(contributionAmount, user.address);

    // Approve the Presale contract to spend STABLEC on behalf of the user
    await STABLEC.connect(user).approve(presale.address, contributionAmount);

    // Attempt to participate in the presale without owning NFTs
    // This should revert with the "Must own NFTs" error message
    await expect(presale.mint(contributionAmount)).to.be.revertedWith("Must own NFTs");
  });

});
