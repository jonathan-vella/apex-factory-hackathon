# Lab risk signing runbook

These tools create the signed records that let APEX complete Plan approval and CodeGen while a reviewed `must_fix` finding is accepted as a lab risk. Run them on the owner's machine, never inside an agent container. The signing keys never leave `~/.apex-risk/private` (`%USERPROFILE%\.apex-risk\private` on Windows) and the scripts never print them.

The scripts were tested against the real upstream evaluator (`tools/scripts/evaluate-risk-authorization.mjs` in `jonathan-vella/apex`) with synthetic data: `node test-e2e.mjs <path-to-an-apex-clone>` (Linux, WSL or macOS, with `ajv` installed in that clone). The evaluator needs POSIX file ownership checks, so it does not run on native Windows.

Replace `<container>` with the dev container's name (`docker ps`). Commands use PowerShell syntax with `docker`; adapt quoting for bash.

## Files

| File | Purpose |
|---|---|
| `settings.json` | The drafts to review and own: classifications, rationale, residual impact, exception text, actions, validity. |
| `risk.mjs` | `keygen`, `evidence`, `trust`, `sign eligibility`, `sign exception`, `sign authorization`, `sign approval`. |
| `collect-facts.mjs` | Read-only. Run in the container to print review hashes and metadata. |
| `test-e2e.mjs` | End-to-end test against the real evaluator. |

## First issue: revision 1 (already done for `university`)

Revision 1 authorized `plan-complete` and `codegen`. These are the steps, for reference or a repeat.

1. **Read `settings.json`.** You are the signer. Edit anything that is not true.
2. **Keys, once:** `node risk.mjs keygen`. It refuses to overwrite existing keys.
3. **Facts from the container:**

   ```powershell
   docker cp collect-facts.mjs <container>:/tmp/collect-facts.mjs
   docker exec -u vscode -w /workspaces/<repo> <container> bash -c "node /tmp/collect-facts.mjs university > /tmp/facts.json"
   docker cp <container>:/tmp/facts.json .\facts.json
   ```

   The must-fix IDs in `facts.json` must match the keys under `findings` in `settings.json`. The script refuses to continue otherwise.

4. **Evidence, trust and signatures:**

   ```powershell
   node risk.mjs evidence --facts facts.json      # read out\risk\*.md
   node risk.mjs trust                            # prints APEX_RISK_TRUST_SHA256
   node risk.mjs sign eligibility   --facts facts.json
   node risk.mjs sign exception     --facts facts.json
   node risk.mjs sign authorization --facts facts.json
   ```

   Each step prints exactly what it signs. Type `SIGN` to confirm. Do not rerun `trust` after you pin it: the file embeds timestamps and the hash changes.

5. **Copy the evidence into the workspace** (`agent-output/university/risk/`) and make it owned by the container user. Compare the SHA-256 values on both sides.
6. **Install the trust file outside the workspace** (for example `~/.apex-risk/risk-trust.json`, owner-only, mode 600) and pin it for terminals:

   ```bash
   export APEX_RISK_TRUST_CONFIG=/home/vscode/.apex-risk/risk-trust.json
   export APEX_RISK_TRUST_SHA256=<pin printed by trust>
   ```

   Put the two lines in `~/.bashrc`. A non-interactive shell (`docker exec ... bash -lc`) does not load them, and a terminal opened earlier needs restarting. Pass them with `docker exec -e` for one-off checks. See jonathan-vella/apex#754.

7. **Dry-run the authorization** with the evaluator (read-only, before you approve):

   ```bash
   echo '{"root":"/workspaces/<repo>","project":"university","action":"plan-complete","reviews":["agent-output/university/challenge-findings-plan-pass10.json"],"preserved_reviews":["agent-output/university/challenge-findings-plan.json"],"authorization":"agent-output/university/risk/risk-authorization.json","require_approval":false}' | node tools/scripts/evaluate-risk-authorization.mjs
   ```

   Expect `exception-authorized` with the findings listed as `risk-accepted`. Repeat with `"action":"codegen"`.

8. **Sign your separate approval** (`node risk.mjs sign approval --facts facts.json`), copy it in, then complete the step from an interactive container terminal:

   ```bash
   apex-recall complete-step university 4 --plan-review agent-output/university/challenge-findings-plan-pass10.json --plan-review-reason "<reason>" --risk-authorization agent-output/university/risk/risk-authorization.json --risk-approval agent-output/university/risk/risk-gate-approval.json --json
   ```

   It is atomic and fails closed. Before `codegen`, run `apex-recall check-gate university --action codegen --json`.

## Later revisions: authorize `code-complete` (needed to complete Step 5)

Completing Step 5 checks the `code-complete` action. The revision 1 records do not list it, so `complete-step university 5` and `transition 5 -> 6` block until a new revision exists. A kit authorization can never list `deploy`.

New IDs and file names are used so the revision 1 files stay byte-identical (the saved state revalidates them):

```powershell
$rev = @('--revision','2','--actions','plan-complete,codegen,code-complete')
node risk.mjs evidence --facts facts.json @rev
node risk.mjs sign eligibility   --facts facts.json @rev
node risk.mjs sign exception     --facts facts.json @rev
node risk.mjs sign authorization --facts facts.json @rev
node risk.mjs trust @rev                                     # new pin
node risk.mjs sign approval      --facts facts.json @rev
```

Files get a `.r2` suffix (`risk-authorization.r2.json`). The new trust file replaces the old one in the container and the pin in `~/.bashrc` changes. The test shows revision 1 records stay valid under the new trust file. Then:

```bash
apex-recall complete-step university 5 --risk-authorization agent-output/university/risk/risk-authorization.r2.json --risk-approval agent-output/university/risk/risk-gate-approval.r2.json --json
```

Regenerate `facts.json` first if the review changed. If the plan or any of its five supporting inputs changed, pass10 is stale: you need a fresh review and new records, not a new revision of these.

## Limits

- All three signing identities are the owner. The records say so. This is an audit trail for a lab, not separation of duties.
- The authorization covers Plan completion, CodeGen and (from revision 2) code-complete. Deployment needs a separate adopter authorization with their own tenant, event, expiry, cleanup owner and teardown evidence.
- Records and trust expire 30 days after signing (`validity_days` in `settings.json`).
