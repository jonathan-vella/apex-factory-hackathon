# Resume prompt for the CoE `university` correction

Send this to the default Agent chat in VS Code, attached to the CoE dev container on the branch `fix/university-52-60-wip`. It makes the agent verify the state read-only and then stop.

```text
Read-only. Change nothing, run no state-changing apex-recall command, no signing, no review and no Azure operation.
Context: project university in this repo. Step 4 is complete with plan_status EXCEPTION_AUTHORIZED under a signed lab risk
authorization (kit scope: plan-complete and codegen only). Step 5 is in_progress. The review challenge-findings-plan-pass10.json
still carries two accepted must_fix findings; that is risk acceptance, not remediation. Never edit a review, hash, state
file or signed record, and never set or change the APEX_RISK_* variables.
1. Report the branch, `git log --oneline -6` and `git status --short`.
2. Report `apex-recall show university --json`: current_step, each step status, plan_status, and the keys under risk_authorizations.
3. In a NEW terminal report `env | grep -c APEX_RISK` (expect 2) and the status line of
   `apex-recall check-gate university --action codegen --json`. If the pins are missing or the gate is blocked, say so and stop.
4. Report sha256 of agent-output/university/challenge-findings-plan-pass10.json (expect
   f78b1970c02027d37fa8acc2eed88e03f62a6427f938f7e2debcd9dc03e7b5e5) and of agent-output/university/risk/risk-authorization.json
   (expect 1439357210aa08dd24b2d2cd151a2ea0a800f8bdada46ec433828995868914fa).
5. Run `node tools/scripts/validate-challenger-findings.mjs --verify-cache agent-output/university/challenge-findings-plan-pass10.json`
   and report the result.
6. Read docs/coe-correction/README.md in the kit repo (jonathan-vella/apex-factory-hackathon) and tell me which of its
   "Finish the correction" steps is next and what it is waiting for.
Then stop.
```

If any value does not match, stop. Do not repair it. Compare with `README.md` in this folder and decide with the owner.
