# Roadmap

How v1 of the kit gets built. Scope and design are in the [PRD](prd.md). Work items are specs in the [backlog](backlog/README.md), each tracked as a GitHub issue, and each phase below is a milestone. A coding agent executes the items; the owner approves, answers 🧑 HUMAN steps and merges.

The kit is built in two subscriptions in the owner's tenant, mirroring one team: a shared services subscription and a workload subscription.

There's no event date yet, so the phases have no dates. Event gates are relative to the event day (T-0): roster and every member's preflight green at T-14, ALZ-lite and the Graph grant at T-7, datacenter ready at T-3, vending at T-1.

| Phase | Goal | Items | Exit criteria |
|---|---|---|---|
| P1 Skeleton and datacenter | Kit repo in place; the "on-premises" starting point deploys unattended | B00–B05 | Template repo public, site builds and lint passes. Build subscriptions ready and preflight script works. Legacy package published. Datacenter deploys unattended and runs the legacy app. Perf kit reproduces the planted issues |
| P2 Spikes | Prove the riskiest app and data paths | B06, B07 | GHCP golden path recorded on Contoso University. MI link seeds and cuts over to a General Purpose MI, or LRS is promoted |
| P3 Build | Build the reusable assets | B08–B10, B14 | ALZ-lite, vending, probes and exemptions work across the two subscriptions. Archetype deploys from only tenant ID, subscription ID and suffix. Playbook, skills and lifelines published |
| P4 Content | Write what attendees and coaches use | B11, B12, B15 | C0–C10 with attendee templates. Facilitator kit complete. Partner learning path (B15) written and published on the site |
| P5 Pilot and v1.0 | Validate end to end in partner-like conditions | B13 | **Closed as not planned.** The full dry run didn't happen, so the whole event order hasn't been rehearsed. The original exit criteria stand as the goal: dry run meets the PRD success metrics, time boxes and points tuned, `versions.md` validated, v1.0 release notes ready |
| P6 Platform automation | GitHub Actions is the only way students deploy the datacenter, foundation and vending, and tear them down (scripts stay the engine and the coach's repair path). Easy onboarding, and the event is re-sequenced so the platform lead deploys the shared platform before it starts. Built and tested on a branch in a second, separate team so the working lab is untouched | B16–B23 | **Merged.** One command sets up the pipeline and one workflow runs it, in two profiles: the member's own repo (their datacenter, C0) and the platform lead's repo (ALZ-lite and vending for the team). The guard refuses a wrong subscription or prefix, and run logs redact GUIDs. ALZ-lite, vending and the datacenter deploy and tear down from Actions in the test lab. A fresh template repo onboards using only the docs. The identity risks are documented and its removal is scripted and verified. The event docs and rubric match the new order |

## Later

Candidates after v1, taken from the PRD non-goals when there's demand:

- The same Actions approach for the CoE archetype in the student's repo, once P6 is proven.
- AKS archetype.
- WebForms and WCF app tracks.
- An "Enable AI tomorrow" module that deploys AI services on the modernized platform.
- Production CI/CD.
- Multi-region.
