const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MintAllowance contract", function () {
  let mintAllowance;
  let earthToken;
  let owner;
  let pool;

  beforeEach(async function () {
    [owner, pool] = await ethers.getSigners();

    // Deploy the EarthERC20Token contract
    const EarthERC20Token = await ethers.getContractFactory("EarthERC20Token");
    earthToken = await EarthERC20Token.deploy();
    await earthToken.deployed();

    // Grant the CAN_MINT role to the owner account
    await earthToken.grantRole(await earthToken.CAN_MINT(), owner.address);

    // Mint some "earth" tokens for the owner and pool
    const mintAmount = ethers.utils.parseEther("1000");
    await earthToken.mint(owner.address, mintAmount);
    await earthToken.mint(pool.address, mintAmount);

    // Deploy the MintAllowance contract and set EarthERC20Token as the Earth token
    const MintAllowance = await ethers.getContractFactory("MintAllowance");
    mintAllowance = await MintAllowance.deploy(earthToken.address);
    await mintAllowance.deployed();
  });

  it("Should increase mint allowance for a pool", async function () {
    const amountToIncrease = ethers.utils.parseEther("100");

    // Approve MintAllowance contract to spend tokens on behalf of the owner
    await earthToken.connect(owner).approve(mintAllowance.address, amountToIncrease);

    // Increase the mint allowance for the pool
    await mintAllowance.connect(owner).increaseMintAllowance(pool.address, amountToIncrease);

    // Check the allowance of the pool
    const poolAllowance = await earthToken.allowance(mintAllowance.address, pool.address);
    expect(poolAllowance).to.equal(amountToIncrease);
  });

  it("Should burn unused mint allowance for a pool", async function () {
    const amountToIncrease = ethers.utils.parseEther("100");

    // Approve MintAllowance contract to spend tokens on behalf of the owner
    await earthToken.connect(owner).approve(mintAllowance.address, amountToIncrease);

    // Increase the mint allowance for the pool
    await mintAllowance.connect(owner).increaseMintAllowance(pool.address, amountToIncrease);

    // Burn the unused mint allowance for the pool
    await mintAllowance.connect(owner).burnUnusedMintAllowance(pool.address);

    // Check that the allowance for the pool is now zero
    const poolAllowance = await earthToken.allowance(mintAllowance.address, pool.address);
    expect(poolAllowance).to.equal(0);

    // Check that the burned tokens have been removed from the MintAllowance contract
    const mintAllowanceBalance = await earthToken.balanceOf(mintAllowance.address);
    expect(mintAllowanceBalance).to.equal(0);
  });
});
