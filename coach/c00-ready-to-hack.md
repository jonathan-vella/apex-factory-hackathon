# C0 answer key: Ready to hack

> [!WARNING]
> Coach material. This page has the answers to C0. Attendees work it out from the scripts and the pre-work instructions.

C0 is pre-work: members do it before the event, on their own time, against their own workload subscription. There's no coach in the room for this one, so the evidence needs to be unambiguous when you review it at T-3 or on the morning of day one.

## Expected evidence

- `Test-Preflight.ps1` output: every automated check green. A member who skipped a manual check (RBAC, MFA, GitHub Copilot policy, APEX runtime access) usually surfaces later in C2 or C5 — ask them to re-run preflight if C5 behaves oddly.
- `Test-Datacenter.ps1` output: all green, including the perf kit's planted objects and data present on `vm-app01`'s SQL Server (this is what C9 depends on later — if it's missing now, the perf kit needs resetting before C9).
- The Arc resource for `vm-app01` showing Connected, with the SQL Server extension installed and the instance listed.
- A screenshot or export of the first Arc migration assessment. They don't need to have acted on it — C3 is where that happens.

## Model answer

1. `./scripts/Test-Preflight.ps1 -Fix`, then review the manual-check list it prints and confirm each one.
2. `./scripts/Deploy-Datacenter.ps1 -MemberIndex <n>`.
3. `./scripts/Connect-DatacenterArc.ps1 -MemberIndex <n>` — this is the kit's only Arc onboarding path; there's no portal fallback, by design (owner decision 2026-10-02).
4. In the Arc resource's SQL Server blade, start (or review) the migration assessment.
5. `./scripts/Test-Datacenter.ps1 -MemberIndex <n>`.
6. Stop both VMs (`vm-app01`, `vm-dev01`) when not actively working.

## Common mistakes

- Running preflight once and not re-running `-Fix` after resource provider registration (which takes up to 15 minutes to propagate) — leaves a false red.
- Trying a manual Arc onboarding through the portal "just to see" — this works but produces a differently-named Arc resource that later scripts (`Test-Datacenter.ps1`, the migration assessment lookups) won't find. Redo with the script if this happened.
- Turning Azure Hybrid Benefit off "to compare" and forgetting to turn it back on — it should stay on throughout.
- Leaving both VMs running between pre-work sessions — not a correctness problem, but worth a reminder since it's billing for nothing.

## Partial credit

- Preflight and datacenter deployed, but Arc onboarding incomplete by the event's start: partial credit, and the member should prioritize finishing onboarding in the first break of day one rather than falling behind in C0 forever.
- No access to the first migration assessment (for example, Arc's own assessment feature is still initializing): accept `Test-Datacenter.ps1`'s green output as sufficient evidence, and have the member pull the assessment first thing in C3.

## Reset

`./scripts/Deploy-Datacenter.ps1 -MemberIndex <n> -Force` redeploys cleanly if something is unrecoverable; re-run Arc onboarding afterward.
