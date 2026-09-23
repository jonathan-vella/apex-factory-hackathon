# Roadmap

How v1 of the kit gets built. Scope and design are in the [PRD](prd.md). Work items are specs in the [backlog](backlog/README.md), each tracked as a GitHub issue, and each phase below is a milestone. A coding agent executes the items; the owner approves, answers 🧑 HUMAN steps and merges.

The kit is built in two subscriptions in the owner's tenant, mirroring one team: a shared services subscription and a workload subscription.

There's no event date yet, so the phases have no dates. Event gates are relative to the event day (T-0): preflight green at T-14, datacenter ready at T-3.

| Phase | Goal | Items | Exit criteria |
|---|---|---|---|
| P1 Skeleton and datacenter | Kit repo in place; the "on-premises" starting point deploys unattended | B00–B05 | Template repo public, site builds and lint passes. Build subscriptions ready and preflight script works. Legacy package published. Datacenter deploys unattended and runs the legacy app. Perf kit reproduces the planted issues |
| P2 Spikes | Prove the riskiest app and data paths | B06, B07 | GHCP golden path recorded on Contoso University. MI link seeds and cuts over on the free offer, or LRS is promoted |
| P3 Build | Build the reusable assets | B08–B10 | ALZ-lite, vending, probes and exemptions work across the two subscriptions. Archetype deploys from only tenant ID, subscription ID and suffix. Playbook, skills and lifelines published |
| P4 Content | Write what attendees and coaches use | B11, B12 | C0–C10 with module contracts and attendee templates. Facilitator kit complete |
| P5 Pilot and v1.0 | Validate end to end in partner-like conditions | B13 | Dry run meets the PRD success metrics. Time boxes and points tuned. `versions.md` validated. v1.0 release notes ready |

## Later

Candidates after v1, taken from the PRD non-goals when there's demand:

- AKS archetype.
- WebForms and WCF app tracks.
- An "Enable AI tomorrow" module that deploys AI services on the modernized platform.
- Production CI/CD.
- Multi-region.
