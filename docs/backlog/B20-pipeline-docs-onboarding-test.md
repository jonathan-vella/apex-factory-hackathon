# B20: Write the student and coach docs and run the fresh-repo onboarding test

| Field      | Value                                                                                       |
| ---------- | ------------------------------------------------------------------------------------------- |
| Issue      | #128                                                                                        |
| Milestone  | P6 Platform automation                                                                      |
| Type       | Both                                                                                        |
| Depends on | B19                                                                                         |
| Unblocks   | The CoE archetype with Actions (later)                                                      |
| Effort     | 3–4 days elapsed                                                                            |
| Cost       | The onboarding test redeploys what-if and foundation only: about $1.30/hour while it exists |
| Teardown   | Remove everything the test created, with B19's scripts                                      |
| PRD        | §2 Platform pipeline; §8 pipeline identity risk                                             |

## Outcome

- Students and coaches have a page that gets them from an imported repo to a first green run. The identity risk is documented. A fresh repo is onboarded using only the docs.

## Before you start

1. B19 is closed (issue #127).

## Requirements

1. A site page for students and coaches (`site/src/content/docs/`) with copy-paste commands for setup, the first run and the doctor check, a "what it grants and why" box, the manual script path as a fallback, and troubleshooting entries.
2. `facilitator/platform-pipeline.md`: the coach page, with the accepted-risk entry for the pipeline identity, the gates, who can run what and the manual steps that remain (Graph grant, elevation, Arc assessment, subscription creation). Update `facilitator/automation-map.md`, `facilitator/cleanup.md` and `site/src/content/docs/reference/troubleshooting.md`.
3. 🧑 HUMAN: the onboarding test. Create a throwaway repo from the template, import the kit and onboard exactly as a student would, using only the docs. Record every stumble and fix the docs or scripts.
4. azd spike: decide go or no-go for an azd wrapper on the datacenter (subscription scope only) and record the reasons.
5. `versions.md` rows for `azure/login`, `actionlint` and the other new tools.

## Deliverables

- The site page, `facilitator/platform-pipeline.md`, the updated pages above, `docs/spikes/B20-pipeline-onboarding/README.md` (including the azd decision), `versions.md`.

## Verify

- `npm run check` passes. The onboarding test reaches a green what-if run using only the docs.

## Done when

- [ ] The fresh-repo test passed using only the docs.
- [ ] The risk is documented and the azd decision recorded.

## Commit message

```text
docs: add the platform pipeline guide and onboarding test
```

## Stop and ask if

- The docs can't get a fresh repo to green without changing a script's behaviour.

## Notes and traps

- Don't promise what wasn't tested: parallel vending and a private-repo reviewer gate are listed as tested or untested.
- Coach pages are public, on the honor system.
