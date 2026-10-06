# B15: Publish the partner learning path

| Field | Value |
|---|---|
| Issue | #44 (B14 onwards, the issue number isn't the item number) |
| Milestone | P4 Content |
| Type | Agent |
| Depends on | B11 |
| Unblocks | — |
| Effort | 1 day |
| Cost | None |
| Teardown | Not applicable: nothing is deployed |
| PRD | §2 Learning path; §3; §5; §7 Deliverables 6 |

## Outcome

- The site has a **Partner learning path** page under Guides. For each factory challenge, it says which Microsoft Learn content and which credential build on that challenge.
- Partners can see which role takes which exam, in what order, and how this meets the skilling requirements of the Infra and Database Migration and App Modernization specializations.
- The page has a last-validated date, and every exam status on it was checked that day.

## Before you start

1. B11 is closed. The challenge pages exist in `site/src/content/docs/challenges/`.
2. `npm run check` passes on `main`.

## Requirements

### Scope (owner decisions 2026-10-06)

1. **Audience:** Microsoft partners, mostly infra architects and engineers, with app and DB work Copilot-assisted. Nothing on the page depends on the partner's qualification track. Where a designation gate counts certified people, plan for **two per gate**, which covers every track.
2. **Hands-on first:** exams come after the event and finish within 6 months (T+180 days). Before the event, Stage 0 is learning only, with no exam gates.
3. **Applied Skills** are recommended stepping stones, never gates.
4. **Coaches:** GH-300 plus DP-300 or AZ-104 is recommended, not required.
5. **No exam offers, vouchers or prices.** English only. Link only public pages on `learn.microsoft.com`, `docs.github.com` and `partner.microsoft.com`. No Microsoft-internal content (PRD §9).

### Page

6. Create `site/src/content/docs/guides/learning-path.md`, titled **Partner learning path**, with these sections in order: **Who it's for**, **Stages**, **Role tracks**, **Challenge map**, **Partner Center outcomes**, **Next: enable AI tomorrow**, **Last validated**.
7. **Stages:** a table with when, goal, content and exit evidence for each stage:

   | Stage | When | Content |
   |---|---|---|
   | 0 Ready | T-30 to T-3 | AZ-104 networking, identity and governance modules; GitHub Copilot Fundamentals Part 1; the Arc SQL migration assessment docs; GH-900 path (optional); Applied Skill "Accelerate AI-assisted development by using GitHub Copilot" (recommended) |
   | 1 Hack | T-0 | The factory, C0–C10 |
   | 2 Certify core | T+0 to T+60 days | AZ-104, GH-300, DP-300, by role |
   | 3 Specialize | T+60 to T+180 days | AZ-305, AZ-400 (DevOps Engineer Expert), SC-500, AZ-700; AI-200 for the developer track; the AKS (AZ-1001) and Azure Container Apps (AZ-2003) learning paths |
   | 4 Next (optional) | Within the 6 months | DP-800, GH-600, AI-103 |

8. **Role tracks:** a table that gives each role its core exam, its specialize exams, its optional "next" exam and the challenges it owns:

   | Role | Core | Specialize | Next | Challenges |
   |---|---|---|---|---|
   | Platform lead | AZ-104 | AZ-700, AZ-305, SC-500 | — | C2, C5, C8 |
   | Workload engineer | AZ-104, GH-300 | AZ-400; AKS and Container Apps paths | GH-600 | C3, C5, C6, C8 |
   | Data/DB specialist | DP-300 | SC-500 or AZ-104 | DP-800 | C3, C4, C7, C9 |
   | App modernization developer | GH-300 | AI-200, AZ-400; AKS and Container Apps paths | GH-600, AI-103 | C6, C8 |
   | Coach / CoE lead | Recommended: GH-300 plus DP-300 or AZ-104 | AZ-305 | GH-600 | All, as coach |
   | Practice lead | No exam needed | AZ-305 (optional) | — | Runs the event |

9. **Challenge map:** one row for each challenge C0–C10. Each row links to that challenge's page and lists the skills it exercises, one to three Learn links and the credential that validates it. Add a final **Beyond v1: AKS and Container Apps** row: the same container on AKS or Container Apps, validated by AI-200, SC-500 and AZ-104. Credentials per challenge:

   | Challenge | Credential |
   |---|---|
   | C0 | AZ-104, GH-300 |
   | C1 | AZ-305 |
   | C2 | AZ-104, AZ-700, SC-500, AZ-305 |
   | C3 | DP-300, GH-300 |
   | C4 | AZ-305, DP-300 |
   | C5 | AZ-104, DP-300, GH-600 |
   | C6 | GH-300 (AI-200 for the developer track) |
   | C7 | DP-300 |
   | C8 | SC-500, AZ-104 |
   | C9 | DP-300, DP-800 |
   | C10 | AZ-305, GH-600 |

10. Map each PRD §5 badge to the exam domain that validates it, for example "trust but verify" to GH-300 "Use GitHub Copilot responsibly".
11. **Partner Center outcomes:**
    - The skilling groups for both specializations. Each specialization also needs an active Solutions Partner designation.
    - A sample plan for five people that covers both specializations:
      - platform lead: AZ-104, AZ-305, AZ-700;
      - DevOps: AZ-104, AZ-400, GH-300;
      - data: DP-300, DP-800;
      - security: AZ-104, SC-500;
      - developer: AI-200.
    - A line saying to plan for two AZ-104 and two AZ-305 holders, for the designation gates.
    - A sentence saying requirements change and Partner Center is the source of truth.
12. **Retired exams:** don't recommend AZ-204, AZ-500, AZ-800, AZ-801 or AI-102. Name each replacement once (AI-200, SC-500, AI-103; AZ-700 for Infrastructure points), and note that certifications earned before retirement still count for one year.
13. 🔎 VERIFY the status and skills-outline date of every exam on the page. Use its study guide (`https://learn.microsoft.com/credentials/certifications/resources/study-guides/<exam>`) and [Exam and assessment lab retirement](https://learn.microsoft.com/credentials/support/retired-certification-exams).
14. 🔎 VERIFY the specialization skilling against [Infra and Database Migration](https://partner.microsoft.com/en-us/partnership/specialization/infra-and-database-migration) and [App Modernization](https://partner.microsoft.com/en-us/partnership/specialization/app-modernization-on-microsoft-azure). Also verify the designation gates against [Solutions Partner for Data & AI, Infrastructure, and Digital & App Innovation](https://learn.microsoft.com/partner-center/membership/solutions-partner-azure).
15. **Last validated:** the date you ran requirements 13 and 14.

### Links into the page

16. Link the page from `site/src/content/docs/guides/index.md` and from `site/src/content/docs/getting-started/index.md`. In getting started, the link is a "learning before the event" pointer to Stage 0.

## Deliverables

- `site/src/content/docs/guides/learning-path.md`
- `site/src/content/docs/guides/index.md`
- `site/src/content/docs/getting-started/index.md`

## Verify

- `npm run check` passes.
- The challenge map links all eleven challenge pages, and the site build resolves them.
- Every external link returns HTTP 200. List them in the PR body with the date checked.
- No offers, vouchers, prices, Enterprise or SMB wording, or retired exams recommended as targets: `Select-String -Path site/src/content/docs/guides/learning-path.md -Pattern 'voucher|discount|price|Enterprise track|SMB'` returns nothing.

## Done when

- [ ] The page is published on the site with a last-validated date.
- [ ] The PR body lists the result of every 🔎 VERIFY, including any change from this runbook.

## Commit message

```text
docs: add the partner learning path page
```

## Stop and ask if

- A 🔎 VERIFY shows an exam in this runbook retired, renamed or replaced.
- A specialization's skilling groups differ from requirement 11.
- It's still unclear whether DP-800 is a fifth required group for Infra and Database Migration or an alternative to DP-300. The partner page lists it after the database administrator group without "OR".

## Notes and traps

- **Fast-moving exams:** GH-300's outline changed on 2026-08-07, DP-800's on 2026-10-19 and DP-300's on 2026-10-27. Link to the study guides and don't copy their skills lists.
- **Partner Center lag:** the Infrastructure designation still lists Windows Server Hybrid Administrator, although AZ-800 and AZ-801 retired on 2026-09-30. Don't recommend them.
- **AZ-400 prerequisite:** AZ-104 or Azure Developer Associate. Whether AI-200 counts isn't confirmed, so route infra people through AZ-104.
- **AI-200 fit:** it's Python-oriented and covers Cosmos DB, PostgreSQL vectors and Redis, so keep it on the developer track only.
- **Arc and MI link:** there's no standalone Arc credential: the Arc-enabled servers Applied Skill retired on 2026-01-30. DP-300 covers Arc-enabled SQL use cases and online migration, but doesn't name MI link.
- **AKS:** v1 runs on App Service only. AKS and Container Apps are learning content, not a kit path (PRD §1 non-goals).
