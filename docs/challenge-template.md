# Challenge page template

Copy this to `site/src/content/docs/challenges/cNN-short-name.md` and fill it in. The page has five parts, in this order, the same as the secure-networking hackathon: Background, Challenge, Requirements, Success criteria, References. Start the page at the front matter, not at this note.

Rules:

- The page says what the team must achieve and how they prove it. Keep it under about 6 KB. Long how-to material goes in a collapsible `<details>` under the requirement it serves, or in a guide under `/guides/`.
- One requirement is one outcome. Number them, so coaches and the evidence list can point at them.
- Every requirement appears in the success criteria. Every success criterion traces to a requirement.
- Write "you must" or "the team must". Don't write "should".
- No identifiers, and no "C0": the readiness check is not a challenge.
- Points and minutes must match `facilitator/scoring-rubric.md`. `npm run check` fails if they drift.

Copy from the line below.

---

```markdown
---
title: "CN: Short imperative name"
description: One sentence, under 160 characters, saying what the team achieves.
---

## Background

Two or three sentences on why this matters in the story of Contoso University's move to Azure.

**Objective.** One sentence beginning "Understand how to" or "Be able to".

**Time and points.** Team or member, N min, N pts (N team + N member).

## Challenge

The scenario and the facts the team needs, and nothing else.

- **Starting point.** What exists when you begin: the output of the earlier challenges, by name.
- **Fixed by the kit.** What you don't decide, so nobody spends time debating it.
- **You decide.** The choices that are yours.
- **Where to work.** Dev container, `vm-dev01` or the portal, in one line.

Add a diagram only if it saves words. Use the `Diagram` component.

## Requirements

1. **First outcome.** What must be true, in one sentence.

   <details>
   <summary>How</summary>

   Commands and clicks, only if the requirement needs them.

   </details>

2. **Second outcome.** Add one entry per outcome.

## Success criteria

To complete this challenge, show your coach:

- [ ] Evidence for requirement 1, saved as `factory/evidence/cNN/<file>`.
- [ ] Evidence for requirement 2.
- [ ] One thing you can explain: the decision, its alternative and its consequence.

Save your evidence under `factory/evidence/cNN/` in your own repo on `main`.

<details>
<summary>Hints</summary>

- A hint that unblocks without giving the answer.

</details>

<details>
<summary>If you need to start over</summary>

What is safe to repeat, what isn't, and who to ask.

</details>

**Bonus.** Up to N pts for X, or "None for CN."

## References

- [Link title](https://learn.microsoft.com/...)
```
