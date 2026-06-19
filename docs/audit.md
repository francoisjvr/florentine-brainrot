# Florentine Groteschi Contract Audit

Date: 2026-06-19
Scope: `src/FlorentineGroteschi.sol`, vendored SeaDrop interfaces, and `test/FlorentineGroteschi.test.js`.

## Summary

No blocking contract issues found in the current implementation.

The contract preserves the SeaDrop-compatible mint/admin surface from the Normie Pets source contract and adds the project-required agent burn path from Morph Mint. The burn behavior is intentional: burned tokens do not reopen mint supply.

## Verified properties

- Collection name/symbol: `Florentine Groteschi` / `FGROT`.
- Max supply: `1,401`.
- Direct `mint()` reverts; minting is routed through `mintSeaDrop` from allowed SeaDrop contracts.
- ETH receive/fallback reverts.
- SeaDrop interface IDs are exposed.
- OpenSea-style token URI uses `baseURI + tokenId + uriSuffix`.
- Owner/approved token burn works and does not increment agent burn count.
- Owner/admin `agentBurnFromCollection` works and increments `agentBurnedCount`.
- Burned supply accounting:
  - `totalMinted` remains lifetime minted supply.
  - `totalBurned` tracks burned tokens.
  - `totalSupply()` returns live supply (`totalMinted - totalBurned`).
  - `getMintStats()` returns `totalMinted` for SeaDrop cap accounting so burns do not reopen mint capacity.
- Zero-address config checks added for admin and allowed SeaDrop updates.
- Deployed bytecode size: `12,066` bytes, under Ethereum's `24,576` byte limit.

## Test evidence

`npm test`

- 14 passing tests.

`npm run compile`

- Hardhat compile successful / nothing left to compile after test compile.

`npm audit --omit=dev --audit-level=high`

- 0 production vulnerabilities.

Secret scan across project source/assets excluding `node_modules`, `cache`, `artifacts`, `.git`:

- 0 findings for private keys, GitHub tokens, OpenAI-style keys, AWS keys, or hardcoded password assignments.

## Dependency audit notes

`npm audit fix` cannot resolve all dev dependency advisories without breaking upgrades to Hardhat/toolbox. Current remaining advisories are in dev tooling dependency trees (`hardhat`, `@nomicfoundation/hardhat-toolbox`, `solidity-coverage`, `mocha`, `ethers` transitive packages). They are not production/runtime contract dependencies. This repo should still periodically upgrade Hardhat/toolbox once the plugin ecosystem supports a clean non-breaking path.

## Manual review notes

### SeaDrop mint path

- `mintSeaDrop` checks caller is in `allowedSeaDrop`.
- Quantity must be non-zero.
- Mints cannot exceed `_maxSupply`.
- State is updated before `_safeMint` loop.
- Function is `nonReentrant`.

### Burn/admin path

- `burn` requires token owner or approved operator via OpenZeppelin `_isAuthorized`.
- `agentBurnFromCollection` requires owner or an enabled admin.
- Both burn functions call `_requireOwned` before `_burn`, so nonexistent tokens revert before counters increment.
- Counters update after `_burn` succeeds.
- Admin role is explicit and emits `AdminSet`.

### Metadata/URI

- `setBaseURI` and `setURISuffix` emit EIP-4906-style batch metadata update events through the vendored SeaDrop metadata interface event.
- `tokenURI` reverts for nonexistent tokens through `_requireOwned`.

## Residual risks / follow-ups

- Full 1,401 production artwork is not yet in this repo; the current included artwork is the latest 24-piece final-polish preview batch.
- Dev dependency audit has known Hardhat/toolbox transitive advisories requiring breaking updates to clear.
- No deployment was performed in this task; deployment config and SeaDrop/OpenSea drop setup still need a separate deployment checklist.
