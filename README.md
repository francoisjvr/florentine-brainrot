# Florentine Groteschi

OpenSea SeaDrop-compatible ERC721 contract repo for **Florentine Groteschi**.

## What is included

- `src/FlorentineGroteschi.sol` — collection contract based on the SeaDrop-compatible `normie-pets/src` contract surface.
- `src/seadrop/` — vendored minimal OpenSea SeaDrop interfaces/structs used by the contract.
- Agent/admin burn feature ported from `morph-mint/src/AiShapu.sol`:
  - `setAdmin(address,bool)`
  - `agentBurnFromCollection(uint256)`
  - `getAgentBurnedCount()`
  - `agentBurnedCount`, `totalBurned`, live `totalSupply()` accounting
- `artwork/florentine-groteschi-final-polish/` — current 24-panel Florentine Groteschi final-polish preview batch, metadata, and render report.
- `artwork/florentine-groteschi-final-polish-preview.zip` — zipped copy of the same current preview batch.
- `test/FlorentineGroteschi.test.js` — SeaDrop compatibility, URI, supply, and burn tests.
- `docs/audit.md` — audit notes for the current contract.
- `agents/burn-agent/` — Privy-wallet burn agent scaffold with dry-run, queue daemon, audit logs, and X/Twitter burn announcements.

## Contract defaults

- Name: `Florentine Groteschi`
- Symbol: `FGROT`
- Max supply: `1,401`
- Mint path: SeaDrop / OpenSea-compatible `mintSeaDrop`
- Direct public `mint()` intentionally reverts so SeaDrop controls public mint settings.
- Token URI format: `baseURI + tokenId + uriSuffix`, default suffix `.json`

## Artwork note

The repo currently includes the latest 24-piece final-polish preview batch. The full 1,401 production artwork set can be added once generated/uploaded.

## Development

```bash
npm install
npm test
npm run compile
```

Burn agent setup and dry-runs are documented in `agents/burn-agent/README.md`.

## Deployment

Set env vars as needed:

```bash
OWNER=0x...
PAYOUT_WALLET=0x...
ROYALTY_BPS=250
ALLOWED_SEADROP=0x00005EA00Ac477B1030CE78506496e8C2dE24bf5
```

Then run:

```bash
npx hardhat run scripts/deploy.js --network mainnet
```

No deployment has been performed by this repo setup task.
