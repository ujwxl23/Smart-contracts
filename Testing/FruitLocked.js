const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("LockedFruit contract", function () {
  let lockedFruit;
  let fruit;
  let owner;
  let user;

  beforeEach(async function () {
    [owner, user] = await ethers.getSigners();

    // Deploy the Fruit contract
    const Fruit = await ethers.getContractFactory("Fruit");
    fruit = await Fruit.deploy();
    await fruit.deployed();

    // Deploy the LockedFruit contract and set Fruit as the token being staked
    const LockedFruit = await ethers.getContractFactory("LockedFruit");
    lockedFruit = await LockedFruit.deploy(fruit.address);
    await lockedFruit.deployed();
  });

  it("Should deploy the LockedFruit contract", async function () {
    expect(lockedFruit.address).to.not.equal(0);
  });

  it("Should allow locking Fruit tokens", async function () {
    // Lock some Fruit tokens for the user
    const lockAmount = ethers.utils.parseEther("100");
    const lockDuration = Math.floor(Date.now() / 1000) + 3600; // Lock for 1 hour
    await fruit.connect(owner).mint(user.address, lockAmount);
    await fruit.connect(user).approve(lockedFruit.address, lockAmount);

    await lockedFruit.connect(user).lock(lockAmount, lockDuration);

    // Check the number of locks for the user
    const numLocks = await lockedFruit.numLocks(user.address);
    expect(numLocks).to.equal(1);
    });

  it("Should prevent withdrawing locked Fruit tokens before the lock duration", async function () {
    // Attempt to withdraw the locked tokens (should fail as they are still locked)
    const lockAmount = ethers.utils.parseEther("100");
    const lockDuration = Math.floor(Date.now() / 1000) + 3600; // Lock for 1 hour
    await fruit.connect(owner).mint(user.address, lockAmount);
    await fruit.connect(user).approve(lockedFruit.address, lockAmount);

    await lockedFruit.connect(user).lock(lockAmount, lockDuration);
    const numLocks = await lockedFruit.numLocks(user.address);
    expect(numLocks).to.equal(1);
    try {
      await lockedFruit.connect(user).withdraw(0);
      expect.fail("Should have thrown an error");
    } catch (error) {
      expect(error.message).to.include("Specified entry is still locked");
    }
    });

    it("Should allow locking and withdrawing Fruit tokens", async function () {
    // Lock some Fruit tokens for the user
    const lockAmount = ethers.utils.parseEther("100");
    const lockDuration = Math.floor(Date.now() / 1000) + 3600; // Lock for 1 hour
    await fruit.connect(owner).mint(user.address, lockAmount);
    await fruit.connect(user).approve(lockedFruit.address, lockAmount);

    await lockedFruit.connect(user).lock(lockAmount, lockDuration);

    // Check the number of locks for the user
    const numLocks = await lockedFruit.numLocks(user.address);
    expect(numLocks).to.equal(1);

    // Advance the time to unlock the tokens
    await ethers.provider.send("evm_increaseTime", [3601]); // Move time forward by 1 hour + 1 second

    // Withdraw the locked tokens
    await lockedFruit.connect(user).withdraw(0);

    // Check the user's Fruit balance after withdrawal
    const userBalance = await fruit.balanceOf(user.address);
    expect(userBalance).to.equal(lockAmount);
  });

  it("Should not allow withdrawing non-existent locks", async function () {
    // Attempt to withdraw a non-existent lock
    try {
      await lockedFruit.connect(user).withdraw(0);
      expect.fail("Should have thrown an error");
    } catch (error) {
      expect(error.message).to.include("No lock entry at the specified index");
    }
  });
});
