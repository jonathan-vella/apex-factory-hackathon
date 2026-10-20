---
title: Prompt library
description: Copy-paste prompts for the Upgrade agent workflow, split by where you run it.
sidebar:
  order: 1
---

Short, reusable prompts for the parts of the modernization work ([C3](../../challenges/c03-assess-the-source/),
[C6](../../challenges/c06-modernize-with-ghcp/), [C7](../../challenges/c07-migrate-and-go-live/) and
[C8](../../challenges/c08-validate-the-pattern/)) that aren't already a single paste like
[`plan-prompt.txt`](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/.github/modernization/plan-prompt.txt).
Each page is one prompt: what it's for, the exact text, and what to check afterward. They don't replace the
[playbook](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/.github/modernization/playbook.md),
the [GHCP upgrade guide](../guides/ghcp-upgrade/), or the challenge pages — those explain the *why* and the
acceptance bar; these are the *paste this*.

## Two tracks

| Track | Host | Status |
| --- | --- | --- |
| [VS Code](vscode/) | VS Code on `vm-dev01`, harness **Local** | The kit's validated golden path. Use this. |
| [Copilot App](ghcp-app/) | The GitHub Copilot app, on `vm-dev01` | Best-effort. The playbook's own CLI section already notes the Upgrade agent's tools sometimes don't attach in the app, with VS Code as the fallback. This track adds four prerequisites that measurably help, but isn't a guaranteed alternative. |

If you haven't chosen a track yet, use VS Code. Reach for the Copilot App track only if you specifically want to
try it, and keep VS Code as your fallback if a prompt's checks don't pass.
