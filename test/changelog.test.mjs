import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { changelogBaseline, historicalChanges } from "../site/src/data/changelog-history.mjs";
import {
  cleanCommitTitle,
  formatChangelogDate,
  isBreakingChange,
  isDependencyBump,
  loadChangelog,
  publicCommitTitle,
} from "../site/src/lib/changelog.mjs";

const repoRoot = fileURLToPath(new URL("../", import.meta.url));

function git(cwd, args, env = {}) {
  return execFileSync("git", ["-C", cwd, ...args], {
    encoding: "utf8",
    env: { ...process.env, ...env },
    stdio: ["ignore", "pipe", "pipe"],
  }).trim();
}

function commit(cwd, subject, date, body, author = "Changelog test") {
  const args = ["commit", "--allow-empty", "--quiet", "-m", subject];
  if (body !== undefined) args.push("-m", body);
  git(cwd, args, {
    GIT_AUTHOR_DATE: date,
    GIT_COMMITTER_DATE: date,
    GIT_AUTHOR_NAME: author,
    GIT_AUTHOR_EMAIL: "test@example.invalid",
  });
  return git(cwd, ["rev-parse", "HEAD"]);
}

async function repository(t) {
  const cwd = await mkdtemp(join(tmpdir(), "factory-changelog-"));
  t.after(() => rm(cwd, { recursive: true, force: true }));
  git(cwd, ["init", "--quiet", "--initial-branch=main"]);
  git(cwd, ["config", "user.name", "Changelog test"]);
  git(cwd, ["config", "user.email", "test@example.invalid"]);
  git(cwd, ["config", "commit.gpgsign", "false"]);
  git(cwd, ["config", "core.hooksPath", join(cwd, "disabled-hooks")]);
  const baseline = commit(cwd, "Initial baseline", "2026-01-01T10:00:00Z");
  return { cwd, baseline };
}

test("curated history has unique first-parent sources with accurate UTC dates", () => {
  const output = execFileSync(
    "git",
    ["-C", repoRoot, "log", "--first-parent", "-z", "--format=%H%x00%cI%x00%s"],
    { encoding: "utf8" },
  );
  const fields = output.split("\0");
  assert.equal(fields.pop(), "");
  const commits = [];
  for (let i = 0; i < fields.length; i += 3) {
    commits.push({
      sha: fields[i],
      date: new Date(fields[i + 1]).toISOString().slice(0, 10),
      pr: /\(#(\d+)\)$/.exec(fields[i + 2])?.[1],
    });
  }
  assert.ok(commits.some(({ sha }) => sha === changelogBaseline));
  assert.equal(
    new Set(historicalChanges.map((change) => change.pr ?? change.commit)).size,
    historicalChanges.length,
  );
  assert.deepEqual(
    historicalChanges.map(({ date }) => date),
    historicalChanges
      .map(({ date }) => date)
      .toSorted()
      .reverse(),
  );
  for (const change of historicalChanges) {
    assert.equal(publicCommitTitle(change.title), change.title);
    const source = change.pr
      ? commits.find(({ pr }) => pr === String(change.pr))
      : commits.find(({ sha }) => sha === change.commit);
    assert.ok(source, `Missing historical source for ${change.pr ?? change.commit}`);
    assert.equal(source.date, change.date);
  }
});

test("dependency filtering keeps unrelated changes and security fixes", () => {
  for (const title of [
    "chore(deps): bump sharp from 1.0 to 2.0",
    "chore(deps-dev): bump the npm group",
    "chore(deps): Update a package to 1.9.1",
    "build(deps-prod)!: upgrade a package",
    "fix(deps): bump a package",
    "chore: update dependencies",
    "Bump the dev dependencies",
  ]) {
    assert.equal(isDependencyBump(title), true, title);
  }
  for (const title of [
    "fix: update dependencies behind security alerts",
    "fix(deps): update error handling",
    "docs: update the dependencies guide",
    "Bump the event score from 3 to 5",
  ]) {
    assert.equal(isDependencyBump(title), false, title);
  }
  assert.equal(isDependencyBump("Bump a package from 1.0 to 2.0", "dependabot[bot]"), true);
  assert.equal(isDependencyBump("Bump the event score from 3 to 5", "Changelog test"), false);
});

test("commit formatting preserves meaning and finds explicit breaking markers", () => {
  assert.equal(cleanCommitTitle("feat(api)!: change the setup (#42)"), "change the setup");
  assert.equal(cleanCommitTitle("fix: BREAKING: remove the old setup"), "remove the old setup");
  assert.equal(cleanCommitTitle("[BREAKING] remove the old setup"), "remove the old setup");
  assert.equal(cleanCommitTitle("T03: clarify requirements"), "T03: clarify requirements");
  assert.equal(
    publicCommitTitle("ci: update the lifeline build"),
    "Updated coach-only recovery material.",
  );
  assert.equal(
    publicCommitTitle("ci: publish the known-good image"),
    "Updated coach-only recovery material.",
  );
  assert.equal(
    publicCommitTitle("docs(coach): adjust the C6 points cap"),
    "Updated coach-only recovery material.",
  );
  assert.equal(
    publicCommitTitle("docs(coach): update the scoring cap"),
    "Updated coach-only recovery material.",
  );
  assert.equal(publicCommitTitle("docs: clarify the bonus cap"), "clarify the bonus cap");
  assert.equal(publicCommitTitle("docs: update setup"), "update setup");
  assert.equal(isBreakingChange("feat!: change the setup", ""), true);
  assert.equal(isBreakingChange("fix(api)!: change a contract", ""), true);
  assert.equal(
    isBreakingChange("docs: update setup", "BREAKING CHANGE: reset the configuration"),
    true,
  );
  assert.equal(
    isBreakingChange("docs: update setup", "BREAKING-CHANGE: reset the configuration"),
    true,
  );
  assert.equal(isBreakingChange("fix: BREAKING: remove the old setup", ""), true);
  assert.equal(isBreakingChange("[BREAKING] remove the old setup", ""), true);
  assert.equal(isBreakingChange("docs: update setup", "No breaking change was needed."), false);
  assert.equal(formatChangelogDate("2026-11-01"), "1 November 2026");
});

test("generates dated, linked entries from main commits without duplicating history", async (t) => {
  const { cwd, baseline } = await repository(t);
  const direct = commit(cwd, "docs: update setup (#37)", "2026-01-02T00:30:00+02:00");
  const security = commit(
    cwd,
    "fix: update dependencies behind security alerts",
    "2026-01-03T10:00:00Z",
  );
  const explicitSubject = commit(
    cwd,
    "fix: BREAKING: remove the old setup",
    "2026-01-03T11:00:00Z",
  );
  commit(cwd, "chore(deps-dev): bump the npm group", "2026-01-04T09:00:00Z");
  commit(cwd, "chore: update dependencies", "2026-01-04T09:15:00Z");
  commit(
    cwd,
    "Bump a package from 1.0 to 2.0",
    "2026-01-04T09:30:00Z",
    undefined,
    "dependabot[bot]",
  );
  const footer = commit(
    cwd,
    "docs: change the preparation",
    "2026-01-04T10:00:00Z",
    "BREAKING-CHANGE: the old preparation no longer works",
  );
  const coach = commit(cwd, "ci: update the lifeline build", "2026-01-04T11:00:00Z");
  const marked = commit(cwd, "feat(api)!: change the interface (#42)", "2026-01-05T10:00:00Z");
  const groups = loadChangelog({
    cwd,
    ref: "HEAD",
    baseline,
    history: [{ date: "2026-01-01", title: "Historical baseline", commit: baseline }],
  });
  assert.deepEqual(
    groups.map(({ date }) => date),
    ["2026-01-05", "2026-01-04", "2026-01-03", "2026-01-01"],
  );
  const changes = groups.flatMap((group) => group.changes);
  assert.deepEqual(
    changes.map(({ title }) => title),
    [
      "change the interface",
      "Updated coach-only recovery material.",
      "change the preparation",
      "remove the old setup",
      "update dependencies behind security alerts",
      "update setup",
      "Historical baseline",
    ],
  );
  assert.deepEqual(
    changes.map(({ breaking }) => breaking),
    [true, false, true, true, false, false, false],
  );
  assert.deepEqual(
    changes.map(({ url }) => url.split("/").at(-1)),
    [marked, coach, footer, explicitSubject, security, direct, baseline],
  );
});

test("uses a PR base revision instead of its synthetic merge commit", async (t) => {
  const { cwd, baseline } = await repository(t);
  git(cwd, ["switch", "--quiet", "-c", "feature"]);
  const feature = commit(cwd, "feat: unmerged branch change", "2026-01-02T10:00:00Z");
  git(cwd, ["switch", "--quiet", "main"]);
  const base = commit(cwd, "docs: main branch change", "2026-01-03T10:00:00Z");
  git(cwd, ["merge", "--quiet", "--no-ff", "--no-edit", "feature"]);

  const changes = loadChangelog({ cwd, ref: base, baseline, history: [] }).flatMap(
    (group) => group.changes,
  );
  assert.deepEqual(
    changes.map(({ title }) => title),
    ["main branch change"],
  );
  assert.throws(
    () => loadChangelog({ cwd, ref: "HEAD", baseline: feature, history: [] }),
    /baseline.*first-parent history/i,
  );
});

test("redacts prohibited identifiers and addresses without logging their values", async (t) => {
  const { cwd, baseline } = await repository(t);
  const guid = ["12345678", "1234", "1234", "1234", "123456789abc"].join("-");
  const email = ["owner", "example.invalid"].join("@");
  const ipv4 = [8, 8, 4, 4].join(".");
  const publicAnycast = [192, 0, 0, 9].join(".");
  const ipv6 = ["2606", "4700", "4700", "", "1111"].join(":");
  const privateAddress = [10, 10, 1, 4].join(".");
  const sha = commit(
    cwd,
    `docs: remove ${guid} ${email} ${ipv4} ${publicAnycast} ${ipv6} but retain ${privateAddress}`,
    "2026-01-02T10:00:00Z",
  );
  const warnings = [];
  const [change] = loadChangelog({
    cwd,
    ref: "HEAD",
    baseline,
    history: [],
    onRedaction: (source) => warnings.push(source),
  }).flatMap((group) => group.changes);
  for (const value of [guid, email, ipv4, publicAnycast, ipv6]) {
    assert.ok(!change.title.includes(value));
  }
  assert.equal((change.title.match(/\[identifier removed\]/g) ?? []).length, 5);
  assert.ok(change.title.includes(privateAddress));
  assert.deepEqual(warnings, [`commit ${sha.slice(0, 12)}`]);
});

test("fails clearly when required history or source data is invalid", async (t) => {
  const { cwd, baseline } = await repository(t);
  assert.throws(
    () => loadChangelog({ cwd, ref: "HEAD", baseline: "a".repeat(40), history: [] }),
    /baseline.*first-parent history/i,
  );
  assert.throws(
    () => loadChangelog({ cwd, ref: "--all", baseline, history: [] }),
    /Git ref is invalid/,
  );
  assert.throws(
    () => loadChangelog({ cwd: join(cwd, "missing"), ref: "HEAD", baseline, history: [] }),
    /Cannot read changelog Git history/,
  );
  assert.throws(
    () =>
      loadChangelog({
        cwd,
        ref: "HEAD",
        baseline,
        history: [{ date: "2026-02-31", title: "Invalid date", pr: 1 }],
      }),
    /historical changelog entry has an invalid date or title/i,
  );
  assert.throws(
    () =>
      loadChangelog({
        cwd,
        ref: "HEAD",
        baseline,
        history: [{ date: "2026-01-01", title: "Invalid source", pr: -1 }],
      }),
    /historical changelog entry has an invalid source/i,
  );
});

test("the component renders commit text as escaped Astro text", async () => {
  const component = await readFile(
    new URL("../site/src/components/Changelog.astro", import.meta.url),
    "utf8",
  );
  assert.match(component, /<a href=\{url\}>\{title\}<\/a>/);
  assert.doesNotMatch(component, /set:html/);
});
