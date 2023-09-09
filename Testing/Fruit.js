const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Fruit contract", function () {
  let fruitContract;
  let owner;
  let alice;

  before(async function () {
    [owner, user1] = await ethers.getSigners();

    const Fruit = await ethers.getContractFactory("Fruit");
    fruitContract = await Fruit.deploy();
    await fruitContract.deployed();
  });

  it("Should deploy the Fruit contract", async function () {
    expect(fruitContract.address).to.not.equal(0);
  });

  it("Should have the correct name and symbol", async function () {
    expect(await fruitContract.name()).to.equal("Fruit");
    expect(await fruitContract.symbol()).to.equal("FRUIT");
  });

  it("Owner should be able to mint tokens", async function () {
    const mintAmount = ethers.utils.parseEther("100");
    await fruitContract.connect(owner).mint(user1.address, mintAmount);

    const user1Balance = await fruitContract.balanceOf(user1.address);
    expect(user1Balance).to.equal(mintAmount);
  });

  it("Non-owner should not be able to mint tokens", async function () {
    const mintAmount = ethers.utils.parseEther("50");

    try {
      await fruitContract.connect(user1).mint(owner.address, mintAmount);
      expect.fail("Should have thrown an error");
    } catch (error) {
      expect(error.message).to.include("Ownable: caller is not the owner");
    }
  });

});
