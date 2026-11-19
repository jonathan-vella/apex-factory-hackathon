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

test("the challenge contract has ten challenges and no C0", async () => {
  const root = await mkdtemp(join(tmpdir(), "apex-microhack-invariants-"));
  try {
    await mkdir(join(root, "facilitator"), { recursive: true });
    const result = await runChecks(root);
    const text = result.failures.join("\n");
    assert.doesNotMatch(text, /c00-ready-to-hack/);
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

test("the overview must render the shared run sheet and challenge prose must match its metadata", async () => {
  const root = await mkdtemp(join(tmpdir(), "apex-microhack-invariants-"));
  try {
    await mkdir(join(root, "site/src/content/docs/challenges"), { recursive: true });
    await writeFile(
      join(root, "site/src/content/docs/challenges/c01-define-the-opportunity.md"),
      "# C1\n\n**Time and scope.** Day 2, **09:00**, **45 min**, **Member**.\n",
    );
    await writeFile(
      join(root, "site/src/content/docs/challenges/index.mdx"),
      "## The challenges\n\nA handwritten overview.\n",
    );
    const result = await runChecks(root);
    const text = result.failures.join("\n");
    assert.match(text, /index\.mdx: render ChallengeRunSheet/);
    assert.match(text, /c01-define-the-opportunity\.md: time and scope must match Day 1, 45 min, Team/);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});
