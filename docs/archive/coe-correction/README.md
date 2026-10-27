# CoE correction: status and how to resume

Last updated 2026-10-20. This folder exists so the work on the CoE `university` correction can continue from any device. It holds no secrets.

## Status at a glance

| Item | State |
|---|---|
| #52 script fixes and deployment summary | Done 2026-10-20. CoE PR 19 merged (`main` `db65758`): Step 4 re-reviewed (pass11), handoff re-emitted, tree hash matches, Step 5 complete. The kit's `archetype/` is re-packaged from it. |
| #60 deployer Monitoring Metrics Publisher | Done 2026-10-20, same delivery. The playbook grant stays only as a fallback for deployments from before that date. |
| #40 B14 adoption agent | Not started. The CoE commit to pin is `db65758`. |
| #44 B15 learning path | Done and live (#83, #84). Nothing left. |
| Lab foundation (hub, spokes) | Deployed for member 1 on 2026-10-19 and still running. Tracked in #87. |
| Documenting the accepted lab risks for adopters | Done (#94). |

## What exists where

- **CoE:** [`jonathan-vella/apex-factory-coe`](https://github.com/jonathan-vella/apex-factory-coe) `main` at `db65758` (PR 19, merged 2026-10-20). Step 4 and Step 5 are complete. The selected Step 4 review is `challenge-findings-plan-pass11.json`; its signed lab risk authorization is revision 2 (`*.r2.*`, plan-complete, codegen and code-complete, expires 2026-11-19). Revision 1 files stay as history.
- **Upstream framework:** [`jonathan-vella/apex`](https://github.com/jonathan-vella/apex) `main`, with the lab risk authorization (#747, #748) and the review-verdict fix (#750). Contract: `tools/apex-recall/docs/risk-authorizations.md` in that repo.
- **Upstream issues found on the way:** [#751](https://github.com/jonathan-vella/apex/issues/751) pre-commit hook false positive, [#752](https://github.com/jonathan-vella/apex/issues/752) stale reviews after a sync, [#753](https://github.com/jonathan-vella/apex/issues/753) `validate:session-state`, [#754](https://github.com/jonathan-vella/apex/issues/754) `check-gate` pre-check and trust pins.
- **This folder:** the signing tools (`risk-signing/`), the SQL MI identity research (`research/`), a resume prompt (`resume-prompt.md`) and this guide.

## What the lab risk authorization covers

Step 4's review (`challenge-findings-plan-pass10.json`) still carries two `must_fix` findings. The owner accepted both as residual risk for a non-production lab. This is risk acceptance, not remediation, and the review stays `NEEDS_REVISION`.

| Finding | Risk |
|---|---|
| `a749666a` | The shared identity `id-sqlmi-directory` holds Graph read permissions and members can attach it to other resources. |
| `bc629836` | The public web app has no end-user authentication and its identity holds data-plane roles. End-user authentication was excluded from the archetype by an owner decision. |

The signed authorization permits Plan completion and CodeGen only. It never permits deployment. Each adopting team needs its own deployment authorization, expiry, cleanup owner and teardown verification.

## What does not move with the repo

These stay on the old device. Plan for each one.

| Item | Where | What to do |
|---|---|---|
| Signing private keys | `~/.apex-risk/private/` (`%USERPROFILE%\.apex-risk\private\` on Windows), 3 files | Copy them over a secure channel, then run `risk.mjs restore`. See [Keys](#keys). Never commit them or paste them into chat. |
| Kit settings | `.local/settings.json` in the kit repo (gitignored) | Copy it to the same place on the new device. It holds tenant and subscription values, so never commit or print it. |
| Trust file and pins | Inside the dev container, `~/.apex-risk/risk-trust.json`, plus two `export` lines in `~/.bashrc` | Regenerate with `risk.mjs trust` and pin again. |
| The working copy | A Docker volume on the old machine | Clone the branch again. Everything is pushed. |
| Copilot app sessions and their history | The old device | Not needed. This folder and the issues carry the state. |
| Azure CLI sign-in | The old device | Sign in again only when a live validation is approved. |

## Resume on the new device

1. Install Docker, VS Code with the Dev Containers extension, GitHub Copilot, Node 24 and Git.
2. Clone the CoE repo and check out `fix/university-52-60-wip`. On Windows, use **Dev Containers: Clone Repository in Container Volume**. A plain bind mount of a Windows checkout failed earlier because the Git pointer and file ownership are wrong inside Linux. On Linux or macOS a normal open should work, but this is unverified.
3. Let the repo's dev container finish its post-create steps. They install `apex-recall` and the tools. Check `apex-recall --help` works.
4. Add the Azure MCP mapping to `.vscode/settings.json` under `chat.mcp.serverSampling`. The key includes the workspace folder name, for example `"<folder-name>/.mcp.json: azure-mcp"` (upstream moved the MCP config from `.vscode/mcp.json` to a root `.mcp.json` on 2026-10-20), so it differs from the old device's `coe-linux-source`. The CoE prompt in [prompts.md](prompts.md) does this for you (Step 0.5).
5. Restore the signing keys (see [Keys](#keys)), then create the trust file and pins.
6. Send the prompt for the repo you are working in from [prompts.md](prompts.md). Each one first checks you are on the right branch and fixes it safely, then does read-only checks and stops.

## Keys

Three keys exist: `lab-kit-owner`, `lab-eligibility-reviewer` and `lab-rule-authority`. All are held by the owner, so the records show separate keys and principals, not separation of duties. Their public fingerprints are recorded in `risk-signing/settings.json` and in the signed records:

| Key | Public fingerprint |
|---|---|
| `lab-kit-owner` | `abb903b2b140163b` |
| `lab-eligibility-reviewer` | `af4b931d085ef615` |
| `lab-rule-authority` | `668346513c4aca95` |

### Restore the keys on the new device

1. On the old device, put a copy of the folder that contains `private\` and `public\` (the `.apex-risk` folder) in a place you can reach from the new device. Cloud-synced storage works as a temporary transfer point. Never put it in a Git repo, an issue, a PR or a chat.
2. On the new device, from the root of the kit repo (Node 24 required):

   ```powershell
   node docs/coe-correction/risk-signing/risk.mjs restore --from "<folder that contains private and public>"
   ```

   It checks that each private key matches its public key and the fingerprint above, refuses to overwrite a different existing key, and locks the private files to your account. Expect three lines ending in `restored and verified`. If it reports a fingerprint mismatch, these are not the keys that signed the records. Stop and do not generate new keys.
3. Delete the transfer copy, then empty the recycle bin of the sync service and of the device. Keep the keys only in `~/.apex-risk` (`%USERPROFILE%\.apex-risk` on Windows).
4. Create the trust file and pins for the container: `node docs/coe-correction/risk-signing/risk.mjs trust` prints the new `APEX_RISK_TRUST_SHA256`. Copy `out/risk-trust.json` into the container as `~/.apex-risk/risk-trust.json` (mode 600) and set the two `APEX_RISK_*` variables in `~/.bashrc`. The runbook has the exact commands. The trust file embeds timestamps, so its hash is new each time; pin the one you installed.
5. Check from a new container terminal: `env | grep -c APEX_RISK` prints `2`, then `apex-recall check-gate university --action codegen --json` reports `exception-authorized`.

### If the keys are lost

Key IDs are fixed, so new keys under the same IDs cannot verify the existing signatures, and Step 4's stored authorization would then fail revalidation. Do not improvise. Ask in the upstream repo how to re-issue records, and expect to re-sign everything at a new revision. This path is untested.

### Expiry and rotation

The trust file, authorization and approval are valid until 2026-11-19 (revision 2; revision 1 was valid until 2026-11-09). After that, re-sign at a new revision (see the runbook). That is also a good moment to generate fresh keys and update the fingerprints in `settings.json`, because new records signed by new keys replace the old ones.

## Finish the correction (done 2026-10-20)

These steps are complete and are kept as the record of what ran and in which order. For a repeat (for example after another upstream sync that changes the review protocol) the same sequence applies: a fresh review of unchanged inputs needs an owner override of the invocation ceiling; run the reviewer from the CoE container with `prior_findings` as an array, and run `record-review.mjs` in a later turn. In an agent terminal, run `apex-recall` gate commands through an interactive shell (`bash -ic ...`), because the trust pins load only from `~/.bashrc`.


These steps need the lab foundation. Redeploying it needs the owner's approval and a cost estimate first (about $4.63 per hour while the foundation and archetype are deployed, per the B14 runbook). Track it in #87.

1. Redeploy ALZ-lite, the datacenter and vending with the kit's scripts. Vending creates the spoke with the delegated `snet-sqlmi` subnet.
2. In the CoE dev container, run the 06b validate-only step. Confirm with the 06b agent's own rules whether it needs a separate authorization. The agent must not run anything that creates resources.
3. Re-emit `05-iac-handoff.json` through the owner path, never by hand. Check `node tools/scripts/validate-iac-handoff.mjs --tree-hash infra/bicep/university` matches the new handoff.
4. Sign revision 2 so that `code-complete` is authorized (see the runbook, "Later revisions"), install the new trust file and update the pin.
5. Complete Step 5 with the revision 2 authorization and approval. Commit, push, open a PR into CoE `main` and merge it.
6. Re-package `archetype/` in the kit from the new CoE commit with `Import-Archetype.ps1`, run the ID scan and confirm the tree hash matches. Drop the playbook self-grant for #60.
7. Tear down and confirm each resource group is gone.

The stale Step 1, 2 and 3.5 reviews also stop `00-handoff.md` from regenerating (see [#752](https://github.com/jonathan-vella/apex/issues/752)). That does not block the steps above.

## Rules that still apply

- Never hand-edit a review, a hash, the session state or a signed record. Never restamp a review.
- Do not repeat a review hoping for a different verdict. A review of unchanged bytes is a loop.
- Any change to the plan or its five supporting inputs makes pass10 stale and invalidates everything signed against it.
- No Azure operation without the owner's explicit approval.
