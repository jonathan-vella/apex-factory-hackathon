// Read-only. Run in the CoE container from the workspace root:
//   node collect-facts.mjs university > facts.json
// Prints hashes and review metadata only. It signs nothing and writes nothing.
import fs from "node:fs";
import { createHash } from "node:crypto";

const project = process.argv[2] || "university";
const dir = `agent-output/${project}`;
const sha = (file) => createHash("sha256").update(fs.readFileSync(file)).digest("hex");
const ref = (relative) => ({ path: relative, sha256: sha(relative) });

const reviewPath = process.argv[3] || `${dir}/challenge-findings-plan-pass10.json`;
const review = JSON.parse(fs.readFileSync(reviewPath, "utf8"));
const original = `${dir}/challenge-findings-plan.json`;

const facts = {
  project,
  workspace_root: process.cwd(),
  review: ref(reviewPath),
  challenged_artifact: review.challenged_artifact,
  artifact: ref(review.challenged_artifact),
  cache_inputs: review.cache_inputs,
  supporting_inputs: review.supporting_inputs,
  overall_assessment: review.overall_assessment,
  pass_number: review.pass_number,
  findings: review.findings.map((f) => ({ id: f.id, severity: f.severity, claim: f.claim })),
  preserved_reviews: fs.existsSync(original) ? [ref(original)] : [],
  current_supporting_hashes: Object.fromEntries(
    review.supporting_inputs.map((s) => [s.path, sha(s.path) === s.sha256 ? "match" : "DIFF"]),
  ),
};
process.stdout.write(JSON.stringify(facts, null, 2) + "\n");
