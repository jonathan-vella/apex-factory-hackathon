# B24: Apply the October 2026 site review

| Field | Value |
|---|---|
| Issue | T01 #190 · T02 #191 · T03 #192 · T04 #193 · T05 #194 · T06 #195 · T07 #196 · T08 #197 · T09 #198 · T10 #199 |
| Milestone | Site review, before the site is shared |
| Type | Agent. Owner decisions recorded on 29 October 2026 (below); one owner-approved pipeline change (T01, requirement 1) |
| Depends on | Nothing |
| Unblocks | Sharing the site; the dry run |
| Effort | Mostly small edits: 260 of 280 findings are effort S, 19 M, 1 L |
| Cost | None, except one lab run of the teardown stage for T01 requirement 1 |
| Teardown | Only for that lab test |
| Source | `docs/review/2026-10-29/`: the report and the findings register |

## Kickoff prompt

**Copilot cloud agent (default):** assign the ten `site-review` issues to Copilot one at a time, in order (T01 to T10), and merge each PR before you assign the next. The issue body carries the rules.

**VS Code agent mode or Copilot CLI:** paste this from the repo root, one theme per run. Change `T01` to the next theme each time.

```text
Execute backlog item B24, docs/review/2026-10-29/factory-site-copilot-spec.md: the October 2026
site review, in ten themes (T01 to T10), each with a GitHub issue labelled site-review.

First read AGENTS.md, .github/workflows/AGENTS.md, docs/archive/backlog/AGENTS.md and the whole
spec. The Decisions table, the code-change rule, "Stop and ask if", the Deferred list and the
appendix are binding. For every finding ID a requirement cites, read its row in
docs/review/2026-10-29/factory-site-review-findings.md: its Evidence, Problem and Fix are part of
the requirement unless a decision overrides them.

Work on one theme only: T01. Use one branch and one draft PR, linked to the theme's issue with
"Closes #<number>", and the commit message the spec gives for the theme.
- Change docs, the sidebar config, frontmatter and user-facing strings only. The one logic
  change is T01 requirement 1 in .github/workflows/platform.yml.
- Keep every existing page URL. Don't change points, timings or the event order unless the
  theme says so.
- Never run, dispatch or push anything that deploys or deletes in Azure, and never create a
  ci-test/* branch. The owner runs the T01 CI-lab tests.
- Before you open the PR, run the Verify commands that apply, plus PSScriptAnalyzer on any
  changed script and actionlint on a changed workflow.
- In the PR description, list each finding ID as Closed or Left open (with the reason), the
  decisions applied by number, the checks you ran, and Follow-ups for anything that needs code.
Stop when the PR is open and wait for the owner's review.
```

## Outcome

- No documented command can make a team lead's run delete the team's environment, and the workflow refuses to.
- Every pre-event page sends people to the team lead, then the event owner; the event owner and tech lead are defined.
- Requirements lists every commitment a partner must secure before T-14, with cost.
- Each fact is stated once and matches its source: the journey map matches `challenges.json`, the agenda lives on Event overview, timings and the member-index rule are stated once.
- The sidebar and pager follow the journey (before, during, after the event); attendees can't page or search into coach answer keys by accident; every guide and prompt links to its challenge and back.
- A coach can run both days from the Coach section alone.
- Every challenge's evidence matches its rubric rows and scripts, and every recovery path works.
- Tear down is safe, complete and linked from the end of the journey.
- Time-sensitive pages carry a validated-on date and current Learn references.
- One term per concept, and a glossary that covers the site.

## Decisions (29 October 2026)

The owner settled every open question from the review. Numbers match the report's section 7.

| # | Topic | Decision | Theme |
|---|---|---|---|
| 1 | Teardown guard | Fail closed in the lead repo: `member`, `teardown` and `all` need `members`; team teardown needs `members=all` and a confirm input. The one logic change, tested in the CI lab. | T01 |
| — | Code changes | Docs, sidebar config and frontmatter, plus text-only edits to user-facing strings in scripts, the workflow and site components. No other logic changes; anything that needs code is deferred. | All |
| 2 | Exemptions | "None needed" is valid evidence, with one deferred-work entry for the datacenter. | T07 |
| 3 | GitHub plan | GitHub Free works (owner-tested on private repos, October 2026); add a Troubleshooting entry for a plan error. | T03 |
| 4 | Copilot CLI | Optional, only for the playbook's CLI path. | T03 |
| 5 | Upgrade dashboard | Pin the validated versions and add one fallback line; owner re-tests before the dry run. | T09 |
| 6 | ALZ demo | Fold into the 08:30 kickoff as slides or a short recording. | T06 |
| 7 | APEX 07b | Works, but not supported at events. | T04 |
| 8 | Teardown default | Delete `rg-management` and the Graph grant unless the tenant will be reused. | T08 |
| 9 | Privileged Role Administrator | The team lead books; the event owner handles escalations. | T02 |
| 10 | Docker | Licence note only. | T03 |
| 11 | Rollback after cutover | Out of scope at the event; say so and name what a customer would do. | T07 |
| 12 | Curveball scoring | The team lead's C2 evidence only; nobody's points change. | T07 |
| 13 | OpenTelemetry | Keep the Azure Monitor distro; add a note. | T09 |
| 14 | Templates | Keep both copies; fix both. | T04 |
| 15 | Coach pages in search | Label coach page titles "(coach)". | T05 |

**Code-change rule.** Change docs, the sidebar configuration and page frontmatter, plus user-facing strings in scripts, the workflow and site components (prompts, run summaries, labels). Don't change logic anywhere, except T01 requirement 1. If a fix needs code, leave it out of the diff and list it under Follow-ups in the PR. Known cases are under "Deferred" below.

**Still with the owner (🧑 HUMAN):** approve each CI-lab run for T01 requirement 1; re-test the GitHub Copilot upgrade path before the dry run and update `versions.md`; add the full-ALZ slides or recording to the kickoff deck. Optional: if your own tests used a personal account rather than an organization, run Step 1.5 once in a GitHub Free organization before the pilot; GitHub's docs say Free organizations can't configure environments on private repos.

## Before you start

1. 🧑 HUMAN: the owner copies the five review files (this spec, the issues, the findings register, the report and the review brief) into `docs/review/2026-10-29/` on `main`.
2. `npm run check` passes on `main`.
3. Read the report's sections 2 (themes), 3 (proposed information architecture) and 7 (decisions).
4. Read the rules in AGENTS.md on pipeline changes, identifiers and PRs. T01 requirement 1 is a pipeline change.

## Requirements

Work theme by theme. The decisions above are settled: apply them, don't reopen them. 🧑 HUMAN marks a step only the owner can do. Each requirement cites findings; their Fix column says how, within the code-change rule. The last requirement of each theme covers that theme's remaining P2 and P3 findings, so every finding in the register is covered.

### T01 Lead-repo safety: teardown, members filter, vending reruns

1. Fail-closed guard (decided 29 Oct 2026; the one logic change in this item, owner-approved). In the plan job of `.github/workflows/platform.yml`, for `workflow_dispatch` runs in the lead profile: the `member`, `teardown` and `all` stages need an explicit `members` input, either one or more indexes or `all` (expanded from `MEMBER_INDEXES`). With no value, fail in the plan job before any Azure call, with a message that shows both forms. `teardown-team` runs only when `members` is `all` and a new boolean input `confirm-team-teardown` is `true`. Pushes to `ci-test/*` branches and member-profile runs behave as today. Also fix the header comment that says vending waits for a coach (text only). Test in the lab named in `.local/ci-lab.json`, never the owner's live lab, each run approved by the owner: (1) a lead `teardown` with no `members` fails in plan; (2) `-f members=<n>` removes only that member and skips `teardown-team`; (3) a `ci-test/teardown-*` push still works; (4) `-f members=all -f confirm-team-teardown=true` at the next planned lab teardown. Link the runs in the PR. (DEP-01, CRF-01, DEP-16)
2. Once requirement 1 is merged, wherever a page shows `gh workflow run platform.yml -f stage=member` or `-f stage=teardown`, show two forms: "In your own repo (member)" and "In the team lead's repo: add `-f members=<your index>`". At T+2 the team lead's full teardown is `-f stage=teardown -f members=all -f confirm-team-teardown=true`, plus `-f include-management=true` unless the event owner will reuse the tenant (decision 8). Pages: `deploy/member-steps.mdx` (including "If you need to start over" and the `no-hybrid-benefit` command), `deploy/tear-down.mdx`, `reference/troubleshooting.md` (Arc entries), `reference/azure-hybrid-benefit.md`. Add one rule to the Deploy overview: "Team leads: your repo runs `member` and `teardown` only for the members you name." (DEP-02, CRF-09)
3. Add a team-lead warning to every start-over path: never run a full teardown in the lead repo before T+2; to start over, use `-f members=<your index>` or ask the event owner for a coach repair. Make the after-Arc recovery the same on `deploy/member-steps.mdx`, `reference/troubleshooting.md`, `reference/azure-hybrid-benefit.md` and `coach/readiness.md`, and say that member teardown also removes `rg-spoke` and the archetype, so the team lead must run vending for that member again. (DEP-01, CRF-01, DEP-07, CRF-13, DEP-20, CRF-27)
4. Describe vending failures as the script behaves: it stops at the first member who isn't ready; earlier members are vended but not restarted, exempted or probed; later members aren't vended. The fix is to correct the cause and re-run vending for all members (safe to repeat); use `-f members=<n>` only for members that phase 3 names. Pages: `deploy/vending.mdx`, `getting-started/event-overview.mdx`, `coach/readiness.md`, `facilitator/agenda.md`. (DEP-03, CRF-07, START-07)

### T02 Support model and roles before and during the event

5. Before day one, every escalation is member → team lead → event owner. Replace pre-event "tell your coach" / "ask your coach" / "a coach can help" on `getting-started/requirements.mdx` (three places), `reference/troubleshooting.md` (preflight, quota, Arc timeout and the closing line), `guides/alz-lite.md`, `guides/ghcp-upgrade.md` ("Before the event, ask your team lead; on event days, ask your coach"), and `deploy/set-up-your-repo.mdx`. In `scripts/Initialize-Settings.ps1` (text only), change "from your coach" to "from your team lead" and drop "in C2". Keep coach wording for event-day contexts. (START-02, DEP-04, DEP-19, CRF-08, GDE-10, DEP-29, DEP-33)
6. Add the event owner to `getting-started/roles.md` and the glossary: confirms rosters and member indexes, handles escalations (for example when the team lead can't find a Privileged Role Administrator) and owns clean-up. Add the escalation path. (START-05)
7. Define the tech lead (who gives the 08:30 kickoff, from which organization) in Roles and the glossary, and say once that the workflow and scripts call the team lead the "platform lead". (START-15, START-41, CRF-36)
8. Remove what's left of the old readiness approval (text only): the member-stage run summary in `platform.yml` and the C5 coach sheet say the team lead's vending stage checks Arc status automatically. (DEP-16, CRF-14)
9. The team lead books the Privileged Role Administrator for T-7; the event owner only handles escalations (decision 9). Say so on Step 2, in the ALZ-lite guide (replace "a coach can help" with "if you can't find one, escalate to your event owner"), in the team lead row of Requirements and in `facilitator/guide.md`, which today gives the booking to the event owner. (GDE-09, START-35)
10. Apply the Fix column of the remaining T02 findings (P2 first, then P3), within the code-change rule; list any that need code under Follow-ups: CHA-33, START-38.

### T03 Prerequisites, tenant commitments and cost up front

11. Add rows to `getting-started/requirements.mdx`, each with who grants it and by when: (a) a dedicated non-production tenant and dedicated, empty subscriptions, and what the kit changes in them (moves them under `mg-factory-corp` with Deny policies; Foundational CSPM only, with every paid Defender plan off); (b) GitHub plan (decision 3): GitHub Free works, because the owner ran the pipeline end to end from private repos on a free plan in October 2026; required reviewers need a paid plan, so on Free the gate is write access (keep the repo private and the writers few); (c) Copilot (decision 4): a seat, plus org policies for agent mode and MCP servers (off by default); Copilot CLI is optional, only for the playbook's CLI path; (d) Owner at Tenant Root in place by T-14, because pipeline setup in Step 1.5 needs it; (e) org rights to create private repos from a template, and an Actions policy that allows `actions/checkout`, `actions/upload-artifact` and `azure/login`; (f) Azure Hybrid Benefit eligibility, linked to `/reference/azure-hybrid-benefit/`; (g) Docker Desktop (decision 10): a licensing note only ("organizations with 250 or more employees or $10M or more revenue need a paid Docker subscription; confirm yours before T-14"); (h) VS Code: latest stable, 1.106 or later; (i) the network allowlist, pointing to GitHub's and VS Code's own lists. Repeat (a) as a caution on Step 2 and Step 4. (START-04, DEP-10, DEP-05, START-03, DEP-09, START-14, START-13, START-12, START-10, START-11)
12. Make the Copilot CLI optional everywhere it's asked for: `scripts/Test-Preflight.ps1`'s MANUAL reason (text only), check 4 on Step 1 and `facilitator/guide.md`. Add a Troubleshooting entry: if Step 1.5 can't create the `gh-lab` environment or set its secrets, check the org's GitHub plan (GitHub's docs list Pro, Team or Enterprise for environments in private repos). (START-03, DEP-05)
13. Add a Cost row to Requirements (per-member and per-team hourly figures, billing from T-7 to T+2, link to `/reference/cost/`). On the Cost page: date the prices, add when each charge starts and stops (foundation from T-7, datacenter from Step 3, archetype from C5, all until teardown), correct the no-Hybrid-Benefit delta (it changes `vm-app01` only), and publish the 3-, 4- and 5-member totals. Link Cost from Requirements, the Step 3 cost hint and Tear down. (START-09, CRF-24, CRF-25, CRF-11, CRF-30, CRF-40)
14. Fix the Windows 11 Hybrid Benefit statement on the Azure Hybrid Benefit page and Step 1 to match Learn (per-user licences). (CRF-26, DEP-31)
15. Apply the Fix column of the remaining T03 findings (P2 first, then P3), within the code-change rule; list any that need code under Follow-ups: DEP-34, DEP-35, START-17, START-37.

### T04 Single source of truth for facts and data

16. Correct the C2 entry in `site/src/components/JourneyMap.astro` in place (scope Member, 45 minutes, 15 points); no refactor. In the PR, show that every JourneyMap entry matches `challenges.json`. (START-01)
17. One agenda: move the Day 1 and Day 2 tables into `getting-started/event-overview.mdx`, keep the breaks, remove the copy from About, and update links that point to `/about/#agenda`. (START-18, START-20)
18. One member-index rule, said the same way on Step 1, Roles and Kit at a glance, and in the script prompts (text only): "assigned by the team lead; scripts accept 1 to 20; teams use 1 to 5; the team lead is 1". Add a Step 1 sub-step, before 1.4, where the team lead assigns and shares indexes. (DEP-08, DEP-43, START-27, DEP-33)
19. One timing table for the stages (in How it works); other pages link to it. Fix the script text that contradicts the pages (text only), for example the setup script's "Then the foundation" at T-14 and vending's "the datacenter comes before ALZ-lite". (DEP-22, DEP-44, DEP-17)
20. Stop copying the playbook into the prompts: link to playbook anchors instead, and align the model guidance with the playbook (balanced model to assess, most capable to plan). (GDE-03, GDE-04, CHB-25)
21. Resolve the remaining contradictions: persona names in C1 versus the customer story (CHA-05); whether assessors read `vm-dev01-work` (CHB-06); when members get the shared services subscription ID (CHA-14). APEX 07b (decision 7): `archetype/README.md` says the path works but isn't supported at events and coaches won't help with it; the APEX guide keeps azd as the path. (GDE-13)
22. Templates stay in two identical copies (decision 14): every template fix in this item lands in both `templates/attendee/` and `templates/team/templates/`.
23. Apply the Fix column of the remaining T04 findings (P2 first, then P3), within the code-change rule; list any that need code under Follow-ups: CHA-23, CHA-37, CHB-18, CHB-21, CHB-40, CHB-43, DEP-30, GDE-27, START-23, START-26, START-36.

### T05 Navigation and information architecture

24. Apply the proposed sidebar in the report, section 3, in `site/astro.config.mjs` and page frontmatter (`sidebar.order`, labels): Getting started reordered; How it works before Step 1; a new "After the event" group with Tear down; Guides and Prompts in order of use (Prompts by `sidebar.order` only, labels without the repeated "VS Code:" prefix); Reference with Troubleshooting first; Coach last. Don't change URLs. (START-16, START-30, DEP-36, GDE-32, GDE-33, GDE-39, LEAD-01)
25. Fix the pager at section boundaries: `next: false` on About; Step 4's next is the Challenges overview; C10's next is Tear down; Tear down has no next. Give each landing page a distinct label ("Deploy overview", "Challenges overview" and so on). (LEAD-01, LEAD-02, LEAD-03, CHA-24)
26. Make links two-way: every prompt page opens with "Used in Cn, requirement m" and a link; the prompts index links its When column; C2 links the ALZ-lite guide and the naming and IP plan; C3 links the Arc guide; C5 links the APEX guide from "Where to work"; the GitHub Copilot upgrade guide links C7, C8 and C9; C3, C4 and C5 end with a "Next" line. (GDE-06, GDE-07, CHA-32, CHA-39, GDE-31, CHB-45)
27. Link Tear down from C10 and from a new "After the event (T+2)" section in Event overview and Roles; link Troubleshooting from every Deploy step and from challenge hints. (START-08, CRF-30, DEP-39)
28. Fix the anchors that land in the wrong place: the playbook's two `#set-up-vm-dev01` links become `#33-set-up-vm-dev01`; the GitHub Copilot upgrade guide links 3.3, not 3.4; C3 links 3.2. List Steps 1 to 4 in order, including vending, on the Getting started overview. (GDE-41, CHB-11, GDE-11, CHA-35, START-06)
29. Label coach pages instead of hiding them (decision 15): end the H1 of every coach source (`coach/*.md`, `facilitator/agenda.md`, `facilitator/automation-map.md`) with "(coach)", so search results show it. The loader strips " answer key" but keeps the label. (LEAD-09)
30. Apply the Fix column of the remaining T05 findings (P2 first, then P3), within the code-change rule; list any that need code under Follow-ups: DEP-08, DEP-17, CHA-22, CHA-36, CHB-20, CHB-23, CHB-24, CHB-42, GDE-25, GDE-26, GDE-42, GDE-43, GDE-44, START-19, START-33.

### T06 Coach section: run both days from the site

31. Publish the coach material without code changes. The coach loader renders every `coach/*.md` file, so move `facilitator/curveballs.md`, `facilitator/apex-demo.md` and `facilitator/scoreboard.md` into `coach/` (they appear at `/coach/curveballs/`, `/coach/apex-demo/` and `/coach/scoreboard/`). Move the rubric's "Scoring rules", "Badges" and "Challenge bonus tasks" sections into `coach/scoreboard.md`; leave the base-points table and the `### Cn —` evidence sections in `facilitator/scoring-rubric.md`, which the loader and the content check read, and update the rubric's opening line to say where the rules now live. Update every link to the moved files (`coach/c07-migrate-and-go-live.md`, `facilitator/cleanup.md`, `facilitator/guide.md`, and the moved files' own relative links) and add the three pages to the Coach sidebar. Add a 10:15 curveball row to the agenda and a curveball section to the C2 sheet. Link the coach sections of `facilitator/guide.md` (lifeline handout, escalation table, kickoff duties, coach ratio) from the agenda page. Without a loader change, other coach pages can't link to the new pages as site routes: point to the sidebar entry instead of linking. (CRF-03, CRF-04, CRF-05, CRF-20)
32. Add Lifelines to the Coach sidebar, and a Lifelines section (L1 to L4, the 15-of-30 cap, how to record use) to the C6 sheet. (CRF-06, CRF-17)
33. Work around the two loader bugs in content: reword the C2 sheet's bonus line to "Up to 5 bonus points (member, under the shared 30-point cap)" so `/coach/` shows it, and on the readiness page put the audience note in a plain paragraph before the leading alert so the loader doesn't strip it. (CRF-10, CRF-12)
34. Order and name the Coach group as in the report: Coach overview, Two-day agenda, Readiness check, C1 to C10, Lifelines, Scoreboard and badges, Curveballs, APEX demo script, Automation map, Repair: deploy with scripts. Use "Readiness check" everywhere, and "attendee" or "member" rather than "participant" in coach sources. (CRF-18, CRF-19, LEAD-07)
35. Fold the full-ALZ demo into the 08:30 kickoff (decision 6): reword the ALZ-lite guide ("A full Azure Landing Zone, as the portal accelerator deploys it, adds the following") with a Learn link; update `facilitator/guide.md`'s coach role, the agenda's kickoff row and the "Full ALZ (coach demo)" column in `infra/foundation/README.md`. 🧑 HUMAN: the owner adds two or three slides (or a short recording) to the kickoff deck. (CRF-22, GDE-14)
36. Coach sources: use repo-relative links (`../site/src/content/docs/...`) instead of `https://factory.apexops.pro/...`; keep the manual repair page to the scope AGENTS.md allows, with the parameters the stages pass. (LEAD-04, CRF-45, CRF-15, CRF-16, CRF-44)
37. Apply the Fix column of the remaining T06 findings (P2 first, then P3), within the code-change rule; list any that need code under Follow-ups: CRF-31, CHA-34, CHA-47, CHB-35, CHB-39, CRF-32, CRF-33, CRF-34, CRF-35, CRF-36, CRF-37, CRF-38, CRF-46, CRF-47, CRF-48, START-18, START-29.

### T07 Challenge evidence, scoring and recovery paths

38. Replace `alzl-deny-public-acr` with `alzl-deny-pna-acr` in `challenges/c02-secure-ai-ready-foundation.mdx`, `coach/c02-secure-ai-ready-foundation.md` and `facilitator/scoring-rubric.md`. (CHA-01, CRF-02)
39. Exemptions (decision 2: "none needed" is valid evidence). Rewrite C2 requirement 3: `rg-datacenter` normally complies with ALZ-lite, so vending records no exemptions; members record the compliance result (or any exemptions vending did create) and one deferred-work entry for the datacenter with owner, target and timeline. Correct the Bastion explanation (the NIC public IP policy never applies to Bastion's public IP). Remove the hint that sends the team lead to re-run vending when the list is empty. Update the wording, not the points, of rubric row 3, C4 requirement 5 (map the deferred-work entry), the Policy clean badge ("documented exemptions, if any") and Troubleshooting. (CHA-02, CHA-08)
40. C5: add a "Before you deploy" licence check for SQL MI (Hybrid Benefit or licence included) linked to `/reference/azure-hybrid-benefit/`; make the lost-terminal recovery pass `-TenantId`, `-SubscriptionId` and `-Suffix` from `$s` (also in `guides/apex.md`); copy C5's warning about the `deploy.ps1` fallback into the APEX guide; check C2's `registry.bicep` edit was reverted; use the archetype's real `07-*.md` file names. (CHA-03, CHA-04, GDE-12, CHA-49, CHA-20)
41. Prompt 07: save C3's triage to `C:\src\<your-repo>\factory\evidence\c03\triage.md` on `main` (run `git pull --rebase` first). (GDE-01)
42. C6: name the evidence for the rubric's per-task build-and-run row (a per-task log plus `git log`); give prompts 03, 04 and 05 the same "Before you send" block as the others (agent, harness, model, where, which requirement). Settle whether assessors read `vm-dev01-work` (C6 versus C9). (CHB-01, GDE-05, CHB-06)
43. C7: add the team lead's Day 2 08:30 Graph-grant check (`-WhatIf`) with a link to Step 2.2; fix the cross-references to C2's requirement numbers. Rollback (decision 11): C7 and the runbook template (both copies) say rollback after cutover isn't exercised at the event; the runbook's rollback section covers aborting before cutover and names what a customer would do after it (restore from backup or a planned failback). (CHB-02, CHB-03, CHB-16, CHA-19)
44. Curveball (decision 12): say on C2, the C2 coach sheet and the curveballs page that the Day 1 curveball goes in the team lead's C2 evidence and changes nobody's points; other members aren't marked down for not having it.
45. C8: make the ACCEPT rule match `Test-Acceptance.ps1` (no UNKNOWN), and give a path for a member whose cutover isn't done. C10: add Owner and Next step columns to the AI-readiness gap register (both template copies), replace the stale C2 item in the factory-kit checklist with `guardrail-test.md`, and add example rows. (CHB-04, CHB-29, CHB-07, CRF-23, CHB-08, CHB-37, CHB-38)
46. C2 details: fix the inverted baseline list, the pre-commit exclusion, the Key Vault purge-protection case, the rubric's explanation item, the "deny didn't fire" path and the non-negotiable defaults table name. (CHA-10, CHA-11, CHA-12, CHA-13, CHA-15, CHA-09)
47. Deploy steps: give the lab password route after a failed run; tell members to wait until `vm-app01` shows Connected in Arc after starting the VMs; give the Privileged Role Administrator a ready-to-run block (PIM, `az login --tenant`, download, `-WhatIf`); add the missing failures to Troubleshooting. (DEP-12, DEP-11, DEP-18, CRF-28)
48. Give every challenge page the same header line: day, start time, time box, scope, points, matching `facilitator/agenda.md`. (CHA-40, CHA-45, CHB-15)
49. Apply the Fix column of the remaining T07 findings (P2 first, then P3), within the code-change rule; list any that need code under Follow-ups: CHA-06, CHA-17, CHA-18, CHA-26, CHA-27, CHA-28, CHA-29, CHA-30, CHA-43, CHA-46, CHA-48, CHB-12, CHB-17, CHB-19, CHB-26, CHB-27, CHB-32, CHB-34, CHB-36, CHB-41, CHB-44, DEP-21, DEP-23, DEP-24, DEP-27, DEP-28, DEP-38, DEP-42, GDE-21, GDE-22, GDE-40, START-28.

### T08 Tear down and clean-up

50. Rebuild `deploy/tear-down.mdx`: a Who/When line and "(T+2)" in the title; a "Before you run teardown" checklist (scores signed off, `git branch -vv` shows `vm-dev01-work` pushed, evidence on `main`, settings values noted, the event owner's go); the command lines from T01 (the team lead's full teardown needs `-f members=all -f confirm-team-teardown=true`); the default from decision 8: add `-f include-management=true` unless the event owner will reuse the tenant (the next event then needs the Graph grant again); who the admin is in each repo and what they need; real durations (about 20 minutes without an archetype, up to about 2 hours with SQL MI; don't cancel); a final check that the resource groups are gone; links to Troubleshooting and Cost. (DEP-06, DEP-13, DEP-14, DEP-15, DEP-40, DEP-41, CRF-43)
51. Correct the team-teardown claims in `facilitator/platform-pipeline.md` and the automation map, and make `facilitator/cleanup.md` and `facilitator/guide.md` match the new commands. (CRF-21, CRF-46)
52. Apply the Fix column of the remaining T08 findings (P2 first, then P3), within the code-change rule; list any that need code under Follow-ups: START-08.

### T09 Product freshness and outside links

53. Upgrade dashboard (decision 5): C3, C6, prompts 01 and 02, the playbook and the GitHub Copilot upgrade guide say "validated with the GitHub Copilot upgrade extension 1.1.612 on VS Code 1.139.0" (from `versions.md`) and add one fallback line: "If no dashboard opens, ask Copilot to show `plan.md` and `tasks.md`." 🧑 HUMAN: the owner re-tests on the current extension before the dry run and updates `versions.md`. (GDE-02, CHA-16, CHB-14, GDE-30)
54. Replace references Learn has moved on from: the Upgrade Assistant link (GDE-16); "Transaction search" is now Search in the page, both template copies and the coach sheet (CHB-05); CAF Strategy motivations (CHA-07); the Copilot app's plugin install steps (GDE-15). OpenTelemetry (decision 13): C6 says the kit uses the Azure Monitor OpenTelemetry Distro (validated) and that Learn now recommends the Microsoft OpenTelemetry Distro for new apps; no code change. (CHB-13)
55. Point the five redirected links at their canonical pages. (LEAD-05, CHB-24, CHB-42, CHA-31)
56. Learning path: AZ-305 earns the Expert certification only with AZ-104; refresh the outline dates and the Last validated date. (GDE-08, GDE-17, GDE-18)
57. Add a "Validated on" date to every page with fast-changing UI labels or product facts: Requirements, Cost, Availability zones, the GitHub Copilot upgrade guide, the prompts, and C7's portal steps. (START-34, CHB-22, CRF-24)
58. Apply the Fix column of the remaining T09 findings (P2 first, then P3), within the code-change rule; list any that need code under Follow-ups: CHA-38, CHA-42, CHB-31, CRF-39, DEP-25, DEP-26, GDE-19, GDE-20, GDE-23, GDE-24, GDE-38.

### T10 Terminology, style and glossary

59. Add the missing glossary entries (CAF, ALZ, AHB, ACR, KPI, CVE, MSMQ, SSMS, MFA, RBAC, OIDC, NSG, NAT gateway, DNS proxy, DeployIfNotExists, MCP, Copilot CLI, agent mode, As-Built, playbook, roster, shared services subscription, workload subscription, Corp management group, T+2, tech lead, event owner, Privileged Role Administrator, and the Azure services the site names). (CRF-29)
60. One term per concept: "requirement" for challenge items, including the progress bar (text only); "GitHub Copilot" in titles and sidebar labels (keep GHCP only if the glossary defines it); "Getting started" in sentence case; one form of Day 1 / day one; "hackathon" on the 404 page (text only); member, attendee, team lead, coach and event owner as the only persona words. (CHA-21, CHB-10, START-21, GDE-37, CHA-36, START-30, LEAD-06, CHB-28, LEAD-07)
61. Apply the Fix column of the remaining T10 findings (P2 first, then P3), within the code-change rule; list any that need code under Follow-ups: CHA-25, CHA-41, CHA-44, CHB-09, CHB-30, CHB-33, CRF-41, CRF-42, DEP-32, DEP-37, GDE-28, GDE-29, GDE-34, GDE-35, GDE-36, GDE-39, LEAD-08, START-22, START-24, START-25, START-27, START-31, START-32, START-39, START-40, START-41.

## Deliverables

- `site/astro.config.mjs` (sidebar), page frontmatter under `site/src/content/docs/**` (order, labels, `next`/`prev`)
- Pages under `site/src/content/docs/**` named in the requirements
- `site/src/components/JourneyMap.astro` (the C2 data only), and text-only edits in `site/src/pages/404.astro` and the progress-bar label
- `coach/*.md` (including `curveballs.md`, `apex-demo.md` and `scoreboard.md`, moved from `facilitator/`), `facilitator/*.md`
- `templates/attendee/*` and `templates/team/templates/*` (both copies, kept identical)
- `.github/modernization/playbook.md`, `archetype/README.md`, `infra/foundation/README.md`
- Text-only edits in `scripts/Initialize-Settings.ps1`, `scripts/Initialize-PlatformPipeline.ps1`, `scripts/Test-Preflight.ps1` and the vending error message
- `.github/workflows/platform.yml`: the guard in T01 requirement 1, plus text-only edits to its header comment and run summary

## Verify

Commands are PowerShell 7, from the repo root.

```powershell
npm run check
Push-Location site; npm run build; npm run lint:prose; Pop-Location
node scripts/check-internal-links.mjs
# Each of these returns nothing:
Get-ChildItem site/src, coach, facilitator -Recurse -File | Select-String -Pattern 'alzl-deny-public-acr'
Get-ChildItem coach, facilitator -Recurse -File | Select-String -Pattern 'https://factory\.apexops\.pro'
# Review every hit by hand: each must be an event-day context
Get-ChildItem site/src/content/docs -Recurse -File | Select-String -Pattern '(tell|ask) your coach|a coach can help'
```

- In the built site: the last Prompts page has no Next link into `/coach/`; Step 4's Next is the Challenges overview; C10's Next is Tear down; About has no Next; Coach is the last sidebar group and lists Lifelines.
- `/getting-started/kit-at-a-glance/` shows C2 as Member, 45 minutes, 15 points, with totals of 750 minutes and 170 points; `/coach/` shows C2's bonus as "up to 5 pts".
- The coach sidebar lists Lifelines, Scoreboard and badges, Curveballs and APEX demo script, and each opens a rendered page; coach page titles end in "(coach)".
- T01 requirement 1, in the CI lab with the owner's approval: a lead `teardown` without `members` fails in plan; `-f members=<n>` skips `teardown-team`; a `ci-test/teardown-*` push still works. Link the runs in the PR.
- The diff changes no logic outside `platform.yml`'s plan and teardown conditions; every other code-file change is a string.
- Every internal link and anchor resolves, and no URL changed without a redirect.

## Done when

- [ ] T01 Lead-repo safety: teardown, members filter, vending reruns: PR merged by the owner.
- [ ] T02 Support model and roles before and during the event: PR merged by the owner.
- [ ] T03 Prerequisites, tenant commitments and cost up front: PR merged by the owner.
- [ ] T04 Single source of truth for facts and data: PR merged by the owner.
- [ ] T05 Navigation and information architecture: PR merged by the owner.
- [ ] T06 Coach section: run both days from the site: PR merged by the owner.
- [ ] T07 Challenge evidence, scoring and recovery paths: PR merged by the owner.
- [ ] T08 Tear down and clean-up: PR merged by the owner.
- [ ] T09 Product freshness and outside links: PR merged by the owner.
- [ ] T10 Terminology, style and glossary: PR merged by the owner.
- [ ] Each PR names the decisions it applies (by number) and lists anything deferred under Follow-ups.
- [ ] The PR bodies list every finding ID they close, and any finding left open with the reason.

## Commit messages

```text
fix(pipeline): require named members for team-lead member and teardown runs
docs: route pre-event help to the team lead and event owner
docs: list tenant, GitHub, Copilot and cost prerequisites
docs: state shared facts once and match their sources
docs: reorder the sidebar and pager around the event journey
docs: publish the coach material needed on event days
docs: align challenge evidence with the rubric and scripts
docs: make tear down safe and complete
docs: refresh product references and validated-on dates
docs: use one term per concept and extend the glossary
```

## Stop and ask if

- A fix would change logic in a script, the workflow (beyond T01 requirement 1), Bicep, a site component or the coach loader, or would change points. Strings and docs are fine.
- A decision above doesn't fit what you find in the repo.
- The code and the page disagree and the findings register doesn't say which one changes.
- A Learn page contradicts a finding's Fix column (products change; check the date).
- A change would move a URL. Add a redirect only after the owner agrees.
- Any run would touch the owner's live lab (the subscriptions in `.local/settings.json`).

## Deferred: needs code (not in this item)

These parts of findings need code changes, which the owner has ruled out for now. Leave them for a later item.

| Change | Findings |
|---|---|
| Extend `scripts/check-content-invariants.mjs` to check components against `challenges.json` | START-01 (the data fix is in T04) |
| Run Vale on `coach/` and `facilitator/` (`site/package.json`, `validate-docs.yml`) | CRF-45 |
| Previous/next links between coach sheets | CRF-48 |
| A meta description per coach page | CRF-38 |
| Fix the coach loader's bonus regex and alert stripping (worked around in content) | CRF-10, CRF-12 |
| Render the agenda on Event overview from `facilitator/agenda.md` instead of moving it | START-18 |
| Keep coach pages out of site search (labelled instead) | LEAD-09 |
| One template copy instead of two | C6–C10 reviewer note |
| Move to the Microsoft OpenTelemetry Distro | CHB-13 |

## Appendix: code and pipeline changes

Everything B24 changes outside the documentation. One logic change (the teardown guard); the rest is wording, one data correction and sidebar configuration.

### Pipeline: `.github/workflows/platform.yml` (T01)

| Change | Kind | What changes |
|---|---|---|
| New input `confirm-team-teardown` | Logic | Boolean, default `false`. Teardown only, team lead's repo. |
| `members` accepts `all` | Logic | `all` expands to `MEMBER_INDEXES`. Description becomes: "Member indexes, comma separated (for example 1,2,3), or all. In the team lead's repo, member, teardown and all need a value." |
| Plan job guard | Logic | For `workflow_dispatch` runs in the lead profile, `member`, `teardown` and `all` fail in the plan job, before any Azure call, when `members` is empty. The error shows both forms. |
| `teardown-team` condition | Logic | Runs only when the plan says so: by hand, `members=all` and `confirm-team-teardown=true`; on `ci-test/teardown-*` pushes, as today. |
| Header comment | Text | Drop "the reviewer approves it once for the stage" and "vending waits for the coach to approve each readiness record": a reviewer approves only where the plan offers one, and vending checks readiness itself. |
| Member-stage run summary | Text | "Vending comes after the foundation and every member's readiness record is approved." becomes "The team lead's vending stage at T-1 checks your Arc status automatically." |
| `include-management` description | Text | Add: "Use it at T+2 unless the event owner will reuse the tenant." The default stays `false`. |

Sketch of the plan-step logic (keep the existing job structure, outputs and `ci-test` behaviour):

```bash
# Added to the plan step's env: INPUT_CONFIRM_TEAM_TEARDOWN: ${{ inputs.confirm-team-teardown }}
requested="${INPUT_MEMBERS// /}"
if [ "$GITHUB_EVENT_NAME" = "workflow_dispatch" ] && [ "$profile" = "lead" ]; then
  case "$stage" in
    member|teardown|all)
      if [ -z "$requested" ]; then
        echo "::error::In the team lead's repo, '$stage' needs -f members=<your index> or -f members=all."
        exit 1
      fi ;;
  esac
fi
if [ "$requested" = "all" ]; then INPUT_MEMBERS=""; fi   # fall back to MEMBER_INDEXES below
team=false
if [ "$stage" = "teardown" ] && [ "$profile" = "lead" ]; then
  if [ "$GITHUB_EVENT_NAME" != "workflow_dispatch" ]; then team=true
  elif [ "$requested" = "all" ] && [ "$INPUT_CONFIRM_TEAM_TEARDOWN" = "true" ]; then team=true; fi
fi
echo "team-teardown=$team" >> "$GITHUB_OUTPUT"
```

```yaml
teardown-team:
  needs: [plan, teardown-member]
  if: ${{ needs.plan.outputs.stage == 'teardown' && needs.plan.outputs.profile == 'lead' && needs.plan.outputs.team-teardown == 'true' && needs.teardown-member.result == 'success' }}
```

Checks: `actionlint`; the CI-lab runs listed in requirement 1, each approved by the owner.

### Scripts (text only, no behaviour change)

| File | Current text | New text | Findings |
|---|---|---|---|
| `scripts/Initialize-Settings.ps1` | Prompt "Your member index (1-20, from your coach)" | "Your member index (1-20, from your team lead)" | DEP-33 |
| `scripts/Initialize-Settings.ps1` | Prompt "...members: press Enter, you add it in C2" and the help line "members add it in C2" | "...you add it at Step 4" | DEP-33 |
| `scripts/Initialize-PlatformPipeline.ps1` | Closing line "Then the foundation: gh workflow run platform.yml ... -f stage=foundation" | "At T-7 (Step 2), run the foundation: ..." | DEP-17 |
| `scripts/Invoke-PipelineVending.ps1` | "Deploy it first: the datacenter comes before ALZ-lite and vending." | "Deploy it first: each member's datacenter (Step 3) must exist before vending." | DEP-44 |
| `scripts/Deploy-AlzLite.ps1` | Help and closing output point to running `./scripts/Deploy-Vending.ps1` by hand | Point to the `vending` stage at T-1 (Step 4) | DEP-44 |
| `scripts/Grant-SqlMiDirectoryRead.ps1` | Help "(C2, task 4)" and "the coach brings someone who does" | "Step 2 (T-7)" and "the team lead books someone who does" (decision 9) | CHA-33, DEP-44 |
| `scripts/Get-PipelineEvidence.ps1` | Help "as C1 explains" | "as Step 3 explains" | DEP-44 |
| `scripts/Import-Kit.ps1` | "Next, as the Set up your repo page describes: ..." | "Next, as Step 1 (Repo and preflight) describes: ..." | DEP-44 |
| `scripts/Test-Preflight.ps1` | MANUAL row "...allowing agent mode, MCP servers and Copilot CLI." | "...allowing agent mode and MCP servers (Copilot CLI only for the playbook's CLI path)." (decision 4) | START-03 |

Checks: PSScriptAnalyzer on every changed script, and the script tests in `test/`.

### Site code and configuration

| File | Kind | What changes | Findings |
|---|---|---|---|
| `site/src/components/JourneyMap.astro` | Data | C2 entry: scope Team → Member, 120 → 45 minutes, 35 → 15 points (totals become 750 minutes and 170 points). | START-01 |
| `site/src/components/JourneyMap.astro` | Text | Phase label "Foundation" for C1 and C2 becomes "Plan and secure". | START-25 |
| `site/src/components/ArchitectureDiagram.astro` | Text | `vm-dev01` "never stopped" goes; it can be stopped between sessions. | START-23 |
| `site/src/scripts/progress.js` | Text | "Jump to task" → "Jump to requirement"; "Tasks N of M done" → "Requirements N of M done"; "All N tasks done" → "All N requirements done". Storage keys stay, so saved progress survives. | CHA-21 |
| `site/src/pages/404.astro` | Text | "workshop guide" / "workshop docs" → "hackathon guide" / "hackathon docs". | LEAD-06 |
| `site/src/pages/coach/index.astro`, `site/src/components/CoachSheet.astro` | Text | "attending as a participant" → "attending as a member"; heading "Facilitator pages" → "Other coach pages"; drop the maintainer line "Edit the source files, not these pages." | LEAD-07, CRF-37 |
| `site/astro.config.mjs` | Config | Sidebar only: "Getting started" label; Deploy relabelled "Before the event"; new "After the event" group linking Tear down; Coach group moved last, reordered and relabelled, with Lifelines, Scoreboard and badges, Curveballs and APEX demo script added. | LEAD-01, LEAD-02, LEAD-03, CRF-17, CRF-18, CRF-19, START-30 |

Checks: `npm run check`, the site build, `lint:prose` and `scripts/check-internal-links.mjs`.

### Not changing

The coach loader, the content check, Vale's scope in CI, `Get-PipelineEvidence.ps1`'s behaviour, `Remove-FactoryEnvironment.ps1`, any Bicep, the app and its skills (OpenTelemetry stays), `Import-Kit.ps1`'s template handling and search indexing. The `include-management` default stays `false`. See "Deferred" above.

## Notes and traps

- In the team lead's repo an empty `members` input means the whole roster. Never test `member` or `teardown` from a lead profile without `-f members`.
- `coach-loader.ts` rewrites repo-relative links in `coach/` and `facilitator/` to site routes only for student pages, challenge sheets, Lifelines, Readiness, the manual repair page, the agenda and the automation map. Links to the newly moved coach pages fall back to GitHub, so point to the sidebar instead.
- Moving sections out of `facilitator/scoring-rubric.md` must leave the base-points table and every `### Cn —` section intact: the loader and `scripts/check-content-invariants.mjs` read them.
- The templates exist twice (`templates/attendee/` and `templates/team/templates/`) and must stay identical.
- `trailingSlash: "always"`: internal links end in `/`.
- Vale ignores frontmatter, so check titles and sidebar labels by hand; `lint:prose` covers only `src/content` today.
- Don't run `npx prettier --write` on `docs/`.
- No identifiers in the repo, logs or PR bodies; draft PRs only; never push to `main`.
- `docs/archive/` is history: don't edit it to match the site.
