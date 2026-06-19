import { expect } from "chai";
import hre from "hardhat";

const { ethers } = hre;

async function deployFixture() {
  const [owner, minter, payout, other, admin] = await ethers.getSigners();
  const MockSeaDrop = await ethers.getContractFactory("MockSeaDrop");
  const seaDrop = await MockSeaDrop.deploy();
  await seaDrop.waitForDeployment();
  const FlorentineGroteschi = await ethers.getContractFactory("FlorentineGroteschi");
  const groteschi = await FlorentineGroteschi.deploy(owner.address, payout.address, 250, [seaDrop.target]);
  await groteschi.waitForDeployment();
  return { owner, minter, payout, other, admin, seaDrop, groteschi };
}

describe("FlorentineGroteschi", function () {
  it("deploys with Florentine Groteschi collection settings and SeaDrop allowlist", async function () {
    const { groteschi, payout, seaDrop } = await deployFixture();
    expect(await groteschi.name()).to.equal("Florentine Groteschi");
    expect(await groteschi.symbol()).to.equal("FGROT");
    expect(await groteschi.DEFAULT_MAX_SUPPLY()).to.equal(1401n);
    expect(await groteschi.maxSupply()).to.equal(1401n);
    expect(await groteschi.allowedSeaDrop(seaDrop.target)).to.equal(true);
    const royalty = await groteschi.royaltyInfo(1, 10_000n);
    expect(royalty[0]).to.equal(payout.address);
    expect(royalty[1]).to.equal(250n);
  });

  it("rejects ETH and disables direct public minting in favor of SeaDrop", async function () {
    const { groteschi, minter } = await deployFixture();
    await expect(minter.sendTransaction({ to: groteschi.target, value: 1n })).to.be.revertedWithCustomError(groteschi, "EthNotAccepted");
    await expect(groteschi.connect(minter).mint(1)).to.be.revertedWithCustomError(groteschi, "NotSeaDropCompatibleMintPath");
  });

  it("exposes SeaDrop interface ids", async function () {
    const { groteschi } = await deployFixture();
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
    expect(await groteschi.supportsInterface(ethers.hexlify(seaDropTokenInterfaceId))).to.equal(true);
    expect(await groteschi.supportsInterface(ethers.hexlify(metadataInterfaceId))).to.equal(true);
  });

  it("lets allowed SeaDrop mint and tracks mint stats", async function () {
    const { groteschi, seaDrop, owner, minter, payout } = await deployFixture();
    const now = Math.floor(Date.now() / 1000);
    await groteschi.connect(owner).updateCreatorPayoutAddress(seaDrop.target, payout.address);
    await groteschi.connect(owner).updatePublicDrop(seaDrop.target, {
      mintPrice: 0,
      startTime: now - 60,
      endTime: now + 86400,
      maxTotalMintableByWallet: 3,
      feeBps: 0,
      restrictFeeRecipients: false
    });

    await expect(seaDrop.mintPublic(groteschi.target, minter.address, 2)).to.emit(groteschi, "Transfer");
    expect(await groteschi.totalMinted()).to.equal(2n);
    expect(await groteschi.totalSupply()).to.equal(2n);
    expect(await groteschi.ownerOf(1)).to.equal(minter.address);
    expect(await groteschi.ownerOf(2)).to.equal(minter.address);
    const stats = await groteschi.getMintStats(minter.address);
    expect(stats[0]).to.equal(2n);
    expect(stats[1]).to.equal(2n);
    expect(stats[2]).to.equal(1401n);
  });

  it("blocks non-SeaDrop callers from mintSeaDrop", async function () {
    const { groteschi, minter } = await deployFixture();
    await expect(groteschi.connect(minter).mintSeaDrop(minter.address, 1)).to.be.revertedWithCustomError(groteschi, "OnlyAllowedSeaDrop");
  });

  it("builds OpenSea-style tokenURI from base URI and suffix", async function () {
    const { groteschi, owner, minter } = await deployFixture();
    await groteschi.connect(owner).setBaseURI("ipfs://collection-metadata/");
    await groteschi.connect(owner).devMint(minter.address, 1);
    expect(await groteschi.tokenURI(1)).to.equal("ipfs://collection-metadata/1.json");
    await groteschi.connect(owner).setURISuffix("");
    expect(await groteschi.tokenURI(1)).to.equal("ipfs://collection-metadata/1");
  });

  it("enforces max supply and dev mint boundaries", async function () {
    const { groteschi, owner } = await deployFixture();
    await expect(groteschi.connect(owner).devMint(owner.address, 0)).to.be.revertedWithCustomError(groteschi, "InvalidAmount");
    await expect(groteschi.connect(owner).devMint(owner.address, 101)).to.be.revertedWithCustomError(groteschi, "InvalidAmount");
    await groteschi.connect(owner).setMaxSupply(2);
    await expect(groteschi.connect(owner).devMint(owner.address, 3)).to.be.revertedWithCustomError(groteschi, "SoldOut");
  });

  it("validates admin and SeaDrop configuration addresses", async function () {
    const { groteschi, owner } = await deployFixture();
    await expect(groteschi.connect(owner).setAdmin(ethers.ZeroAddress, true)).to.be.revertedWithCustomError(groteschi, "ZeroAddress");
    await expect(groteschi.connect(owner).updateAllowedSeaDrop([ethers.ZeroAddress])).to.be.revertedWithCustomError(groteschi, "ZeroAddress");
  });

  it("lets token owner or approved operator burn without incrementing agent counter", async function () {
    const { groteschi, owner, minter, other } = await deployFixture();
    await groteschi.connect(owner).devMint(minter.address, 1);
    await expect(groteschi.connect(other).burn(1)).to.be.revertedWithCustomError(groteschi, "NotTokenOwnerOrApproved");
    await expect(groteschi.connect(minter).burn(1))
      .to.emit(groteschi, "TokenBurned")
      .withArgs(minter.address, 1n);
    expect(await groteschi.totalSupply()).to.equal(0n);
    expect(await groteschi.totalMinted()).to.equal(1n);
    expect(await groteschi.totalBurned()).to.equal(1n);
    expect(await groteschi.getAgentBurnedCount()).to.equal(0n);
    await expect(groteschi.ownerOf(1)).to.be.reverted;
  });

  it("lets owner and enabled admins use the project agent burn path", async function () {
    const { groteschi, owner, minter, admin, other } = await deployFixture();
    await groteschi.connect(owner).devMint(minter.address, 2);

    await expect(groteschi.connect(other).agentBurnFromCollection(1)).to.be.revertedWithCustomError(groteschi, "NotOwnerOrAdmin");

    await expect(groteschi.connect(owner).agentBurnFromCollection(1))
      .to.emit(groteschi, "CollectionBurned")
      .withArgs(groteschi.target, 1n);
    expect(await groteschi.totalSupply()).to.equal(1n);
    expect(await groteschi.getAgentBurnedCount()).to.equal(1n);

    await groteschi.connect(owner).setAdmin(admin.address, true);
    await expect(groteschi.connect(admin).agentBurnFromCollection(2))
      .to.emit(groteschi, "CollectionBurned")
      .withArgs(groteschi.target, 2n);
    expect(await groteschi.totalSupply()).to.equal(0n);
    expect(await groteschi.totalMinted()).to.equal(2n);
    expect(await groteschi.totalBurned()).to.equal(2n);
    expect(await groteschi.getAgentBurnedCount()).to.equal(2n);
  });
});
