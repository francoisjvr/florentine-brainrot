import fs from "node:fs";
import hre from "hardhat";

const { ethers, network } = hre;
const DEFAULT_SEADROP = "0x00005EA00Ac477B1030CE78506496e8C2dE24bf5";

function requireAddress(name, fallback) {
  const value = process.env[name] || fallback;
  if (!value || !ethers.isAddress(value) || value === ethers.ZeroAddress) {
    throw new Error(`${name} must be a non-zero address`);
  }
  return value;
}

function parseAddressList(name, fallbackList = []) {
  const raw = process.env[name];
  const values = raw ? raw.split(",").map((v) => v.trim()).filter(Boolean) : fallbackList;
  for (const value of values) {
    if (!ethers.isAddress(value) || value === ethers.ZeroAddress) throw new Error(`${name} contains invalid address: ${value}`);
  }
  return values;
}

async function main() {
  const [deployer] = await ethers.getSigners();
  const owner = requireAddress("OWNER", deployer.address);
  const payoutWallet = requireAddress("PAYOUT_WALLET", deployer.address);
  const royaltyBps = BigInt(process.env.ROYALTY_BPS || "250");
  const allowedSeaDrop = parseAddressList("ALLOWED_SEADROP", [DEFAULT_SEADROP]);

  console.log(`Deploying Florentine Groteschi to ${network.name} (${network.config.chainId ?? "unknown chain"})`);
  console.log(`Deployer: ${deployer.address}`);
  console.log(`Owner:    ${owner}`);
  console.log(`Payout:   ${payoutWallet}`);
  console.log(`SeaDrop:  ${allowedSeaDrop.join(", ")}`);

  const FlorentineGroteschi = await ethers.getContractFactory("FlorentineGroteschi");
  const groteschi = await FlorentineGroteschi.deploy(owner, payoutWallet, royaltyBps, allowedSeaDrop);
  await groteschi.waitForDeployment();
  const contractAddress = await groteschi.getAddress();
  console.log(`FlorentineGroteschi deployed: ${contractAddress}`);

  const deployment = {
    network: network.name,
    chainId: network.config.chainId ?? null,
    contract: contractAddress,
    owner,
    payoutWallet,
    royaltyBps: royaltyBps.toString(),
    allowedSeaDrop,
    maxSupply: "1401",
    intendedMint: "OpenSea SeaDrop public mint; configure drop through OpenSea/SeaDrop",
    deployedAt: new Date().toISOString()
  };
  fs.writeFileSync("deployment.json", JSON.stringify(deployment, null, 2));
  console.log("Wrote deployment.json");
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
