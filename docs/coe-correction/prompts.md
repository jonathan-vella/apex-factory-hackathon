# Prompts for resuming on a new device

Two prompts, one per repo. Each starts by checking the branch and fixing it only in safe ways (clean tree, fast-forward only). They never discard work. Do the key restore in [README.md](README.md#keys) first if you will use the CoE prompt.

## 1. Kit repo (`jonathan-vella/apex-factory-hackathon`)

Paste into a new Agent session opened in the kit repo.

```text
Step 0, before anything else: make sure we are on the right branch.
- Run `git fetch origin`, `git status --short` and `git branch --show-current`. Never work on main directly.
- The work branch for this task is `docs/archetype-lab-risks`, created from the latest origin/main.
- If the working tree is clean: if that branch does not exist, run `git switch -c docs/archetype-lab-risks origin/main`. If it
  exists, switch to it and run `git merge --ff-only origin/main` (if the fast-forward is refused, stop and tell me).
- If the working tree has uncommitted changes, stop and show me `git status --short`. Do not stash, reset, clean or discard.
- Report the branch and `git log --oneline -3` before continuing.

Settings: if `.local/settings.json` is missing, tell me. I restore it myself from my transfer copy. Never print, commit or paste
its contents (it holds tenant and subscription values), and check `git check-ignore .local/settings.json` prints the path.

Context: the CoE "university" correction is parked until the lab foundation is redeployed. Read docs/coe-correction/README.md
(status, what exists where, what does not move with the repo), then docs/backlog/AGENTS.md for the safety rules (it only governs
backlog items, but its rules on secrets, Azure, deletion and asking apply to everything here).

Task: do issue #88, "Document the accepted lab risks and adopter obligations for the archetype". Docs only.
- Read the issue body, docs/coe-correction/README.md and docs/coe-correction/research/sqlmi-identity-options.md for the facts.
  Do not invent facts, numbers or approvals.
- Find where an adopter or facilitator reads first (the archetype README, the playbook, facilitator material, matching site
  pages). One short section plus links, no repetition.
- CAUTION: files under archetype/ that were copied from the CoE repo are byte-checked by Import-Archetype.ps1. Do not edit those.
  Before touching anything under archetype/, check whether it is kit-authored. If unsure, stop and ask me.
- The wording must say: risk acceptance, not remediation; a kit-level authorization never covers an adopter's deployment; tenant
  authorization, expiry, cleanup owner and teardown verification belong to the adopting team; production reuse needs its own review.
- Public repo: no tenant, subscription or object IDs, account names, secrets or real IPs.
- Conventional one-line commit, open a PR, do not merge it. Run `npm run lint:md` and `node scripts/check-content-invariants.mjs`
  and report the results.
- No Azure operations of any kind. Stop and ask before doing anything the issue does not cover.

Afterwards, report in 10 lines or fewer, and say whether #87 (foundation redeploy) is ready for my cost approval. Do not start #87,
#52, #60 or #40 (B14).
```

## 2. CoE repo (`jonathan-vella/apex-factory-coe`)

Open the repo in its dev container first, then paste into the default Agent chat.

```text
Step 0, before anything else: make sure we are on the right branch.
- Run `git fetch origin`, `git status --short`, `git branch --show-current` and `git log --oneline -6`.
- The work branch is `fix/university-52-60-wip`. Its HEAD must be commit 778d8d2 or a descendant of it
  (`git merge-base --is-ancestor 778d8d2 HEAD`).
- If the working tree is clean and we are on another branch: run `git switch fix/university-52-60-wip` (if it does not exist
  locally, `git switch -c fix/university-52-60-wip --track origin/fix/university-52-60-wip`), then `git merge --ff-only
  origin/fix/university-52-60-wip`. If the fast-forward is refused, stop and tell me.
- Expected, harmless leftovers: a modified tools/scripts/_data/avm-module-cache.json and an untracked
  agent-output/university/00-session-state.json.lock. Report them, do not touch them. Any other change: stop and show me.
- If 778d8d2 is not an ancestor of HEAD, or origin/main has moved on, stop and tell me. Do not merge main yourself.
- Never use reset --hard, clean, checkout -- , stash drop, force-push or --no-verify.
- Report the branch and `git log --oneline -3` before continuing.

Then read-only. Change nothing, run no state-changing apex-recall command, no signing, no review, no commit and no Azure operation.
Context: project university. Step 4 is complete with plan_status EXCEPTION_AUTHORIZED under a signed lab risk authorization (kit
scope: plan-complete and codegen only). Step 5 is in_progress. The review challenge-findings-plan-pass10.json carries two accepted
must_fix findings: risk acceptance, not remediation. The code for #52 and #60 is committed. What is left needs a live lab
foundation, tracked in jonathan-vella/apex-factory-hackathon#87. Never edit a review, hash, state file or signed record. Never set
or change APEX_RISK_* variables, and never read or print any key file.

1. Do every check in docs/coe-correction/resume-prompt.md of jonathan-vella/apex-factory-hackathon (fetch it from GitHub) and
   report each result. Expected: Step 4 complete, plan_status EXCEPTION_AUTHORIZED, Step 5 in_progress, risk_authorizations with
   plan-complete and codegen, check-gate codegen exception-authorized, pass10 verify-cache clean, both SHA-256 values match.
2. If `env | grep -c APEX_RISK` in a NEW terminal is not 2, or ~/.apex-risk/risk-trust.json is missing, do not create or fix it.
   Tell me to follow "Restore the keys" in docs/coe-correction/README.md and stop.
3. Report whether the dev container tools are the pinned versions (az 2.90.0, gh 2.101.0, pwsh 7.6.6, azd 1.34.1); report
   differences only.
4. Tell me which "Finish the correction" step is next and what it is waiting for. Then stop and wait for me.

Rules for any later step, so you do not rediscover them:
- Use a NEW terminal for apex-recall gate checks (trust pins load from ~/.bashrc in interactive shells only). Run complete-step
  from an interactive terminal, never through docker exec.
- Do not repeat reviews of unchanged bytes. The reviewer worker (GPT-6 Luna) must not be asked to verify its own model; verify from
  the debug log instead. A worker may repair its own local script defects. Planner model override: GPT-6.1 Sol.
- A commit touching infra/bicep fails the iac-security-baseline hook for the approved public web app (jonathan-vella/apex#751).
  First run `node tools/scripts/validate-iac-security-baseline.mjs --public-web-app infra/bicep/university/modules/web-app.bicep`;
  if it passes, commit with `LEFTHOOK_EXCLUDE=iac-security-baseline git commit ...`. Branch prefix: fix/.
- No Azure operation, including validate-only, without my explicit approval for that specific operation.
```
