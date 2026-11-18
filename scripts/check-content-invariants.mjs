import { readFileSync } from "node:fs";
import { access, readFile, readdir } from "node:fs/promises";
import { extname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const defaultRoot = fileURLToPath(new URL("..", import.meta.url));
const textExtensions = new Set([".astro", ".md", ".mdx", ".yml", ".yaml"]);
// The challenge order, scope, time and objective live in site/src/data/challenges.json.
const challengeData = JSON.parse(
  readFileSync(new URL("../site/src/data/challenges.json", import.meta.url), "utf8"),
).challenges;
const challengeContract = challengeData.map((c) => [c.id, c.file, c.minutes]);
const expectedChallengeCount = 10;
const expectedMinutes = 750;

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

// The team template folder holds copies of the attendee templates: they must stay byte-identical.
async function checkTemplateCopies(root) {
  const attendee = join(root, "templates/attendee");
  const team = join(root, "templates/team/templates");
  let names;
  try {
    names = await readdir(attendee);
  } catch (error) {
    if (error.code === "ENOENT") return [];
    throw error;
  }
  const failures = [];
  for (const name of names) {
    let copy;
    try {
      copy = await readFile(join(team, name));
    } catch (error) {
      if (error.code === "ENOENT") {
        failures.push(
          `templates/team/templates/${name}: missing, copy it from templates/attendee/${name}`,
        );
        continue;
      }
      throw error;
    }
    if (!copy.equals(await readFile(join(attendee, name)))) {
      failures.push(`templates/team/templates/${name}: differs from templates/attendee/${name}`);
    }
  }
  return failures;
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

  let overviewRows = [];
  try {
    overviewRows = (await readFile(join(root, "site/src/content/docs/challenges/index.md"), "utf8"))
      .replace(/\r\n/g, "\n")
      .split("\n")
      .filter((line) => line.startsWith("|"));
  } catch {
    // The missing overview is reported by each challenge row below.
  }

  let storyText = "";
  try {
    storyText = await readFile(
      join(root, "site/src/content/docs/getting-started/customer-story.md"),
      "utf8",
    );
  } catch {
    failures.push("site/src/content/docs/getting-started/customer-story.md: missing");
  }
  for (const outcome of new Set(challengeData.map((c) => c.outcome))) {
    if (outcome !== "All six, in order" && storyText && !storyText.includes(`| ${outcome} |`)) {
      failures.push(
        `customer-story.md: the outcome "${outcome}" in challenges.json is not in the outcomes table`,
      );
    }
  }

  let totalMinutes = 0;
  for (const [, fileName, minutes] of challengeContract) {
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

    const infoPattern = new RegExp(`\\*\\*${minutes}\\s+min\\*\\*`);
    if (!infoPattern.test(text)) {
      failures.push(`site/src/content/docs/challenges/${fileName}: expected ${minutes} min`);
    }

    const challenge = challengeData.find((c) => c.file === fileName);
    const challengePath = `site/src/content/docs/challenges/${fileName}`;
    if (!text.includes(`title: "${challenge.id}: ${challenge.title}"`)) {
      failures.push(`${challengePath}: title must be "${challenge.id}: ${challenge.title}"`);
    }
    if (!text.includes(`**Objective.** ${challenge.objective}`)) {
      failures.push(`${challengePath}: objective differs from site/src/data/challenges.json`);
    }
    const slug = fileName.replace(/\.mdx?$/, "");
    const row = overviewRows.find((line) => line.includes(`(./${slug}/)`));
    const expectedRow = [
      challenge.day,
      `[${challenge.id}: ${challenge.title}](./${slug}/)`,
      challenge.scope,
      `${challenge.minutes} min`,
      challenge.outcome,
    ];
    const cells = row
      ? row
          .split("|")
          .slice(1, -1)
          .map((cell) => cell.trim())
      : [];
    if (JSON.stringify(cells) !== JSON.stringify(expectedRow)) {
      failures.push(
        `site/src/content/docs/challenges/index.md: the ${challenge.id} row must read ${expectedRow.join(" | ")}`,
      );
    }

    totalMinutes += minutes;
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

  failures.push(...(await checkTemplateCopies(root)));

  return { failures, totalMinutes };
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const { failures, totalMinutes } = await runChecks();
  if (failures.length > 0) {
    console.error("Content invariant checks failed:");
    for (const failure of failures) console.error(`- ${failure}`);
    process.exitCode = 1;
  } else {
    console.log(
      `Content invariants passed: ${challengeContract.length} challenges, ${totalMinutes} minutes.`,
    );
  }
}
