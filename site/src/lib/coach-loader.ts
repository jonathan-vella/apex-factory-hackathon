import { readdir, readFile } from "node:fs/promises";
import { posix } from "node:path";
import { fileURLToPath } from "node:url";
import type { Loader } from "astro/loaders";
import { z } from "astro/zod";

const REPO_URL = "https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/";

const sectionKinds: Record<string, string> = {
  "expected evidence": "evidence",
  "model answer": "answer",
  "common mistakes": "mistakes",
  "partial credit": "partial",
  bonus: "bonus",
  reset: "reset",
};

export const coachSchema = z.object({
  kind: z.enum(["challenge", "lifelines", "run-of-show"]),
  title: z.string(),
  sourcePath: z.string(),
  studentPage: z.string().optional(),
  scope: z.string().optional(),
  minutes: z.number().optional(),
  teamPoints: z.number().optional(),
  memberPoints: z.number().optional(),
  bonus: z.string().optional(),
  introHtml: z.string(),
  scoringHtml: z.string().optional(),
  sections: z.array(
    z.object({
      title: z.string(),
      slug: z.string(),
      kind: z.string(),
      html: z.string(),
    }),
  ),
});

type CoachData = z.infer<typeof coachSchema>;

function slugify(text: string) {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

// Splits on level 2 headings outside code fences. The level 1 heading is the title.
function splitMarkdown(markdown: string) {
  const lines = markdown.replace(/\r\n/g, "\n").split("\n");
  let title = "";
  const intro: string[] = [];
  const sections: { title: string; lines: string[] }[] = [];
  let fence = false;
  for (const line of lines) {
    if (/^\s*(```|~~~)/.test(line)) fence = !fence;
    const h1 = !fence && !title && /^# (.+)$/.exec(line);
    const h2 = !fence && /^## (.+?)\s*$/.exec(line);
    if (h1) title = h1[1].trim();
    else if (h2) sections.push({ title: h2[1].trim(), lines: [] });
    else if (sections.length) sections[sections.length - 1].lines.push(line);
    else intro.push(line);
  }
  return { title, intro: intro.join("\n"), sections };
}

// Removes the GitHub alert that opens the coach files; the page shows its own banner.
function stripLeadingAlert(markdown: string) {
  return markdown.replace(/^\s*(?:>.*\n?)+/, (block) => (/\[!\w+\]/.test(block) ? "" : block));
}

// Relative links in the source files point at repo files, not at site routes.
function rewriteLinks(markdown: string, sourcePath: string) {
  return markdown.replace(/\]\(([^)\s]+)\)/g, (match, target: string) => {
    if (/^(?:[a-z][a-z0-9+.-]*:|\/\/|#)/i.test(target)) return match;
    const [path, hash] = target.split("#");
    const resolved = posix.normalize(posix.join(posix.dirname(sourcePath), path));
    const suffix = hash ? `#${hash}` : "";
    const hidden = /^coach\/(c\d+)-[^/]+\.md$/.exec(resolved);
    if (hidden) return `](/coach/${hidden[1]}/${suffix})`;
    if (resolved === "coach/lifelines.md") return `](/coach/lifelines/${suffix})`;
    if (resolved === "facilitator/agenda.md") return `](/coach/run-of-show/${suffix})`;
    const student = /^site\/src\/content\/docs\/(.+?)(?:\/index)?\.mdx?$/.exec(resolved);
    if (student) return `](/${student[1]}/${suffix})`;
    return `](${REPO_URL}${resolved}${suffix})`;
  });
}

export function coachLoader(): Loader {
  return {
    name: "coach-material",
    async load({ config, store, parseData, generateDigest, renderMarkdown, watcher, logger }) {
      const repoRoot = fileURLToPath(new URL("../", config.root));
      const read = (path: string) => readFile(`${repoRoot}${path}`, "utf8");
      const render = async (markdown: string, sourcePath: string) =>
        (await renderMarkdown(rewriteLinks(markdown, sourcePath))).html;

      async function build(sourcePath: string, rubric: string) {
        const { title, intro, sections } = splitMarkdown(await read(sourcePath));
        const fileName = posix.basename(sourcePath, ".md");
        const number = /^c(\d+)-/.exec(fileName)?.[1];
        const base: CoachData = {
          kind: number ? "challenge" : fileName === "lifelines" ? "lifelines" : "run-of-show",
          title: title.replace(/\s+answer key(?=[:\s]|$)/i, "") || fileName,
          sourcePath,
          introHtml: await render(stripLeadingAlert(intro), sourcePath),
          sections: [],
        };
        for (const section of sections) {
          base.sections.push({
            title: section.title,
            slug: slugify(section.title),
            kind: sectionKinds[section.title.toLowerCase()] ?? "other",
            html: await render(section.lines.join("\n"), sourcePath),
          });
        }
        if (number) {
          const id = Number(number);
          base.studentPage = `/challenges/${fileName}/`;
          const row = new RegExp(
            `^\\|\\s*C${id}\\s[^|]*\\|\\s*([^|]+?)\\s*\\|\\s*(\\d+)\\s*\\|\\s*(\\d+)\\s*\\|\\s*(\\d+)\\s*\\|`,
            "m",
          ).exec(rubric);
          if (row) {
            base.scope = row[1];
            base.minutes = Number(row[2]);
            base.teamPoints = Number(row[3]);
            base.memberPoints = Number(row[4]);
          }
          const scoring = new RegExp(
            `^### C${id} — [^\\n]+\\n([\\s\\S]*?)(?=^#{2,3} |(?![\\s\\S]))`,
            "m",
          ).exec(rubric);
          if (scoring) {
            base.scoringHtml = await render(scoring[1], "facilitator/scoring-rubric.md");
          }
          const bonusText = sections
            .find((s) => sectionKinds[s.title.toLowerCase()] === "bonus")
            ?.lines.join(" ");
          const bonus = bonusText && /up to (\d+)\s+(?:bonus\s+)?points?/i.exec(bonusText);
          if (bonus) base.bonus = `up to ${bonus[1]} pts`;
        }
        const id = number ? `c${number}` : fileName === "agenda" ? "run-of-show" : fileName;
        return { id, data: base };
      }

      async function loadAll() {
        const rubric = (await read("facilitator/scoring-rubric.md")).replace(/\r\n/g, "\n");
        const files = (await readdir(`${repoRoot}coach`))
          .filter((name) => name.endsWith(".md"))
          .map((name) => `coach/${name}`);
        files.push("facilitator/agenda.md");
        store.clear();
        for (const sourcePath of files) {
          try {
            const { id, data } = await build(sourcePath, rubric);
            store.set({
              id,
              data: await parseData({ id, data }),
              digest: generateDigest(JSON.stringify(data)),
            });
          } catch (error) {
            logger.error(`Could not render ${sourcePath}: ${(error as Error).message}`);
            throw error;
          }
        }
      }

      await loadAll();

      if (watcher) {
        const watched = [`${repoRoot}coach`, `${repoRoot}facilitator`];
        watcher.add(watched);
        watcher.on("change", (changed: string) => {
          const normalized = changed.replaceAll("\\", "/");
          if (watched.some((dir) => normalized.startsWith(dir.replaceAll("\\", "/")))) {
            void loadAll();
          }
        });
      }
    },
  };
}
