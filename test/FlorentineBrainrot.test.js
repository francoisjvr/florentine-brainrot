import { expect } from "chai";
import hre from "hardhat";

const { ethers } = hre;

async function deployFixture() {
  const [owner, minter, payout, other, admin] = await ethers.getSigners();
  const MockSeaDrop = await ethers.getContractFactory("MockSeaDrop");
  const seaDrop = await MockSeaDrop.deploy();
  await seaDrop.waitForDeployment();
  const FlorentineBrainrot = await ethers.getContractFactory("FlorentineBrainrot");
  const brainrot = await FlorentineBrainrot.deploy(owner.address, payout.address, 250, [seaDrop.target]);
  await brainrot.waitForDeployment();
  return { owner, minter, payout, other, admin, seaDrop, brainrot };
}

describe("FlorentineBrainrot", function () {
  it("deploys with Florentine Brainrot collection settings and SeaDrop allowlist", async function () {
    const { brainrot, payout, seaDrop } = await deployFixture();
    expect(await brainrot.name()).to.equal("Florentine Brainrot");
    expect(await brainrot.symbol()).to.equal("FBRAIN");
    expect(await brainrot.DEFAULT_MAX_SUPPLY()).to.equal(1401n);
    expect(await brainrot.maxSupply()).to.equal(1401n);
    expect(await brainrot.allowedSeaDrop(seaDrop.target)).to.equal(true);
    const royalty = await brainrot.royaltyInfo(1, 10_000n);
    expect(royalty[0]).to.equal(payout.address);
    expect(royalty[1]).to.equal(250n);
  });

  it("rejects ETH and disables direct public minting in favor of SeaDrop", async function () {
    const { brainrot, minter } = await deployFixture();
    await expect(minter.sendTransaction({ to: brainrot.target, value: 1n })).to.be.revertedWithCustomError(brainrot, "EthNotAccepted");
    await expect(brainrot.connect(minter).mint(1)).to.be.revertedWithCustomError(brainrot, "NotSeaDropCompatibleMintPath");
  });

  it("exposes SeaDrop interface ids", async function () {
    const { brainrot } = await deployFixture();
    const seaDropTokenInterfaceId = ethers.getBytes("0x00000000");
    const metadataInterfaceId = ethers.getBytes("0x00000000");
    const artifact = await hre.artifacts.readArtifact("INonFungibleSeaDropToken");
    const metadataArtifact = await hre.artifacts.readArtifact("ISeaDropTokenContractMetadata");
    const xorSelectors = (abi) => abi
      .filter((item) => item.type === "function")
      .reduce((acc, item) => {
        const iface = new ethers.Interface([item]);
        const selector = ethers.getBytes(iface.fragments[0].selector);
        return acc.map((b, i) => b ^ selector[i]);
      }, [0, 0, 0, 0]);
    seaDropTokenInterfaceId.set(xorSelectors(artifact.abi));
    metadataInterfaceId.set(xorSelectors(metadataArtifact.abi));
    expect(await brainrot.supportsInterface(ethers.hexlify(seaDropTokenInterfaceId))).to.equal(true);
    expect(await brainrot.supportsInterface(ethers.hexlify(metadataInterfaceId))).to.equal(true);
  });

  it("lets allowed SeaDrop mint and tracks mint stats", async function () {
    const { brainrot, seaDrop, owner, minter, payout } = await deployFixture();
    const now = Math.floor(Date.now() / 1000);
    await brainrot.connect(owner).updateCreatorPayoutAddress(seaDrop.target, payout.address);
    await brainrot.connect(owner).updatePublicDrop(seaDrop.target, {
      mintPrice: 0,
      startTime: now - 60,
      endTime: now + 86400,
      maxTotalMintableByWallet: 3,
      feeBps: 0,
      restrictFeeRecipients: false
    });

    await expect(seaDrop.mintPublic(brainrot.target, minter.address, 2)).to.emit(brainrot, "Transfer");
    expect(await brainrot.totalMinted()).to.equal(2n);
    expect(await brainrot.totalSupply()).to.equal(2n);
    expect(await brainrot.ownerOf(1)).to.equal(minter.address);
    expect(await brainrot.ownerOf(2)).to.equal(minter.address);
    const stats = await brainrot.getMintStats(minter.address);
    expect(stats[0]).to.equal(2n);
    expect(stats[1]).to.equal(2n);
    expect(stats[2]).to.equal(1401n);
  });

  it("blocks non-SeaDrop callers from mintSeaDrop", async function () {
    const { brainrot, minter } = await deployFixture();
    await expect(brainrot.connect(minter).mintSeaDrop(minter.address, 1)).to.be.revertedWithCustomError(brainrot, "OnlyAllowedSeaDrop");
  });

  it("builds OpenSea-style tokenURI from base URI and suffix", async function () {
    const { brainrot, owner, minter } = await deployFixture();
    await brainrot.connect(owner).setBaseURI("ipfs://collection-metadata/");
    await brainrot.connect(owner).devMint(minter.address, 1);
    expect(await brainrot.tokenURI(1)).to.equal("ipfs://collection-metadata/1.json");
    await brainrot.connect(owner).setURISuffix("");
    expect(await brainrot.tokenURI(1)).to.equal("ipfs://collection-metadata/1");
  });

  it("enforces max supply and dev mint boundaries", async function () {
    const { brainrot, owner } = await deployFixture();
    await expect(brainrot.connect(owner).devMint(owner.address, 0)).to.be.revertedWithCustomError(brainrot, "InvalidAmount");
    await expect(brainrot.connect(owner).devMint(owner.address, 101)).to.be.revertedWithCustomError(brainrot, "InvalidAmount");
    await brainrot.connect(owner).setMaxSupply(2);
    await expect(brainrot.connect(owner).devMint(owner.address, 3)).to.be.revertedWithCustomError(brainrot, "SoldOut");
  });

  it("validates admin and SeaDrop configuration addresses", async function () {
    const { brainrot, owner } = await deployFixture();
    await expect(brainrot.connect(owner).setAdmin(ethers.ZeroAddress, true)).to.be.revertedWithCustomError(brainrot, "ZeroAddress");
    await expect(brainrot.connect(owner).updateAllowedSeaDrop([ethers.ZeroAddress])).to.be.revertedWithCustomError(brainrot, "ZeroAddress");
  });

  it("lets token owner or approved operator burn without incrementing agent counter", async function () {
    const { brainrot, owner, minter, other } = await deployFixture();
    await brainrot.connect(owner).devMint(minter.address, 1);
    await expect(brainrot.connect(other).burn(1)).to.be.revertedWithCustomError(brainrot, "NotTokenOwnerOrApproved");
    await expect(brainrot.connect(minter).burn(1))
      .to.emit(brainrot, "TokenBurned")
      .withArgs(minter.address, 1n);
    expect(await brainrot.totalSupply()).to.equal(0n);
    expect(await brainrot.totalMinted()).to.equal(1n);
    expect(await brainrot.totalBurned()).to.equal(1n);
    expect(await brainrot.getAgentBurnedCount()).to.equal(0n);
    await expect(brainrot.ownerOf(1)).to.be.reverted;
  });

  it("lets owner and enabled admins use the project agent burn path", async function () {
    const { brainrot, owner, minter, admin, other } = await deployFixture();
    await brainrot.connect(owner).devMint(minter.address, 2);

    await expect(brainrot.connect(other).agentBurnFromCollection(1)).to.be.revertedWithCustomError(brainrot, "NotOwnerOrAdmin");

    await expect(brainrot.connect(owner).agentBurnFromCollection(1))
      .to.emit(brainrot, "CollectionBurned")
      .withArgs(brainrot.target, 1n);
    expect(await brainrot.totalSupply()).to.equal(1n);
    expect(await brainrot.getAgentBurnedCount()).to.equal(1n);

    await brainrot.connect(owner).setAdmin(admin.address, true);
    await expect(brainrot.connect(admin).agentBurnFromCollection(2))
      .to.emit(brainrot, "CollectionBurned")
      .withArgs(brainrot.target, 2n);
    expect(await brainrot.totalSupply()).to.equal(0n);
    expect(await brainrot.totalMinted()).to.equal(2n);
    expect(await brainrot.totalBurned()).to.equal(2n);
    expect(await brainrot.getAgentBurnedCount()).to.equal(2n);
  });
});
