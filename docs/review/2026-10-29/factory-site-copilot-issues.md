# GitHub issues: October 2026 site review

Ten issues, one per theme. Each one is a block of requirements in the B24 spec (`factory-site-copilot-spec.md`) and cites the findings it closes (`factory-site-review-findings.md`). All owner decisions were recorded on 29 October 2026 and are in the spec.

## How to use these

1. Put the five review files in `docs/review/2026-10-29/` on `main` first: the issue bodies link there.
2. Create the issues in order (T01 to T10). Each block below gives the title, the labels and the body.
3. Assign one issue at a time to Copilot (the cloud agent) and merge each PR before you assign the next. The themes edit the same pages; T05 and T06 both edit `site/astro.config.mjs`.
4. Only the 🧑 HUMAN steps need the owner: the T01 CI-lab runs, re-testing the upgrade path before the dry run, and adding the full-ALZ slides to the kickoff deck.
5. In VS Code agent mode or Copilot CLI, use the kickoff prompt at the top of the spec instead.

| Issue | Title | Highest severity | Findings | Spec requirements |
|---|---|---|---:|---|
| T01 | Make team-lead commands safe: teardown guard, members filter, vending reruns | P0 | 11 | 1 to 4 |
| T02 | Route pre-event help to the team lead and event owner; define every role | P1 | 14 | 5 to 10 |
| T03 | List tenant, GitHub, Copilot and cost prerequisites on Requirements | P1 | 21 | 11 to 15 |
| T04 | State shared facts once (journey map, agenda, timings, member index) | P1 | 24 | 16 to 23 |
| T05 | Reorder the sidebar and pager around the event journey; make links two-way | P1 | 38 | 24 to 30 |
| T06 | Publish the coach material needed on event days | P1 | 35 | 31 to 37 |
| T07 | Align challenge evidence with the rubric and scripts; fix recovery paths | P1 | 68 | 38 to 49 |
| T08 | Make Tear down safe, complete and linked | P1 | 9 | 50 to 52 |
| T09 | Refresh product references, outside links and validated-on dates | P2 | 27 | 53 to 58 |
| T10 | Use one term per concept and extend the glossary | P2 | 33 | 59 to 61 |

---

## T01: Make team-lead commands safe: teardown guard, members filter, vending reruns

**Title:** `Site review T01: Make team-lead commands safe: teardown guard, members filter, vending reruns`

**Labels:** `documentation`, `site-review`, `P0`, `needs-owner-action`, `pipeline`

```markdown
Part of B24, the October 2026 site review. Spec: docs/review/2026-10-29/factory-site-copilot-spec.md, requirements 1 to 4. Evidence and the fix for every finding ID: docs/review/2026-10-29/factory-site-review-findings.md.

## Problem

In the team lead's repo, an empty `members` input means "every member on the roster". Several pages show only the member form of `member` and `teardown`, and the `teardown-team` job runs after any lead teardown, even a filtered one. Vending's stop-at-first-failure behaviour is described as if it were per member.

## Why it matters

A team lead who follows the page can wipe the team's datacenters and the foundation days before the event, or leave teammates unvended on the morning of day one.

## Decisions

Fail closed (decision 1). The workflow guard is the only logic change in B24; each CI-lab run needs the owner's approval. Numbers follow the Decisions table in the spec.

## What to change

1. Fail-closed guard (decided 29 Oct 2026; the one logic change in this item, owner-approved). In the plan job of `.github/workflows/platform.yml`, for `workflow_dispatch` runs in the lead profile: the `member`, `teardown` and `all` stages need an explicit `members` input, either one or more indexes or `all` (expanded from `MEMBER_INDEXES`). With no value, fail in the plan job before any Azure call, with a message that shows both forms. `teardown-team` runs only when `members` is `all` and a new boolean input `confirm-team-teardown` is `true`. Pushes to `ci-test/*` branches and member-profile runs behave as today. Also fix the header comment that says vending waits for a coach (text only). Test in the lab named in `.local/ci-lab.json`, never the owner's live lab, each run approved by the owner: (1) a lead `teardown` with no `members` fails in plan; (2) `-f members=<n>` removes only that member and skips `teardown-team`; (3) a `ci-test/teardown-*` push still works; (4) `-f members=all -f confirm-team-teardown=true` at the next planned lab teardown. Link the runs in the PR. (DEP-01, CRF-01, DEP-16)
2. Once requirement 1 is merged, wherever a page shows `gh workflow run platform.yml -f stage=member` or `-f stage=teardown`, show two forms: "In your own repo (member)" and "In the team lead's repo: add `-f members=<your index>`". At T+2 the team lead's full teardown is `-f stage=teardown -f members=all -f confirm-team-teardown=true`, plus `-f include-management=true` unless the event owner will reuse the tenant (decision 8). Pages: `deploy/member-steps.mdx` (including "If you need to start over" and the `no-hybrid-benefit` command), `deploy/tear-down.mdx`, `reference/troubleshooting.md` (Arc entries), `reference/azure-hybrid-benefit.md`. Add one rule to the Deploy overview: "Team leads: your repo runs `member` and `teardown` only for the members you name." (DEP-02, CRF-09)
3. Add a team-lead warning to every start-over path: never run a full teardown in the lead repo before T+2; to start over, use `-f members=<your index>` or ask the event owner for a coach repair. Make the after-Arc recovery the same on `deploy/member-steps.mdx`, `reference/troubleshooting.md`, `reference/azure-hybrid-benefit.md` and `coach/readiness.md`, and say that member teardown also removes `rg-spoke` and the archetype, so the team lead must run vending for that member again. (DEP-01, CRF-01, DEP-07, CRF-13, DEP-20, CRF-27)
4. Describe vending failures as the script behaves: it stops at the first member who isn't ready; earlier members are vended but not restarted, exempted or probed; later members aren't vended. The fix is to correct the cause and re-run vending for all members (safe to repeat); use `-f members=<n>` only for members that phase 3 names. Pages: `deploy/vending.mdx`, `getting-started/event-overview.mdx`, `coach/readiness.md`, `facilitator/agenda.md`. (DEP-03, CRF-07, START-07)

## Findings in scope

- **P0:** CRF-01, DEP-01
- **P1:** CRF-07, CRF-09, DEP-02, DEP-03
- **P2:** CRF-13, CRF-27, DEP-07, START-07
- **P3:** DEP-20

## Acceptance criteria

- [ ] In the CI lab (owner-approved runs): a lead `teardown` without `members` fails in the plan job; `-f members=<n>` removes only that member and skips `teardown-team`; a `ci-test/teardown-*` push still works.
- [ ] Every `member` or `teardown` command on the site shows the team lead's form, and Tear down shows the full form (`-f members=all -f confirm-team-teardown=true`).
- [ ] Start-over and after-Arc recovery read the same on Step 3, Troubleshooting, Azure Hybrid Benefit and the coach readiness page, and mention re-vending.
- [ ] Vending failure guidance says to re-run for all members, on Step 4, Event overview, the coach readiness page and the agenda.
- [ ] `npm run check`, the site build, `lint:prose` and `scripts/check-internal-links.mjs` pass, and the diff has no logic changes outside T01 requirement 1.
- [ ] The PR body lists every finding ID it closes, and any it leaves open with the reason.

## Rules

Follow AGENTS.md: draft PR, conventional commit, no identifiers, never push to main. Code-change rule: docs, sidebar config, frontmatter and text-only string edits; no logic changes except T01 requirement 1. Anything that needs code goes under Follow-ups. Stop and ask before changing points or a URL.
```

---

## T02: Route pre-event help to the team lead and event owner; define every role

**Title:** `Site review T02: Route pre-event help to the team lead and event owner; define every role`

**Labels:** `documentation`, `site-review`, `P1`

```markdown
Part of B24, the October 2026 site review. Spec: docs/review/2026-10-29/factory-site-copilot-spec.md, requirements 5 to 10. Evidence and the fix for every finding ID: docs/review/2026-10-29/factory-site-review-findings.md.

## Problem

AGENTS.md is clear: before day one the team lead is the first contact and there's no coach on duty. Requirements, Troubleshooting, two guides, a script prompt and leftover run-summary text still send people to a coach, and the event owner (who confirms rosters and books the Privileged Role Administrator) isn't on any page. "Tech lead" differs from "team lead" by one word and isn't defined.

## Why it matters

People wait for help that won't come, and nobody owns the T-7 Graph grant booking.

## Decisions

The team lead books the Privileged Role Administrator; the event owner handles escalations (decision 9). Numbers follow the Decisions table in the spec.

## What to change

5. Before day one, every escalation is member → team lead → event owner. Replace pre-event "tell your coach" / "ask your coach" / "a coach can help" on `getting-started/requirements.mdx` (three places), `reference/troubleshooting.md` (preflight, quota, Arc timeout and the closing line), `guides/alz-lite.md`, `guides/ghcp-upgrade.md` ("Before the event, ask your team lead; on event days, ask your coach"), and `deploy/set-up-your-repo.mdx`. In `scripts/Initialize-Settings.ps1` (text only), change "from your coach" to "from your team lead" and drop "in C2". Keep coach wording for event-day contexts. (START-02, DEP-04, DEP-19, CRF-08, GDE-10, DEP-29, DEP-33)
6. Add the event owner to `getting-started/roles.md` and the glossary: confirms rosters and member indexes, handles escalations (for example when the team lead can't find a Privileged Role Administrator) and owns clean-up. Add the escalation path. (START-05)
7. Define the tech lead (who gives the 08:30 kickoff, from which organization) in Roles and the glossary, and say once that the workflow and scripts call the team lead the "platform lead". (START-15, START-41, CRF-36)
8. Remove what's left of the old readiness approval (text only): the member-stage run summary in `platform.yml` and the C5 coach sheet say the team lead's vending stage checks Arc status automatically. (DEP-16, CRF-14)
9. The team lead books the Privileged Role Administrator for T-7; the event owner only handles escalations (decision 9). Say so on Step 2, in the ALZ-lite guide (replace "a coach can help" with "if you can't find one, escalate to your event owner"), in the team lead row of Requirements and in `facilitator/guide.md`, which today gives the booking to the event owner. (GDE-09, START-35)
10. Apply the Fix column of this theme's remaining findings listed below, P2 first, within the code-change rule.

## Findings in scope

- **P1:** CRF-08, DEP-04, START-02, START-05
- **P2:** CRF-14, DEP-16, DEP-19, GDE-09, GDE-10, START-15
- **P3:** CHA-33, DEP-29, START-35, START-38

## Acceptance criteria

- [ ] No pre-event page or script prompt tells people to contact a coach (grep output reviewed in the PR).
- [ ] Roles and the glossary define the event owner, the tech lead and the "platform lead" alias.
- [ ] No text says a coach approves readiness records.
- [ ] Step 2, the ALZ-lite guide, Requirements and `facilitator/guide.md` all say the team lead books the Privileged Role Administrator.
- [ ] `npm run check`, the site build, `lint:prose` and `scripts/check-internal-links.mjs` pass, and the diff has no logic changes outside T01 requirement 1.
- [ ] The PR body lists every finding ID it closes, and any it leaves open with the reason.

## Rules

Follow AGENTS.md: draft PR, conventional commit, no identifiers, never push to main. Code-change rule: docs, sidebar config, frontmatter and text-only string edits; no logic changes except T01 requirement 1. Anything that needs code goes under Follow-ups. Stop and ask before changing points or a URL.
```

---

## T03: List tenant, GitHub, Copilot and cost prerequisites on Requirements

**Title:** `Site review T03: List tenant, GitHub, Copilot and cost prerequisites on Requirements`

**Labels:** `documentation`, `site-review`, `P1`

```markdown
Part of B24, the October 2026 site review. Spec: docs/review/2026-10-29/factory-site-copilot-spec.md, requirements 11 to 15. Evidence and the fix for every finding ID: docs/review/2026-10-29/factory-site-review-findings.md.

## Problem

Requirements covers accounts and tools, but not the commitments a partner has to secure weeks ahead: a dedicated non-production tenant with empty subscriptions (the kit moves them under a Deny-policy management group and turns off paid Defender plans), the GitHub plan that environments and secrets need on private repos, Copilot org policies (MCP servers, Copilot CLI, models), Owner at Tenant Root by T-14, Hybrid Benefit eligibility, Docker licensing and the cost.

## Why it matters

These are the slow approvals. Discovering them at T-14 or T-7 pushes the event.

## Decisions

GitHub Free works (decision 3); Copilot CLI is optional (decision 4); Docker gets a licence note only (decision 10). Numbers follow the Decisions table in the spec.

## What to change

11. Add rows to `getting-started/requirements.mdx`, each with who grants it and by when: (a) a dedicated non-production tenant and dedicated, empty subscriptions, and what the kit changes in them (moves them under `mg-factory-corp` with Deny policies; Foundational CSPM only, with every paid Defender plan off); (b) GitHub plan (decision 3): GitHub Free works, because the owner ran the pipeline end to end from private repos on a free plan in October 2026; required reviewers need a paid plan, so on Free the gate is write access (keep the repo private and the writers few); (c) Copilot (decision 4): a seat, plus org policies for agent mode and MCP servers (off by default); Copilot CLI is optional, only for the playbook's CLI path; (d) Owner at Tenant Root in place by T-14, because pipeline setup in Step 1.5 needs it; (e) org rights to create private repos from a template, and an Actions policy that allows `actions/checkout`, `actions/upload-artifact` and `azure/login`; (f) Azure Hybrid Benefit eligibility, linked to `/reference/azure-hybrid-benefit/`; (g) Docker Desktop (decision 10): a licensing note only ("organizations with 250 or more employees or $10M or more revenue need a paid Docker subscription; confirm yours before T-14"); (h) VS Code: latest stable, 1.106 or later; (i) the network allowlist, pointing to GitHub's and VS Code's own lists. Repeat (a) as a caution on Step 2 and Step 4. (START-04, DEP-10, DEP-05, START-03, DEP-09, START-14, START-13, START-12, START-10, START-11)
12. Make the Copilot CLI optional everywhere it's asked for: `scripts/Test-Preflight.ps1`'s MANUAL reason (text only), check 4 on Step 1 and `facilitator/guide.md`. Add a Troubleshooting entry: if Step 1.5 can't create the `gh-lab` environment or set its secrets, check the org's GitHub plan (GitHub's docs list Pro, Team or Enterprise for environments in private repos). (START-03, DEP-05)
13. Add a Cost row to Requirements (per-member and per-team hourly figures, billing from T-7 to T+2, link to `/reference/cost/`). On the Cost page: date the prices, add when each charge starts and stops (foundation from T-7, datacenter from Step 3, archetype from C5, all until teardown), correct the no-Hybrid-Benefit delta (it changes `vm-app01` only), and publish the 3-, 4- and 5-member totals. Link Cost from Requirements, the Step 3 cost hint and Tear down. (START-09, CRF-24, CRF-25, CRF-11, CRF-30, CRF-40)
14. Fix the Windows 11 Hybrid Benefit statement on the Azure Hybrid Benefit page and Step 1 to match Learn (per-user licences). (CRF-26, DEP-31)
15. Apply the Fix column of this theme's remaining findings listed below, P2 first, within the code-change rule.

## Findings in scope

- **P1:** DEP-05, START-03, START-04
- **P2:** CRF-11, CRF-24, CRF-25, CRF-26, DEP-09, DEP-10, START-09, START-10, START-11, START-12, START-13, START-14
- **P3:** CRF-40, DEP-31, DEP-34, DEP-35, START-17, START-37

## Acceptance criteria

- [ ] Requirements has a row each for tenant and subscriptions, GitHub plan (Free works), Copilot policies (CLI optional), Tenant Root timing, org rights, Hybrid Benefit, Docker licence, VS Code, network and cost, with who grants it and by when.
- [ ] The preflight text, Step 1 check 4 and the facilitator guide call the Copilot CLI optional; Troubleshooting covers a GitHub plan error in Step 1.5.
- [ ] Step 2 and Step 4 carry the dedicated-tenant caution; the Cost page is dated, shows when charges start and stop and the team totals, and is linked from Requirements, Step 3 and Tear down.
- [ ] `npm run check`, the site build, `lint:prose` and `scripts/check-internal-links.mjs` pass, and the diff has no logic changes outside T01 requirement 1.
- [ ] The PR body lists every finding ID it closes, and any it leaves open with the reason.

## Rules

Follow AGENTS.md: draft PR, conventional commit, no identifiers, never push to main. Code-change rule: docs, sidebar config, frontmatter and text-only string edits; no logic changes except T01 requirement 1. Anything that needs code goes under Follow-ups. Stop and ask before changing points or a URL.
```

---

## T04: State shared facts once (journey map, agenda, timings, member index)

**Title:** `Site review T04: State shared facts once (journey map, agenda, timings, member index)`

**Labels:** `documentation`, `site-review`, `P1`

```markdown
Part of B24, the October 2026 site review. Spec: docs/review/2026-10-29/factory-site-copilot-spec.md, requirements 16 to 23. Evidence and the fix for every finding ID: docs/review/2026-10-29/factory-site-review-findings.md.

## Problem

Facts are copied instead of referenced: `JourneyMap.astro` hard-codes challenge data, About keeps its own copy of the agenda (minus the breaks), durations differ between pages and script output, the member index range is 1–5 on some pages and 1–20 on others, prompts copy the playbook's tables, and the templates exist twice.

## Why it matters

Copies drift, and they already have.

## Decisions

APEX 07b works but isn't supported at events (decision 7); keep both template copies (decision 14). Numbers follow the Decisions table in the spec.

## What to change

16. Correct the C2 entry in `site/src/components/JourneyMap.astro` in place (scope Member, 45 minutes, 15 points); no refactor. In the PR, show that every JourneyMap entry matches `challenges.json`. (START-01)
17. One agenda: move the Day 1 and Day 2 tables into `getting-started/event-overview.mdx`, keep the breaks, remove the copy from About, and update links that point to `/about/#agenda`. (START-18, START-20)
18. One member-index rule, said the same way on Step 1, Roles and Kit at a glance, and in the script prompts (text only): "assigned by the team lead; scripts accept 1 to 20; teams use 1 to 5; the team lead is 1". Add a Step 1 sub-step, before 1.4, where the team lead assigns and shares indexes. (DEP-08, DEP-43, START-27, DEP-33)
19. One timing table for the stages (in How it works); other pages link to it. Fix the script text that contradicts the pages (text only), for example the setup script's "Then the foundation" at T-14 and vending's "the datacenter comes before ALZ-lite". (DEP-22, DEP-44, DEP-17)
20. Stop copying the playbook into the prompts: link to playbook anchors instead, and align the model guidance with the playbook (balanced model to assess, most capable to plan). (GDE-03, GDE-04, CHB-25)
21. Resolve the remaining contradictions: persona names in C1 versus the customer story (CHA-05); whether assessors read `vm-dev01-work` (CHB-06); when members get the shared services subscription ID (CHA-14). APEX 07b (decision 7): `archetype/README.md` says the path works but isn't supported at events and coaches won't help with it; the APEX guide keeps azd as the path. (GDE-13)
22. Templates stay in two identical copies (decision 14): every template fix in this item lands in both `templates/attendee/` and `templates/team/templates/`.
23. Apply the Fix column of this theme's remaining findings listed below, P2 first, within the code-change rule.

## Findings in scope

- **P1:** START-01
- **P2:** CHA-05, CHA-14, CHB-06, GDE-03, GDE-04, GDE-13
- **P3:** CHA-23, CHA-37, CHB-18, CHB-21, CHB-25, CHB-40, CHB-43, DEP-22, DEP-30, DEP-33, DEP-43, DEP-44, GDE-27, START-20, START-23, START-26, START-36

## Acceptance criteria

- [ ] Kit at a glance shows C2 as Member, 45 minutes, 15 points, and every journey entry matches `challenges.json`.
- [ ] The agenda lives on Event overview only; About no longer holds a copy.
- [ ] The member-index rule and the stage timings are stated once and linked from elsewhere; script prompts match.
- [ ] Prompts link to the playbook instead of copying its tables; `archetype/README.md` says 07b isn't supported at events.
- [ ] `npm run check`, the site build, `lint:prose` and `scripts/check-internal-links.mjs` pass, and the diff has no logic changes outside T01 requirement 1.
- [ ] The PR body lists every finding ID it closes, and any it leaves open with the reason.

## Rules

Follow AGENTS.md: draft PR, conventional commit, no identifiers, never push to main. Code-change rule: docs, sidebar config, frontmatter and text-only string edits; no logic changes except T01 requirement 1. Anything that needs code goes under Follow-ups. Stop and ask before changing points or a URL.
```

---

## T05: Reorder the sidebar and pager around the event journey; make links two-way

**Title:** `Site review T05: Reorder the sidebar and pager around the event journey; make links two-way`

**Labels:** `documentation`, `site-review`, `P1`

```markdown
Part of B24, the October 2026 site review. Spec: docs/review/2026-10-29/factory-site-copilot-spec.md, requirements 24 to 30. Evidence and the fix for every finding ID: docs/review/2026-10-29/factory-site-review-findings.md.

## Problem

No link is broken, but the structure works against the journey: three different "start here" orders, How it works between Step 4 and Tear down, the Coach group between Prompts and Reference (so the pager leads into answer keys), prompts numbered out of challenge order, landing pages all called "Overview", one-way links between challenges and the guides and prompts that serve them, and Tear down, Cost and Troubleshooting each linked from one or two places.

## Why it matters

Readers who follow "Next" get lost or spoiled; readers who need help can't find it from where they are.

## Decisions

Label coach pages "(coach)" rather than hiding them from search (decision 15). Numbers follow the Decisions table in the spec.

## What to change

24. Apply the proposed sidebar in the report, section 3, in `site/astro.config.mjs` and page frontmatter (`sidebar.order`, labels): Getting started reordered; How it works before Step 1; a new "After the event" group with Tear down; Guides and Prompts in order of use (Prompts by `sidebar.order` only, labels without the repeated "VS Code:" prefix); Reference with Troubleshooting first; Coach last. Don't change URLs. (START-16, START-30, DEP-36, GDE-32, GDE-33, GDE-39, LEAD-01)
25. Fix the pager at section boundaries: `next: false` on About; Step 4's next is the Challenges overview; C10's next is Tear down; Tear down has no next. Give each landing page a distinct label ("Deploy overview", "Challenges overview" and so on). (LEAD-01, LEAD-02, LEAD-03, CHA-24)
26. Make links two-way: every prompt page opens with "Used in Cn, requirement m" and a link; the prompts index links its When column; C2 links the ALZ-lite guide and the naming and IP plan; C3 links the Arc guide; C5 links the APEX guide from "Where to work"; the GitHub Copilot upgrade guide links C7, C8 and C9; C3, C4 and C5 end with a "Next" line. (GDE-06, GDE-07, CHA-32, CHA-39, GDE-31, CHB-45)
27. Link Tear down from C10 and from a new "After the event (T+2)" section in Event overview and Roles; link Troubleshooting from every Deploy step and from challenge hints. (START-08, CRF-30, DEP-39)
28. Fix the anchors that land in the wrong place: the playbook's two `#set-up-vm-dev01` links become `#33-set-up-vm-dev01`; the GitHub Copilot upgrade guide links 3.3, not 3.4; C3 links 3.2. List Steps 1 to 4 in order, including vending, on the Getting started overview. (GDE-41, CHB-11, GDE-11, CHA-35, START-06)
29. Label coach pages instead of hiding them (decision 15): end the H1 of every coach source (`coach/*.md`, `facilitator/agenda.md`, `facilitator/automation-map.md`) with "(coach)", so search results show it. The loader strips " answer key" but keeps the label. (LEAD-09)
30. Apply the Fix column of this theme's remaining findings listed below, P2 first, within the code-change rule.

## Findings in scope

- **P1:** LEAD-01
- **P2:** CRF-30, DEP-08, DEP-17, GDE-06, GDE-07, GDE-11, LEAD-02, START-06, START-16
- **P3:** CHA-22, CHA-24, CHA-32, CHA-35, CHA-36, CHA-39, CHB-11, CHB-20, CHB-23, CHB-24, CHB-42, CHB-45, DEP-36, DEP-39, GDE-25, GDE-26, GDE-31, GDE-32, GDE-33, GDE-41, GDE-42, GDE-43, GDE-44, LEAD-03, LEAD-09, START-19, START-30, START-33

## Acceptance criteria

- [ ] The sidebar matches the report's proposal (section 3) and no URL changed.
- [ ] No attendee page's Next link leads into `/coach/`; Step 4, C10, Tear down and About have the specified pager links.
- [ ] Every prompt and guide links to its challenges and back; C3, C4 and C5 end with a Next line.
- [ ] Tear down is linked from C10, Event overview and Roles; Troubleshooting is linked from every Deploy step; the anchors land on the right headings.
- [ ] Every coach page title ends in "(coach)".
- [ ] `npm run check`, the site build, `lint:prose` and `scripts/check-internal-links.mjs` pass, and the diff has no logic changes outside T01 requirement 1.
- [ ] The PR body lists every finding ID it closes, and any it leaves open with the reason.

## Rules

Follow AGENTS.md: draft PR, conventional commit, no identifiers, never push to main. Code-change rule: docs, sidebar config, frontmatter and text-only string edits; no logic changes except T01 requirement 1. Anything that needs code goes under Follow-ups. Stop and ask before changing points or a URL.
```

---

## T06: Publish the coach material needed on event days

**Title:** `Site review T06: Publish the coach material needed on event days`

**Labels:** `documentation`, `site-review`, `P1`, `needs-owner-action`

```markdown
Part of B24, the October 2026 site review. Spec: docs/review/2026-10-29/factory-site-copilot-spec.md, requirements 31 to 37. Evidence and the fix for every finding ID: docs/review/2026-10-29/factory-site-review-findings.md.

## Problem

Coach pages are generated from `coach/` and `facilitator/agenda.md`, but the scoring rules, badges, curveballs, APEX demo script and most of the facilitator guide stay on GitHub. Lifelines is reachable only from the coach index and C7. The loader drops C2's bonus and the readiness page's audience note.

## Why it matters

A coach running the day from the site misses the Day 1 curveball and can't award badges or apply the bonus cap.

## Decisions

Fold the full-ALZ demo into the kickoff (decision 6). 🧑 HUMAN: the owner adds the slides or recording to the kickoff deck. Numbers follow the Decisions table in the spec.

## What to change

31. Publish the coach material without code changes. The coach loader renders every `coach/*.md` file, so move `facilitator/curveballs.md`, `facilitator/apex-demo.md` and `facilitator/scoreboard.md` into `coach/` (they appear at `/coach/curveballs/`, `/coach/apex-demo/` and `/coach/scoreboard/`). Move the rubric's "Scoring rules", "Badges" and "Challenge bonus tasks" sections into `coach/scoreboard.md`; leave the base-points table and the `### Cn —` evidence sections in `facilitator/scoring-rubric.md`, which the loader and the content check read, and update the rubric's opening line to say where the rules now live. Update every link to the moved files (`coach/c07-migrate-and-go-live.md`, `facilitator/cleanup.md`, `facilitator/guide.md`, and the moved files' own relative links) and add the three pages to the Coach sidebar. Add a 10:15 curveball row to the agenda and a curveball section to the C2 sheet. Link the coach sections of `facilitator/guide.md` (lifeline handout, escalation table, kickoff duties, coach ratio) from the agenda page. Without a loader change, other coach pages can't link to the new pages as site routes: point to the sidebar entry instead of linking. (CRF-03, CRF-04, CRF-05, CRF-20)
32. Add Lifelines to the Coach sidebar, and a Lifelines section (L1 to L4, the 15-of-30 cap, how to record use) to the C6 sheet. (CRF-06, CRF-17)
33. Work around the two loader bugs in content: reword the C2 sheet's bonus line to "Up to 5 bonus points (member, under the shared 30-point cap)" so `/coach/` shows it, and on the readiness page put the audience note in a plain paragraph before the leading alert so the loader doesn't strip it. (CRF-10, CRF-12)
34. Order and name the Coach group as in the report: Coach overview, Two-day agenda, Readiness check, C1 to C10, Lifelines, Scoreboard and badges, Curveballs, APEX demo script, Automation map, Repair: deploy with scripts. Use "Readiness check" everywhere, and "attendee" or "member" rather than "participant" in coach sources. (CRF-18, CRF-19, LEAD-07)
35. Fold the full-ALZ demo into the 08:30 kickoff (decision 6): reword the ALZ-lite guide ("A full Azure Landing Zone, as the portal accelerator deploys it, adds the following") with a Learn link; update `facilitator/guide.md`'s coach role, the agenda's kickoff row and the "Full ALZ (coach demo)" column in `infra/foundation/README.md`. 🧑 HUMAN: the owner adds two or three slides (or a short recording) to the kickoff deck. (CRF-22, GDE-14)
36. Coach sources: use repo-relative links (`../site/src/content/docs/...`) instead of `https://factory.apexops.pro/...`; keep the manual repair page to the scope AGENTS.md allows, with the parameters the stages pass. (LEAD-04, CRF-45, CRF-15, CRF-16, CRF-44)
37. Apply the Fix column of this theme's remaining findings listed below, P2 first, within the code-change rule.

## Findings in scope

- **P1:** CRF-03, CRF-04, CRF-05, CRF-06
- **P2:** CRF-10, CRF-12, CRF-15, CRF-16, CRF-17, CRF-18, CRF-19, CRF-20, CRF-22, CRF-31, GDE-14
- **P3:** CHA-34, CHA-47, CHB-35, CHB-39, CRF-32, CRF-33, CRF-34, CRF-35, CRF-36, CRF-37, CRF-38, CRF-44, CRF-45, CRF-46, CRF-47, CRF-48, LEAD-04, LEAD-07, START-18, START-29

## Acceptance criteria

- [ ] Scoreboard and badges, Curveballs and APEX demo script render as coach pages (moved from `facilitator/`); the rubric keeps its base-points table and evidence sections, and `npm run check` passes.
- [ ] The agenda has the 10:15 curveball row; Lifelines is in the Coach sidebar and on the C6 sheet.
- [ ] `/coach/` shows C2's bonus as up to 5 points; the readiness page shows its own audience note.
- [ ] The Coach group follows the proposed order, and no absolute `factory.apexops.pro` links remain in `coach/` or `facilitator/`.
- [ ] The ALZ-lite guide, the facilitator guide, the agenda and the foundation README no longer promise a live demo.
- [ ] `npm run check`, the site build, `lint:prose` and `scripts/check-internal-links.mjs` pass, and the diff has no logic changes outside T01 requirement 1.
- [ ] The PR body lists every finding ID it closes, and any it leaves open with the reason.

## Rules

Follow AGENTS.md: draft PR, conventional commit, no identifiers, never push to main. Code-change rule: docs, sidebar config, frontmatter and text-only string edits; no logic changes except T01 requirement 1. Anything that needs code goes under Follow-ups. Stop and ask before changing points or a URL.
```

---

## T07: Align challenge evidence with the rubric and scripts; fix recovery paths

**Title:** `Site review T07: Align challenge evidence with the rubric and scripts; fix recovery paths`

**Labels:** `documentation`, `site-review`, `P1`

```markdown
Part of B24, the October 2026 site review. Spec: docs/review/2026-10-29/factory-site-copilot-spec.md, requirements 38 to 49. Evidence and the fix for every finding ID: docs/review/2026-10-29/factory-site-review-findings.md.

## Problem

Individually small, together significant: a policy name that doesn't exist, an exemptions table that's normally empty, evidence paths that land on the wrong branch, recovery steps that fail in a new terminal, a C8 verdict rule that contradicts the script, templates missing the columns the rubric scores, and missing day/time lines on C4 to C10.

## Why it matters

Members lose points for doing the right thing, and coaches can't sign off consistently.

## Decisions

"None needed" is valid exemptions evidence (decision 2); rollback after cutover is out of scope (decision 11); the curveball is the team lead's evidence only (decision 12). Numbers follow the Decisions table in the spec.

## What to change

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
49. Apply the Fix column of this theme's remaining findings listed below, P2 first, within the code-change rule.

## Findings in scope

- **P1:** CHA-01, CHA-02, CHA-03, CHA-04, CRF-02, GDE-01
- **P2:** CHA-06, CHA-08, CHA-09, CHA-10, CHA-11, CHA-12, CHA-13, CHA-15, CHA-17, CHA-18, CHA-19, CHA-20, CHB-01, CHB-02, CHB-03, CHB-04, CHB-07, CHB-08, CRF-23, CRF-28, DEP-11, DEP-12, DEP-18, GDE-05, GDE-12
- **P3:** CHA-26, CHA-27, CHA-28, CHA-29, CHA-30, CHA-40, CHA-43, CHA-45, CHA-46, CHA-48, CHA-49, CHB-12, CHB-15, CHB-16, CHB-17, CHB-19, CHB-26, CHB-27, CHB-29, CHB-32, CHB-34, CHB-36, CHB-37, CHB-38, CHB-41, CHB-44, DEP-21, DEP-23, DEP-24, DEP-27, DEP-28, DEP-38, DEP-42, GDE-21, GDE-22, GDE-40, START-28

## Acceptance criteria

- [ ] `alzl-deny-public-acr` appears nowhere in the repo.
- [ ] C2, C4, the rubric (wording only) and the badge accept "no exemptions needed" with a deferred-work entry.
- [ ] C5's recovery works in a new terminal, and C5 has the SQL MI licence check; prompt 07 saves triage evidence to the member's repo on `main`.
- [ ] C8's ACCEPT rule matches `Test-Acceptance.ps1`; both copies of the C10 gap register have Owner and Next step columns; C7 says rollback after cutover is out of scope.
- [ ] Every challenge page shows day, start time, time box, scope and points.
- [ ] `npm run check`, the site build, `lint:prose` and `scripts/check-internal-links.mjs` pass, and the diff has no logic changes outside T01 requirement 1.
- [ ] The PR body lists every finding ID it closes, and any it leaves open with the reason.

## Rules

Follow AGENTS.md: draft PR, conventional commit, no identifiers, never push to main. Code-change rule: docs, sidebar config, frontmatter and text-only string edits; no logic changes except T01 requirement 1. Anything that needs code goes under Follow-ups. Stop and ask before changing points or a URL.
```

---

## T08: Make Tear down safe, complete and linked

**Title:** `Site review T08: Make Tear down safe, complete and linked`

**Labels:** `documentation`, `site-review`, `P1`

```markdown
Part of B24, the October 2026 site review. Spec: docs/review/2026-10-29/factory-site-copilot-spec.md, requirements 50 to 52. Evidence and the fix for every finding ID: docs/review/2026-10-29/factory-site-review-findings.md.

## Problem

Tear down is the thinnest page: no Who/When, no checklist, no verification, a "tick box" for a CLI input, a default that contradicts `cleanup.md`, and a duration that ignores SQL MI deletion. Getting Started never mentions T+2.

## Why it matters

Irreversible deletes with unpushed work, or resources left running and billing.

## Decisions

Delete rg-management and the Graph grant unless the tenant will be reused (decision 8). Numbers follow the Decisions table in the spec.

## What to change

50. Rebuild `deploy/tear-down.mdx`: a Who/When line and "(T+2)" in the title; a "Before you run teardown" checklist (scores signed off, `git branch -vv` shows `vm-dev01-work` pushed, evidence on `main`, settings values noted, the event owner's go); the command lines from T01 (the team lead's full teardown needs `-f members=all -f confirm-team-teardown=true`); the default from decision 8: add `-f include-management=true` unless the event owner will reuse the tenant (the next event then needs the Graph grant again); who the admin is in each repo and what they need; real durations (about 20 minutes without an archetype, up to about 2 hours with SQL MI; don't cancel); a final check that the resource groups are gone; links to Troubleshooting and Cost. (DEP-06, DEP-13, DEP-14, DEP-15, DEP-40, DEP-41, CRF-43)
51. Correct the team-teardown claims in `facilitator/platform-pipeline.md` and the automation map, and make `facilitator/cleanup.md` and `facilitator/guide.md` match the new commands. (CRF-21, CRF-46)
52. Apply the Fix column of this theme's remaining findings listed below, P2 first, within the code-change rule.

## Findings in scope

- **P1:** DEP-06
- **P2:** CRF-21, DEP-13, DEP-14, DEP-15, START-08
- **P3:** CRF-43, DEP-40, DEP-41

## Acceptance criteria

- [ ] Tear down has a Who/When line, a pre-delete checklist, the team lead's full command, the include-management default, a named admin per repo, real durations, a final check and links to Troubleshooting and Cost.
- [ ] `facilitator/platform-pipeline.md`, `facilitator/cleanup.md`, `facilitator/guide.md` and the automation map agree with the page.
- [ ] `npm run check`, the site build, `lint:prose` and `scripts/check-internal-links.mjs` pass, and the diff has no logic changes outside T01 requirement 1.
- [ ] The PR body lists every finding ID it closes, and any it leaves open with the reason.

## Rules

Follow AGENTS.md: draft PR, conventional commit, no identifiers, never push to main. Code-change rule: docs, sidebar config, frontmatter and text-only string edits; no logic changes except T01 requirement 1. Anything that needs code goes under Follow-ups. Stop and ask before changing points or a URL.
```

---

## T09: Refresh product references, outside links and validated-on dates

**Title:** `Site review T09: Refresh product references, outside links and validated-on dates`

**Labels:** `documentation`, `site-review`, `P2`, `needs-owner-action`

```markdown
Part of B24, the October 2026 site review. Spec: docs/review/2026-10-29/factory-site-copilot-spec.md, requirements 53 to 58. Evidence and the fix for every finding ID: docs/review/2026-10-29/factory-site-review-findings.md.

## Problem

Microsoft Learn has moved on in places: the upgrade dashboard isn't in VS Code, the agent starts with `@upgrade`, Upgrade Assistant is deprecated, App Insights "Transaction search" is now Search, the OpenTelemetry distro guidance changed, and five links redirect. Time-sensitive pages carry no "validated on" date.

## Why it matters

Instructions that worked in the dry run fail on event day.

## Decisions

Pin the validated versions and add one fallback line (decision 5; 🧑 HUMAN: the owner re-tests before the dry run); keep the Azure Monitor OpenTelemetry distro with a note (decision 13). Numbers follow the Decisions table in the spec.

## What to change

53. Upgrade dashboard (decision 5): C3, C6, prompts 01 and 02, the playbook and the GitHub Copilot upgrade guide say "validated with the GitHub Copilot upgrade extension 1.1.612 on VS Code 1.139.0" (from `versions.md`) and add one fallback line: "If no dashboard opens, ask Copilot to show `plan.md` and `tasks.md`." 🧑 HUMAN: the owner re-tests on the current extension before the dry run and updates `versions.md`. (GDE-02, CHA-16, CHB-14, GDE-30)
54. Replace references Learn has moved on from: the Upgrade Assistant link (GDE-16); "Transaction search" is now Search in the page, both template copies and the coach sheet (CHB-05); CAF Strategy motivations (CHA-07); the Copilot app's plugin install steps (GDE-15). OpenTelemetry (decision 13): C6 says the kit uses the Azure Monitor OpenTelemetry Distro (validated) and that Learn now recommends the Microsoft OpenTelemetry Distro for new apps; no code change. (CHB-13)
55. Point the five redirected links at their canonical pages. (LEAD-05, CHB-24, CHB-42, CHA-31)
56. Learning path: AZ-305 earns the Expert certification only with AZ-104; refresh the outline dates and the Last validated date. (GDE-08, GDE-17, GDE-18)
57. Add a "Validated on" date to every page with fast-changing UI labels or product facts: Requirements, Cost, Availability zones, the GitHub Copilot upgrade guide, the prompts, and C7's portal steps. (START-34, CHB-22, CRF-24)
58. Apply the Fix column of this theme's remaining findings listed below, P2 first, within the code-change rule.

## Findings in scope

- **P2:** CHA-07, CHA-16, CHB-05, GDE-02, GDE-08, GDE-15, GDE-16
- **P3:** CHA-31, CHA-38, CHA-42, CHB-13, CHB-14, CHB-22, CHB-31, CRF-39, DEP-25, DEP-26, GDE-17, GDE-18, GDE-19, GDE-20, GDE-23, GDE-24, GDE-30, GDE-38, LEAD-05, START-34

## Acceptance criteria

- [ ] C3, C6, prompts 01 and 02, the playbook and the GitHub Copilot upgrade guide name the validated versions and carry the fallback line.
- [ ] Deprecated or renamed references are replaced, C6 carries the OpenTelemetry note, and the five redirected links point at their canonical pages.
- [ ] The learning path's dates are refreshed, and time-sensitive pages show a validated-on date.
- [ ] `npm run check`, the site build, `lint:prose` and `scripts/check-internal-links.mjs` pass, and the diff has no logic changes outside T01 requirement 1.
- [ ] The PR body lists every finding ID it closes, and any it leaves open with the reason.

## Rules

Follow AGENTS.md: draft PR, conventional commit, no identifiers, never push to main. Code-change rule: docs, sidebar config, frontmatter and text-only string edits; no logic changes except T01 requirement 1. Anything that needs code goes under Follow-ups. Stop and ask before changing points or a URL.
```

---

## T10: Use one term per concept and extend the glossary

**Title:** `Site review T10: Use one term per concept and extend the glossary`

**Labels:** `documentation`, `site-review`, `P2`

```markdown
Part of B24, the October 2026 site review. Spec: docs/review/2026-10-29/factory-site-copilot-spec.md, requirements 59 to 61. Evidence and the fix for every finding ID: docs/review/2026-10-29/factory-site-review-findings.md.

## Problem

The writing is clear; the problems are naming. Challenge items are "requirements" on the pages and "tasks" in the progress bar, playbook and coach sheets. GHCP and GitHub Copilot alternate in titles. The glossary misses about 40 acronyms and product names the site uses. Vale doesn't run on the coach and facilitator sources.

## Why it matters

Small frictions that add up for first-time attendees.

## Decisions

None needed. Numbers follow the Decisions table in the spec.

## What to change

59. Add the missing glossary entries (CAF, ALZ, AHB, ACR, KPI, CVE, MSMQ, SSMS, MFA, RBAC, OIDC, NSG, NAT gateway, DNS proxy, DeployIfNotExists, MCP, Copilot CLI, agent mode, As-Built, playbook, roster, shared services subscription, workload subscription, Corp management group, T+2, tech lead, event owner, Privileged Role Administrator, and the Azure services the site names). (CRF-29)
60. One term per concept: "requirement" for challenge items, including the progress bar (text only); "GitHub Copilot" in titles and sidebar labels (keep GHCP only if the glossary defines it); "Getting started" in sentence case; one form of Day 1 / day one; "hackathon" on the 404 page (text only); member, attendee, team lead, coach and event owner as the only persona words. (CHA-21, CHB-10, START-21, GDE-37, CHA-36, START-30, LEAD-06, CHB-28, LEAD-07)
61. Apply the Fix column of this theme's remaining findings listed below, P2 first, within the code-change rule.

## Findings in scope

- **P2:** CRF-29
- **P3:** CHA-21, CHA-25, CHA-41, CHA-44, CHB-09, CHB-10, CHB-28, CHB-30, CHB-33, CRF-41, CRF-42, DEP-32, DEP-37, GDE-28, GDE-29, GDE-34, GDE-35, GDE-36, GDE-37, GDE-39, LEAD-06, LEAD-08, START-21, START-22, START-24, START-25, START-27, START-31, START-32, START-39, START-40, START-41

## Acceptance criteria

- [ ] The glossary covers the listed terms.
- [ ] Challenge items are "requirements" everywhere, including the progress bar; titles say GitHub Copilot; "Getting started" is in sentence case; the 404 page says hackathon.
- [ ] `npm run check`, the site build, `lint:prose` and `scripts/check-internal-links.mjs` pass, and the diff has no logic changes outside T01 requirement 1.
- [ ] The PR body lists every finding ID it closes, and any it leaves open with the reason.

## Rules

Follow AGENTS.md: draft PR, conventional commit, no identifiers, never push to main. Code-change rule: docs, sidebar config, frontmatter and text-only string edits; no logic changes except T01 requirement 1. Anything that needs code goes under Follow-ups. Stop and ask before changing points or a URL.
```
