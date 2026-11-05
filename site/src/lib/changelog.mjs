import { spawnSync } from "node:child_process";
import { isIP } from "node:net";
import { changelogBaseline, historicalChanges } from "../data/changelog-history.mjs";

const repositoryUrl = "https://github.com/jonathan-vella/apex-factory-hackathon";
const shaPattern = /^[0-9a-f]{40}$/i;
const identifierPattern = /\b[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}\b/gi;
const emailPattern = /\b[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}\b/gi;
const ipv4Pattern = /(?<![a-z0-9.])(?:\d{1,3}\.){3}\d{1,3}(?![a-z0-9.])/gi;
const ipv6Pattern = /(?<![a-z0-9])(?:[0-9a-f]{0,4}:){2,7}[0-9a-f]{0,4}(?![a-z0-9])/gi;

function isPublicIpv4(address) {
  if (isIP(address) !== 4) return false;
  const [first, second, third, fourth] = address.split(".").map(Number);
  return (
    first > 0 &&
    first < 224 &&
    first !== 10 &&
    first !== 127 &&
    !(first === 100 && second >= 64 && second <= 127) &&
    !(first === 169 && second === 254) &&
    !(first === 172 && second >= 16 && second <= 31) &&
    !(first === 192 && second === 168) &&
    !(
      first === 192 &&
      second === 0 &&
      (third === 2 || (third === 0 && fourth !== 9 && fourth !== 10))
    ) &&
    !(first === 198 && (second === 18 || second === 19 || (second === 51 && third === 100))) &&
    !(first === 203 && second === 0 && third === 113)
  );
}

function isPublicIpv6(address) {
  if (isIP(address) !== 6) return false;
  const normalized = address.toLowerCase();
  const first = Number.parseInt(normalized.split(":")[0], 16);
  return first >= 0x2000 && first <= 0x3fff && !normalized.startsWith("2001:db8:");
}

function redactTitle(title, source, onRedaction) {
  const replacement = "[identifier removed]";
  const safe = title
    .replace(identifierPattern, replacement)
    .replace(emailPattern, replacement)
    .replace(ipv4Pattern, (address) => (isPublicIpv4(address) ? replacement : address))
    .replace(ipv6Pattern, (address) => (isPublicIpv6(address) ? replacement : address));
  if (safe !== title) onRedaction(source);
  return safe;
}

export function isDependencyBump(subject, author = "") {
  return (
    /^[a-z][a-z0-9-]*\(deps(?:-[a-z0-9-]+)?\)!?:\s*bump\b/i.test(subject) ||
    /^(?:chore|build)\(deps(?:-[a-z0-9-]+)?\)!?:\s*(?:update|upgrade)\b/i.test(subject) ||
    /^(?:(?:chore|build)!?:\s*)?(?:bump|update|upgrade)\s+(?:the\s+)?(?:dev[ -]?)?dependencies\b/i.test(
      subject,
    ) ||
    (author === "dependabot[bot]" &&
      /^(?:(?:chore|build)(?:\([^)\r\n]*\))?!?:\s*)?(?:bump|update|upgrade)\b/i.test(subject))
  );
}

export function isBreakingChange(subject, body) {
  return (
    /^[a-z][a-z0-9-]*(?:\([^)\r\n]*\))?!:/i.test(subject) ||
    /^(?:[a-z][a-z0-9-]*(?:\([^)\r\n]*\))?!?:\s*)?(?:BREAKING(?:[ -]CHANGE)?:|\[BREAKING(?:[ -]CHANGE)?\])/i.test(
      subject,
    ) ||
    /^[ \t]*(?:BREAKING(?:[ -]CHANGE)?:|\[BREAKING(?:[ -]CHANGE)?\])/im.test(body)
  );
}

export function cleanCommitTitle(subject) {
  return subject
    .replace(
      /^(?:feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(?:\([^)\r\n]*\))?!?:\s*/i,
      "",
    )
    .replace(/^(?:BREAKING(?:[ -]CHANGE)?:\s*|\[BREAKING(?:[ -]CHANGE)?\]\s*)/i, "")
    .replace(/\s+\(#\d+\)\s*$/, "")
    .trim();
}

export function publicCommitTitle(subject) {
  const coachScoringCap =
    /\b(?:caps?|capped|capping)\b/i.test(subject) &&
    (/\b(?:c0?[67]|l[1-5])\b/i.test(subject) ||
      (/\bcoach(?:es)?\b/i.test(subject) && /\b(?:score|scoring|points?)\b/i.test(subject)));
  if (/\blifelines?\b|\bknown[- ]good\b/i.test(subject) || coachScoringCap) {
    return "Updated coach-only recovery material.";
  }
  return cleanCommitTitle(subject);
}

function git(args, cwd) {
  const result = spawnSync("git", args, {
    cwd,
    encoding: "utf8",
    maxBuffer: 16 * 1024 * 1024,
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (result.error) {
    throw new Error(
      `Cannot read changelog Git history (${result.error.code ?? "unknown error"}). Check that Git and the repository are available.`,
    );
  }
  if (result.status !== 0) {
    const status =
      result.status === null ? `signal ${result.signal ?? "unknown"}` : `exit ${result.status}`;
    throw new Error(
      `Cannot read changelog Git history (Git ${status}). Fetch the history through the baseline.`,
    );
  }
  return result.stdout;
}

function historyEntry(change, onRedaction) {
  const date = new Date(`${change.date}T00:00:00Z`);
  if (
    !/^\d{4}-\d{2}-\d{2}$/.test(change.date) ||
    Number.isNaN(date.valueOf()) ||
    date.toISOString().slice(0, 10) !== change.date ||
    typeof change.title !== "string" ||
    !change.title.trim()
  ) {
    throw new Error("A historical changelog entry has an invalid date or title.");
  }

  let url;
  let source;
  if (Number.isSafeInteger(change.pr) && change.pr > 0 && !change.commit) {
    source = `PR #${change.pr}`;
    url = `${repositoryUrl}/pull/${change.pr}`;
  } else if (typeof change.commit === "string" && shaPattern.test(change.commit) && !change.pr) {
    source = `commit ${change.commit.slice(0, 12)}`;
    url = `${repositoryUrl}/commit/${change.commit}`;
  } else {
    throw new Error("A historical changelog entry has an invalid source.");
  }
  return {
    date: change.date,
    title: redactTitle(change.title, source, onRedaction),
    url,
    breaking: false,
  };
}

function recentEntries(cwd, baseline, ref, onRedaction) {
  if (!shaPattern.test(baseline)) throw new Error("The changelog baseline is invalid.");
  if (ref !== "HEAD" && ref !== "refs/remotes/origin/main" && !shaPattern.test(ref)) {
    throw new Error("The changelog Git ref is invalid.");
  }
  const ancestors = git(["rev-list", "--first-parent", ref], cwd).trim().split(/\r?\n/);
  if (!ancestors.includes(baseline.toLowerCase())) {
    throw new Error(
      "The changelog baseline is not in the checked-out first-parent history. Fetch the required history.",
    );
  }

  const output = git(
    [
      "--no-pager",
      "log",
      "--first-parent",
      "-z",
      "--format=%H%x00%cI%x00%an%x00%s%x00%b",
      `${baseline}..${ref}`,
      "--",
    ],
    cwd,
  );
  if (!output) return [];
  const fields = output.split("\0");
  if (fields.pop() !== "" || fields.length % 5 !== 0) {
    throw new Error("Git returned malformed changelog history.");
  }

  const changes = [];
  for (let i = 0; i < fields.length; i += 5) {
    const [sha, timestamp, author, subject, body] = fields.slice(i, i + 5);
    if (!shaPattern.test(sha) || !subject.trim()) {
      throw new Error("Git returned a changelog entry without a valid commit or title.");
    }
    if (isDependencyBump(subject, author)) continue;
    const date = new Date(timestamp);
    if (Number.isNaN(date.valueOf())) {
      throw new Error(`Changelog commit ${sha.slice(0, 12)} has an invalid date.`);
    }
    const title = publicCommitTitle(
      redactTitle(subject, `commit ${sha.slice(0, 12)}`, onRedaction),
    );
    if (!title) throw new Error(`Changelog commit ${sha.slice(0, 12)} has an empty title.`);
    changes.push({
      date: date.toISOString().slice(0, 10),
      title,
      url: `${repositoryUrl}/commit/${sha}`,
      breaking: isBreakingChange(subject, body),
    });
  }
  return changes;
}

export function loadChangelog({
  cwd = process.cwd(),
  ref = process.env.CHANGELOG_REF || "HEAD",
  baseline = changelogBaseline,
  history = historicalChanges,
  onRedaction = (source) =>
    console.warn(`Changelog: an identifier or address was removed from ${source}.`),
} = {}) {
  const changes = [
    ...recentEntries(cwd, baseline, ref, onRedaction),
    ...history.map((change) => historyEntry(change, onRedaction)),
  ];
  changes.sort((a, b) => (a.date === b.date ? 0 : a.date > b.date ? -1 : 1));

  const groups = [];
  for (const change of changes) {
    let group = groups.at(-1);
    if (!group || group.date !== change.date) {
      group = { date: change.date, changes: [] };
      groups.push(group);
    }
    group.changes.push(change);
  }
  return groups;
}

export function formatChangelogDate(date) {
  return new Intl.DateTimeFormat("en-GB", {
    day: "numeric",
    month: "long",
    year: "numeric",
    timeZone: "UTC",
  }).format(new Date(`${date}T00:00:00Z`));
}
