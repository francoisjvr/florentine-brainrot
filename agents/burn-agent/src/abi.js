import { Interface } from "ethers";

export const GROTESCHI_ABI = [
  "function agentBurnFromCollection(uint256 tokenId)",
  "function ownerOf(uint256 tokenId) view returns (address)",
  "function isAdmin(address account) view returns (bool)",
  "function getAgentBurnedCount() view returns (uint256)"
];

export const GROTESCHI_IFACE = new Interface(GROTESCHI_ABI);
export const AGENT_BURN_SELECTOR = GROTESCHI_IFACE.getFunction("agentBurnFromCollection").selector;

export function encodeAgentBurn(tokenId) {
  const parsed = BigInt(tokenId);
  if (parsed <= 0n) throw new Error("tokenId must be a positive integer");
  return GROTESCHI_IFACE.encodeFunctionData("agentBurnFromCollection", [parsed]);
}
