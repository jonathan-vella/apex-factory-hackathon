import { access, readFile, readdir } from "node:fs/promises";
import { extname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const defaultRoot = fileURLToPath(new URL("..", import.meta.url));
const textExtensions = new Set([".astro", ".md", ".mdx", ".yml", ".yaml"]);
const challengeContract = [
  ["C0", "c00-ready-to-hack.md", 150, 10, 0, 10],
  ["C1", "c01-define-the-opportunity.md", 45, 10, 10, 0],
  ["C2", "c02-secure-ai-ready-foundation.md", 120, 35, 35, 0],
  ["C3", "c03-assess-the-source.md", 60, 15, 0, 15],
  ["C4", "c04-choose-target-states.md", 45, 25, 15, 10],
  ["C5", "c05-deploy-the-coe-archetype.md", 90, 15, 0, 15],
  ["C6", "c06-modernize-with-ghcp.md", 180, 30, 0, 30],
  ["C7", "c07-migrate-and-go-live.md", 120, 20, 0, 20],
  ["C8", "c08-validate-the-pattern.md", 45, 10, 0, 10],
  ["C9", "c09-optimize-the-db-with-ghcp.md", 60, 10, 0, 10],
  ["C10", "c10-package-hand-over-review-ai-readiness.md", 60, 20, 20, 0],
];
const expectedChallengeCount = 11;
const expectedMinutes = 975;
const expectedPoints = 200;
const expectedTeamPoints = 80;
const expectedMemberPoints = 120;

async function collectFiles(path) {
  let entries;
  try {
    entries = await readdir(path, { withFileTypes: true });
  } catch (error) {
    if (error.code === "ENOENT") return [];
    throw error;
  }
  const files = [];

  for (const entry of entries) {
    if (entry.name === "tmp") continue;
    const fullPath = join(path, entry.name);
    if (entry.isDirectory()) {
      files.push(...(await collectFiles(fullPath)));
    } else if (textExtensions.has(extname(entry.name))) {
      files.push(fullPath);
    }
  }

  return files;
}

export async function runChecks(root = defaultRoot) {
  const includedRoots = [
    ".github/ISSUE_TEMPLATE",
    "coach",
    "facilitator",
    "templates",
    "site/src/content/docs",
    "site/src/components",
  ];
  const includedFiles = ["README.md"];
  const files = [
    ...(await Promise.all(includedRoots.map((path) => collectFiles(join(root, path))))).flat(),
    ...(
      await Promise.all(
        includedFiles.map(async (path) => {
          const fullPath = join(root, path);
          try {
            await access(fullPath);
            return fullPath;
          } catch (error) {
            if (error.code === "ENOENT") return null;
            throw error;
          }
        }),
      )
    ).filter(Boolean),
  ];
  const retiredPatterns = [
    {
      pattern: /azure-agentic-infraops-accelerator/gi,
      message: "retired Accelerator repository name",
    },
    {
      pattern: /jonathan-vella\.github\.io\/azure-agentic-infraops/gi,
      message: "retired documentation URL",
    },
    {
      pattern: /07-ab-operations-guide\.md/gi,
      message: "retired operations artifact name",
    },
    {
      pattern: /customAgentInSubagent\.enabled/gi,
      message: "retired custom-agent setting",
    },
    {
      pattern: /other SKUs do not include the required functionality/gi,
      message: "unsupported Copilot entitlement claim",
    },
    {
      pattern: /Node\.js?\s*\+?\s*npm\s*[|:]?\s*22\.x|Node\s+22\.x/gi,
      message: "retired Node 22 environment claim",
    },
    {
      pattern: /parallel execution|autonomous pipeline/gi,
      message: "misleading autonomous or parallel workflow language",
    },
    {
      pattern: /ghpc-appmod-eShop/gi,
      message: "superseded eShop sample repository",
    },
    {
      pattern: /Nordic Fresh Foods|FreshConnect/gi,
      message: "retired APEX microhack scenario name",
    },
    {
      pattern: /apex-factory-(university|archetype|coach)/gi,
      message: "retired multi-repository project name",
    },
  ];
  const failures = [];

  for (const file of files) {
    const text = await readFile(file, "utf8");
    const displayPath = relative(root, file);
    for (const { pattern, message } of retiredPatterns) {
      for (const match of text.matchAll(pattern)) {
        const line = text.slice(0, match.index).split(/\r?\n/).length;
        failures.push(`${displayPath}:${line}: ${message}`);
      }
    }
  }

  let totalMinutes = 0;
  let totalPoints = 0;
  for (const [, fileName, minutes, points] of challengeContract) {
    const path = join(root, "site/src/content/docs/challenges", fileName);
    let text;
    try {
      text = await readFile(path, "utf8");
    } catch {
      failures.push(
        `site/src/content/docs/challenges/${fileName}: required challenge file is missing`,
      );
      continue;
    }

    const infoPattern = new RegExp(
      `\\*\\*${minutes}\\s+min\\*\\*[\\s\\S]*?\\*\\*${points}\\s+pts\\*\\*`,
    );
    if (!infoPattern.test(text)) {
      failures.push(
        `site/src/content/docs/challenges/${fileName}: expected ${minutes} min and ${points} pts`,
      );
    }

    totalMinutes += minutes;
    totalPoints += points;
  }

  if (challengeContract.length !== expectedChallengeCount) {
    failures.push(
      `challenge contract: expected ${expectedChallengeCount} challenges, found ${challengeContract.length}`,
    );
  }
  if (totalMinutes !== expectedMinutes) {
    failures.push(
      `challenge contract: expected ${expectedMinutes} total minutes, found ${totalMinutes}`,
    );
  }
  if (totalPoints !== expectedPoints) {
    failures.push(
      `challenge contract: expected ${expectedPoints} base points, found ${totalPoints}`,
    );
  }

  let rubricTeamPoints = 0;
  let rubricMemberPoints = 0;
  const rubricPath = join(root, "facilitator/scoring-rubric.md");
  let rubricText;
  try {
    rubricText = await readFile(rubricPath, "utf8");
  } catch (error) {
    if (error.code === "ENOENT") {
      failures.push("facilitator/scoring-rubric.md: required scoring rubric is missing");
    } else {
      throw error;
    }
  }

  if (rubricText !== undefined) {
    for (const [challengeId, , , , expectedTeam, expectedMember] of challengeContract) {
      const heading = new RegExp(`^### ${challengeId} — [^\\r\\n]+$`, "m");
      const headingMatch = heading.exec(rubricText);
      if (!headingMatch) {
        failures.push(`facilitator/scoring-rubric.md: missing ${challengeId} evidence table`);
        continue;
      }

      const bodyStart = headingMatch.index + headingMatch[0].length;
      const rest = rubricText.slice(bodyStart);
      const nextHeading = /^(?:### C\d+ — |## )/m.exec(rest);
      const section = nextHeading ? rest.slice(0, nextHeading.index) : rest;
      let sectionTeamPoints = 0;
      let sectionMemberPoints = 0;
      let totalRow;
      let evidenceRows = 0;

      for (const line of section.split(/\r?\n/)) {
        const row =
          /^\|\s*(\*\*[^|]+\*\*|[^|]+?)\s*\|\s*\*{0,2}(\d+)\*{0,2}\s*\|\s*\*{0,2}(\d+)\*{0,2}\s*\|$/.exec(
            line,
          );
        if (!row) continue;
        const label = row[1].trim().replace(/^\*\*|\*\*$/g, "");
        const teamPoints = Number(row[2]);
        const memberPoints = Number(row[3]);
        if (label === "Total") {
          totalRow = { teamPoints, memberPoints };
        } else if (label !== "Evidence item") {
          sectionTeamPoints += teamPoints;
          sectionMemberPoints += memberPoints;
          evidenceRows += 1;
        }
      }

      if (evidenceRows === 0 || !totalRow) {
        failures.push(
          `facilitator/scoring-rubric.md: ${challengeId} has no evidence rows or total row`,
        );
        continue;
      }
      if (
        sectionTeamPoints !== totalRow.teamPoints ||
        sectionMemberPoints !== totalRow.memberPoints
      ) {
        failures.push(
          `facilitator/scoring-rubric.md: ${challengeId} evidence rows sum to ${sectionTeamPoints} team and ${sectionMemberPoints} member points, but its total row says ${totalRow.teamPoints} team and ${totalRow.memberPoints} member`,
        );
      }
      if (sectionTeamPoints !== expectedTeam || sectionMemberPoints !== expectedMember) {
        failures.push(
          `facilitator/scoring-rubric.md: ${challengeId} must match the challenge contract (${expectedTeam} team, ${expectedMember} member points), found ${sectionTeamPoints} team and ${sectionMemberPoints} member`,
        );
      }
      rubricTeamPoints += sectionTeamPoints;
      rubricMemberPoints += sectionMemberPoints;
    }

    if (
      rubricTeamPoints !== expectedTeamPoints ||
      rubricMemberPoints !== expectedMemberPoints ||
      rubricTeamPoints + rubricMemberPoints !== expectedPoints
    ) {
      failures.push(
        `rubric contract: expected ${expectedTeamPoints} team and ${expectedMemberPoints} member points (${expectedPoints} total), found ${rubricTeamPoints} team and ${rubricMemberPoints} member points`,
      );
    }
  }

  return { failures, totalMinutes, totalPoints, rubricTeamPoints, rubricMemberPoints };
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const { failures, totalMinutes, totalPoints, rubricTeamPoints, rubricMemberPoints } =
    await runChecks();
  if (failures.length > 0) {
    console.error("Content invariant checks failed:");
    for (const failure of failures) console.error(`- ${failure}`);
    process.exitCode = 1;
  } else {
    console.log(
      `Content invariants passed: ${challengeContract.length} challenges, ${totalMinutes} minutes, ${totalPoints} base points. Rubric totals passed: ${rubricTeamPoints} team, ${rubricMemberPoints} member.`,
    );
  }
}
