// End-to-end test of risk.mjs against the REAL upstream evaluator, using synthetic data only.
// Run in WSL/Linux:  node test-e2e.mjs <apex-clone-dir>
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const apex = path.resolve(process.argv[2]);
const { evaluateAuthorization } = await import(pathToFileURL(path.join(apex, "tools/scripts/evaluate-risk-authorization.mjs")).href);
const sha = (b) => createHash("sha256").update(b).digest("hex");

const base = fs.mkdtempSync(path.join(os.tmpdir(), "riskt-"));
const ws = path.join(base, "ws");
const dir = path.join(ws, "agent-output/university");
fs.mkdirSync(dir, { recursive: true });
const put = (name, text) => {
  fs.writeFileSync(path.join(dir, name), text);
  return { path: `agent-output/university/${name}`, sha256: sha(Buffer.from(text)) };
};
const plan = put("04-implementation-plan.md", "# synthetic plan\n");
const supporting = [
  "04-iac-contract.json",
  "04-policy-property-map.json",
  "04-environment-manifest.json",
  "04-governance-constraints.md",
  "04-governance-constraints.json",
].map((n) => put(n, `{"${n}":1}`));
put("challenge-findings-plan.json", JSON.stringify({ findings: [], pass_number: 1 }));
const review = {
  pass_number: 10,
  challenged_artifact: plan.path,
  overall_assessment: "NEEDS_REVISION",
  cache_inputs: {
    artifact_sha: plan.sha256,
    checklists_sha: "a".repeat(64),
    protocol_sha: "b".repeat(64),
    subagent_sha: "c".repeat(64),
    model: "GPT-6 Luna (copilot)",
    artifact_hash: "d".repeat(64),
  },
  supporting_inputs: supporting,
  findings: [
    { id: "a749666a", severity: "must_fix", claim: "shared identity" },
    { id: "bc629836", severity: "must_fix", claim: "public ingress" },
    { id: "b51b7d66", severity: "should_fix", claim: "diag" },
  ],
};
put("challenge-findings-plan-pass10.json", JSON.stringify(review));

const env = { ...process.env, APEX_RISK_HOME: path.join(base, "keys"), APEX_RISK_TEST_YES: "1" };
const out = path.join(base, "out");
// The real settings pin fingerprints of the production keys; the test generates fresh keys, so strip them.
const testSettings = JSON.parse(fs.readFileSync(path.join(here, "settings.json"), "utf8"));
for (const key of Object.values(testSettings.keys)) delete key.fingerprint;
const settingsPath = path.join(base, "settings.json");
fs.writeFileSync(settingsPath, JSON.stringify(testSettings));
const run = (script, args, cwd = here) => execFileSync("node", [path.join(here, script), ...args], { cwd, env, encoding: "utf8" });
const risk = (args) => run("risk.mjs", [...args, "--out", out, "--facts", path.join(base, "facts.json"), "--settings", settingsPath]);

fs.writeFileSync(path.join(base, "facts.json"), run("collect-facts.mjs", ["university"], ws));
risk(["keygen"]);
// restore: copy the keys to a second home, verify them, and reject a wrong expected fingerprint
const restoreEnv = { ...env, APEX_RISK_HOME: path.join(base, "keys-restored") };
const restoreRun = (settingsFile) =>
  execFileSync("node", [path.join(here, "risk.mjs"), "restore", "--from", path.join(base, "keys"), "--settings", settingsFile], { cwd: here, env: restoreEnv, encoding: "utf8" });
const restoredOk = restoreRun(settingsPath);
console.log(/restored and verified/.test(restoredOk) ? "PASS  restore verifies and copies the keys" : "FAIL  restore output unexpected");
if (!/restored and verified/.test(restoredOk)) process.exitCode = 1;
const wrong = JSON.parse(JSON.stringify(testSettings));
wrong.keys.owner.fingerprint = "0000000000000000";
const wrongPath = path.join(base, "settings-wrong.json");
fs.writeFileSync(wrongPath, JSON.stringify(wrong));
try {
  execFileSync("node", [path.join(here, "risk.mjs"), "restore", "--from", path.join(base, "keys"), "--settings", wrongPath], { cwd: here, env: { ...env, APEX_RISK_HOME: path.join(base, "keys-wrong") }, encoding: "utf8", stdio: "pipe" });
  console.log("FAIL  restore accepted a wrong fingerprint");
  process.exitCode = 1;
} catch (error) {
  console.log(`PASS  restore rejects a wrong fingerprint (${String(error.stderr).trim()})`);
}
risk(["evidence"]);
// evidence + envelopes are placed into the synthetic workspace exactly as the real process copies them
const place = () => {
  const target = path.join(dir, "risk");
  fs.mkdirSync(target, { recursive: true });
  for (const f of fs.readdirSync(path.join(out, "risk"))) fs.copyFileSync(path.join(out, "risk", f), path.join(target, f));
};
place();
risk(["sign", "eligibility"]);
risk(["sign", "exception"]);
place();
risk(["sign", "authorization"]);
place();
const trustOut = risk(["trust"]);
const trustDir = path.join(base, "trust");
fs.mkdirSync(trustDir, { recursive: true, mode: 0o700 });
fs.copyFileSync(path.join(out, "risk-trust.json"), path.join(trustDir, "risk-trust.json"));
fs.chmodSync(path.join(trustDir, "risk-trust.json"), 0o600);
const pin = /APEX_RISK_TRUST_SHA256=([a-f0-9]{64})/.exec(trustOut)[1];
const environment = { APEX_RISK_TRUST_CONFIG: path.join(trustDir, "risk-trust.json"), APEX_RISK_TRUST_SHA256: pin };

const request = (action, extra = {}) => ({
  root: ws,
  project: "university",
  action,
  reviews: ["agent-output/university/challenge-findings-plan-pass10.json"],
  preserved_reviews: ["agent-output/university/challenge-findings-plan.json"],
  authorization: "agent-output/university/risk/risk-authorization.json",
  require_approval: false,
  ...extra,
});
const attempt = (label, fn) => {
  try {
    const r = fn();
    console.log(`PASS  ${label}: ${r.status}`);
    return r;
  } catch (error) {
    console.log(`FAIL  ${label}: ${error.message}`);
    process.exitCode = 1;
  }
};
const expectBlocked = (label, fn) => {
  try {
    fn();
    console.log(`FAIL  ${label}: expected block but passed`);
    process.exitCode = 1;
  } catch (error) {
    console.log(`PASS  ${label}: blocked (${error.message})`);
  }
};

attempt("authorization-only plan-complete", () => evaluateAuthorization(request("plan-complete"), environment));
expectBlocked("approval required but absent", () => evaluateAuthorization(request("plan-complete", { require_approval: true }), environment));
risk(["sign", "approval"]);
place();
for (const action of ["plan-complete", "codegen"])
  attempt(`approved ${action}`, () =>
    evaluateAuthorization(request(action, { approval: "agent-output/university/risk/risk-gate-approval.json", require_approval: true }), environment),
  );
for (const action of ["deploy", "deployment-complete"])
  expectBlocked(`kit authorization cannot ${action}`, () =>
    evaluateAuthorization(request(action, { approval: "agent-output/university/risk/risk-gate-approval.json", require_approval: true }), environment),
  );
console.log(`\nrevision 2: add code-complete, new IDs and file names, old files untouched`);
const rev2 = ["--revision", "2", "--actions", "plan-complete,codegen,code-complete"];
risk(["evidence", ...rev2]);
place();
risk(["sign", "eligibility", ...rev2]);
risk(["sign", "exception", ...rev2]);
place();
risk(["sign", "authorization", ...rev2]);
place();
const trust2 = risk(["trust", ...rev2]);
fs.copyFileSync(path.join(out, "risk-trust.r2.json"), path.join(trustDir, "risk-trust.json"));
fs.chmodSync(path.join(trustDir, "risk-trust.json"), 0o600);
const environment2 = { ...environment, APEX_RISK_TRUST_SHA256: /APEX_RISK_TRUST_SHA256=([a-f0-9]{64})/.exec(trust2)[1] };
risk(["sign", "approval", ...rev2]);
place();
const r2 = (action) =>
  request(action, {
    authorization: "agent-output/university/risk/risk-authorization.r2.json",
    approval: "agent-output/university/risk/risk-gate-approval.r2.json",
    require_approval: true,
  });
for (const action of ["plan-complete", "codegen", "code-complete"])
  attempt(`rev2 approved ${action}`, () => evaluateAuthorization(r2(action), environment2));
expectBlocked("rev2 still cannot deploy", () => evaluateAuthorization(r2("deploy"), environment2));
attempt("rev1 records still valid under the new trust file (plan-complete)", () =>
  evaluateAuthorization(request("plan-complete", { approval: "agent-output/university/risk/risk-gate-approval.json", require_approval: true }), environment2),
);
expectBlocked("rev1 cannot code-complete", () =>
  evaluateAuthorization(request("code-complete", { approval: "agent-output/university/risk/risk-gate-approval.json", require_approval: true }), environment2),
);
// extra must_fix finding must block (kept last: it changes the review bytes)
const extra = JSON.parse(fs.readFileSync(path.join(dir, "challenge-findings-plan-pass10.json"), "utf8"));
extra.findings.push({ id: "11112222", severity: "must_fix", claim: "x" });
fs.writeFileSync(path.join(dir, "challenge-findings-plan-pass10.json"), JSON.stringify(extra));
expectBlocked("changed review bytes / extra finding", () => evaluateAuthorization(r2("plan-complete"), environment2));
console.log(`\nworkspace: ${base}`);
