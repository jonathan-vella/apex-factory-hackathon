import assert from "node:assert/strict";
import { mkdtemp, mkdir, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { runChecks } from "../scripts/check-content-invariants.mjs";

test("a team template that differs from, or is missing next to, its attendee template is blocked", async () => {
  const root = await mkdtemp(join(tmpdir(), "apex-microhack-invariants-"));
  try {
    await mkdir(join(root, "templates/attendee"), { recursive: true });
    await mkdir(join(root, "templates/team/templates"), { recursive: true });
    await writeFile(join(root, "templates/attendee/adr.md"), "# ADR\n");
    await writeFile(join(root, "templates/team/templates/adr.md"), "# ADR changed\n");
    await writeFile(join(root, "templates/attendee/only-attendee.md"), "# Only here\n");
    const result = await runChecks(root);
    const text = result.failures.join("\n");
    assert.match(text, /templates\/team\/templates\/adr\.md: differs from/);
    assert.match(text, /templates\/team\/templates\/only-attendee\.md: missing/);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("an evidence rule page without the two bullets is blocked", async () => {
  const root = await mkdtemp(join(tmpdir(), "apex-microhack-invariants-"));
  try {
    await mkdir(join(root, "site/src/content/docs/guides"), { recursive: true });
    await writeFile(
      join(root, "site/src/content/docs/guides/ghcp-upgrade.md"),
      "- **Dev container:** evidence goes in `factory/evidence/` on `main`. Run `git pull` first.\n",
    );
    const result = await runChecks(root);
    assert.match(result.failures.join("\n"), /ghcp-upgrade\.md: missing the evidence rule bullet/);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("the scoring contract has ten challenges and no C0", async () => {
  const root = await mkdtemp(join(tmpdir(), "apex-microhack-invariants-"));
  try {
    await mkdir(join(root, "facilitator"), { recursive: true });
    await writeFile(join(root, "facilitator/scoring-rubric.md"), "# Scoring rubric\n");
    const result = await runChecks(root);
    const text = result.failures.join("\n");
    assert.match(text, /scoring-rubric\.md: missing C1 evidence table/);
    assert.match(text, /scoring-rubric\.md: missing C10 evidence table/);
    assert.doesNotMatch(text, /missing C0 evidence table/);
    assert.doesNotMatch(text, /c00-ready-to-hack/);
    assert.match(text, /expected 170 base points/);
    assert.match(text, /expected 750 total minutes/);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("retired artifact in an Astro component is blocked", async () => {
  const root = await mkdtemp(join(tmpdir(), "apex-microhack-invariants-"));
  try {
    await mkdir(join(root, "site/src/components"), { recursive: true });
    await writeFile(join(root, "site/src/components/retired.astro"), "07-ab-operations-guide.md");
    const result = await runChecks(root);
    assert.match(result.failures.join("\n"), /retired operations artifact name/);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("a challenges overview row that differs from challenges.json is blocked", async () => {
  const root = await mkdtemp(join(tmpdir(), "apex-microhack-invariants-"));
  try {
    await mkdir(join(root, "site/src/content/docs/challenges"), { recursive: true });
    await writeFile(
      join(root, "site/src/content/docs/challenges/c01-define-the-opportunity.md"),
      "# C1\n",
    );
    await writeFile(
      join(root, "site/src/content/docs/challenges/index.md"),
      "| Day 1 | [C1: Define the opportunity](./c01-define-the-opportunity/) | Team | 50 min | 10 | All six, in order |\n",
    );
    const result = await runChecks(root);
    assert.match(result.failures.join("\n"), /index\.md: the C1 row must read/);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});
