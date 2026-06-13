# Strict Task Plan

## Objective
- Create a new GitHub repo for **Florentine Brainrot**.
- Base the NFT contract on `francoisjvr/normie-pets/src` because it is OpenSea SeaDrop-compatible.
- Port the agent burn/admin burn functionality from `francoisjvr/morph-mint/src` as an intentional project feature.
- Include the current Florentine Brainrot artwork/metadata outputs in the repo.
- Audit and verify the new contract before pushing.

## Impact Surface
- Solidity ERC721 contract and OpenSea SeaDrop compatibility surface.
- Admin role and agent burn behavior.
- Artwork/metadata repository assets.
- New GitHub repository `francoisjvr/florentine-brainrot`.

## Risk Class
- medium: new contract repo plus admin burn feature, but no deployment or on-chain transaction in scope.

## Assumptions / Unknowns
- Collection name: Florentine Brainrot.
- Token symbol: FBRAIN.
- Max supply: 1,401, matching the generated Florentine Brainrot art plan.
- Current repo will include the latest 24-piece final-polish artwork preview batch plus metadata/contact sheet/render report; full 1,401 production artwork can be added later when generated.
- OpenSea compatibility means preserve the SeaDrop token surface from Normie Pets.

## Out of Scope
- No contract deployment.
- No mint configuration on OpenSea/SeaDrop mainnet.
- No IPFS/Arweave upload.
- No full 1,401 image generation unless separately requested.

## Rollback Plan
- Trigger conditions: tests fail, audit finds a blocker, or pushed repo is wrong.
- Exact rollback steps:
  - Local: revert or delete `C:/Users/Francois/HermesWorkspace/florentine-brainrot`.
  - Remote: use `gh repo delete francoisjvr/florentine-brainrot` only if explicitly requested; otherwise push a corrective commit.
- Validation after rollback: `gh repo view francoisjvr/florentine-brainrot` or local `git status`.

## Implementation Checklist
- [x] Inspect source contracts and identify burn/admin pieces.
- [x] Scaffold Florentine Brainrot repo from Normie Pets project structure.
- [x] Rename collection contract and constants.
- [x] Add agent/admin burn state, events, admin setter, burn functions, and tests.
- [x] Add artwork/metadata preview assets with Git LFS tracking.
- [x] Add README and audit report.
- [ ] Create GitHub repo, commit, push, and verify remote.

## Verification Matrix
- [x] `npm install`
- [x] `npm test`
- [x] `npm run compile`
- [x] Static/manual Solidity audit notes written.
- [x] Dependency audit (`npm audit --audit-level=high`) reviewed.
- [x] Secret scan / tracked sensitive-file check reviewed.
- [ ] Git push preflight reviewed.
- [ ] Remote repository read back through GitHub.

## Approval Checkpoint
- Required? no — user explicitly requested new repo creation and push in this task.
- Status: proceeding autonomously.

## Review
- Summary: pending.
- Evidence: pending.
- Residual risks: pending.
- Follow-ups: pending.
