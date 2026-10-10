#!/usr/bin/env node
// Host-side helper for APEX lab risk records. Run it on YOUR machine, never in the agent container.
//   node risk.mjs keygen
//   node risk.mjs evidence --facts facts.json
//   node risk.mjs trust
//   node risk.mjs sign eligibility   --facts facts.json
//   node risk.mjs sign exception     --facts facts.json
//   node risk.mjs sign authorization --facts facts.json
//   node risk.mjs sign approval      --facts facts.json
// Private keys stay in ~/.apex-risk/private and are never printed. Every sign step shows what it will sign and
// requires you to type SIGN.
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import readline from "node:readline/promises";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { createHash, createPrivateKey, generateKeyPairSync, sign } from "node:crypto";

const here = path.dirname(fileURLToPath(import.meta.url));
const argv = process.argv.slice(2);
const option = (name, fallback) => {
  const i = argv.indexOf(`--${name}`);
  return i >= 0 ? argv[i + 1] : fallback;
};
const command = argv[0];
const sub = argv[1] && !argv[1].startsWith("--") ? argv[1] : undefined;

const settings = JSON.parse(fs.readFileSync(option("settings", path.join(here, "settings.json")), "utf8"));
// Later revisions: node risk.mjs ... --revision 2 --actions plan-complete,codegen,code-complete
if (option("revision")) settings.revision = Number(option("revision"));
if (option("actions")) settings.actions = option("actions").split(",");
const home = process.env.APEX_RISK_HOME || path.join(os.homedir(), ".apex-risk");
const out = path.resolve(option("out", path.join(here, "out")));
const riskDir = path.join(out, "risk");
const workspaceRiskDir = `agent-output/${settings.project}/risk`;

const sha = (bytes) => createHash("sha256").update(bytes).digest("hex");
const utc = (ms) => new Date(Math.floor(ms / 1000) * 1000).toISOString().replace(/\.\d{3}Z$/, "Z");
const now = Date.now();
const window = () => ({
  issued_at: utc(now - 60_000),
  not_before: utc(now - 60_000),
  expires_at: utc(now + settings.validity_days * 86_400_000),
});
const actions = settings.actions;
// Revision 1 keeps the original names. A later revision gets new IDs and file names so earlier signed files stay untouched.
const revision = settings.revision ?? 1;
const rev = revision > 1 ? `.r${revision}` : "";
const idRev = revision > 1 ? `-r${revision}` : "";
const authorizationId = `${settings.authorization_id}${idRev}`;
const fail = (message) => {
  console.error(`ERROR: ${message}`);
  process.exit(1);
};
const loadFacts = () => {
  const file = option("facts");
  if (!file) fail("--facts <facts.json> is required");
  const facts = JSON.parse(fs.readFileSync(file, "utf8"));
  if (facts.project !== settings.project) fail("facts project differs from settings project");
  if (Object.values(facts.current_supporting_hashes || {}).some((v) => v !== "match"))
    fail("a supporting input changed after the review; a fresh review is needed");
  const must = facts.findings.filter((f) => f.severity === "must_fix").map((f) => f.id);
  if (!must.length) fail("the review has no must_fix finding; no risk authorization is needed");
  for (const id of must) if (!settings.findings[id]) fail(`no settings for must_fix finding ${id}; every one must be handled explicitly`);
  for (const id of Object.keys(settings.findings)) if (!must.includes(id)) fail(`settings lists ${id}, which is not a current must_fix`);
  return { facts, must };
};
const workspaceRef = (name) => {
  const file = path.join(riskDir, name);
  if (!fs.existsSync(file)) fail(`missing ${file}; run the earlier step first`);
  return { path: `${workspaceRiskDir}/${name}`, sha256: sha(fs.readFileSync(file)) };
};
const write = (name, text) => {
  fs.mkdirSync(riskDir, { recursive: true });
  const file = path.join(riskDir, name);
  fs.writeFileSync(file, text);
  return { file, sha256: sha(Buffer.from(text)) };
};

function keyPaths(id) {
  return { privatePem: path.join(home, "private", `${id}.pem`), publicPem: path.join(home, "public", `${id}.pem`) };
}
function lockDown(file) {
  if (process.platform === "win32") {
    execFileSync("icacls", [file, "/inheritance:r", "/grant:r", `${os.userInfo().username}:F`], { stdio: "ignore" });
  } else fs.chmodSync(file, 0o600);
}

async function confirm(summary) {
  console.log(summary);
  if (process.env.APEX_RISK_TEST_YES === "1") return;
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  const answer = await rl.question("Type SIGN to sign this exact content, anything else aborts: ");
  rl.close();
  if (answer.trim() !== "SIGN") fail("aborted; nothing signed");
}

async function signPayload(keyName, payload, fileName, description) {
  const key = settings.keys[keyName];
  const { privatePem } = keyPaths(key.key_id);
  if (!fs.existsSync(privatePem)) fail(`missing private key for ${key.key_id}; run keygen`);
  const payloadBytes = Buffer.from(JSON.stringify(payload));
  await confirm(
    `\n=== ${description}\nSigner: ${key.key_id} (${key.principal})\nFile:   ${fileName}\nPayload:\n${JSON.stringify(payload, null, 2)}\n`,
  );
  const signature = sign(null, payloadBytes, createPrivateKey(fs.readFileSync(privatePem)));
  const envelope = {
    schema_version: "risk-envelope-v1",
    key_id: key.key_id,
    payload: payloadBytes.toString("base64"),
    signature: signature.toString("base64"),
  };
  const written = write(fileName, JSON.stringify(envelope));
  console.log(`Wrote ${written.file}\nsha256 ${written.sha256}`);
}

function keygen() {
  for (const key of Object.values(settings.keys)) {
    const { privatePem, publicPem } = keyPaths(key.key_id);
    if (fs.existsSync(privatePem)) fail(`${privatePem} exists; refusing to overwrite`);
    fs.mkdirSync(path.dirname(privatePem), { recursive: true });
    fs.mkdirSync(path.dirname(publicPem), { recursive: true });
    const pair = generateKeyPairSync("ed25519");
    fs.writeFileSync(privatePem, pair.privateKey.export({ type: "pkcs8", format: "pem" }), { mode: 0o600 });
    lockDown(privatePem);
    fs.writeFileSync(publicPem, pair.publicKey.export({ type: "spki", format: "pem" }));
    const der = pair.publicKey.export({ type: "spki", format: "der" });
    console.log(`${key.key_id}: created. public fingerprint ${sha(der).slice(0, 16)} (private key stays in ${privatePem})`);
  }
}

function evidence() {
  const { facts, must } = loadFacts();
  for (const id of must) {
    const finding = settings.findings[id];
    const claim = facts.findings.find((f) => f.id === id).claim;
    write(
      `eligibility-${id}${rev}.md`,
      [
        `# Eligibility assessment: finding ${id}`,
        "",
        `Project: ${settings.project}. Review: ${facts.review.path} (sha256 ${facts.review.sha256}).`,
        `Finding claim (quoted from the review): ${claim}`,
        "",
        `Classification: ${finding.classification}`,
        `Rule reference: ${finding.rule_reference}`,
        `Applicable law: no. Technical deployment possible: yes. Mandatory requirement: ${finding.classification === "mandatory-with-exception" ? "yes" : "no"}.`,
        "",
        "## Assessment",
        finding.assessment,
        "",
        "## Limits",
        settings.limits,
        "",
      ].join("\n"),
    );
    if (finding.classification === "mandatory-with-exception") {
      write(
        `exception-${id}${rev}.md`,
        [
          `# Rule-authority exception: finding ${id}`,
          "",
          `Rule: ${finding.rule_reference}`,
          `Scope: ${settings.operation} (kit, non-production lab). Actions: ${actions.join(", ")}.`,
          "",
          "## Exception",
          finding.exception_text,
          "",
          "## Limits",
          settings.limits,
          "",
        ].join("\n"),
      );
    }
  }
  console.log(`Evidence files written to ${riskDir}. Edit settings.json and rerun if the wording is not yours.`);
  for (const name of fs.readdirSync(riskDir)) console.log(`  ${name}  ${sha(fs.readFileSync(path.join(riskDir, name)))}`);
}

function trust() {
  const w = window();
  const grants = Object.values(settings.keys).map((key) => {
    const { publicPem } = keyPaths(key.key_id);
    if (!fs.existsSync(publicPem)) fail(`missing public key for ${key.key_id}; run keygen`);
    return {
      key_id: key.key_id,
      principal: key.principal,
      public_key: fs.readFileSync(publicPem, "utf8"),
      roles: key.roles,
      projects: [settings.project],
      actions,
      authority_evidence: key.authority_evidence,
      not_before: w.not_before,
      expires_at: w.expires_at,
      tenants: [],
      subscriptions: [],
      ...(key.rules ? { rules: key.rules } : {}),
    };
  });
  const text = JSON.stringify({
    schema_version: "risk-trust-v1",
    not_before: w.not_before,
    expires_at: w.expires_at,
    revoked_ids: [],
    revoked_keys: [],
    grants,
  });
  fs.mkdirSync(out, { recursive: true });
  fs.writeFileSync(path.join(out, `risk-trust${rev}.json`), text);
  console.log(`Wrote ${path.join(out, `risk-trust${rev}.json`)}\nAPEX_RISK_TRUST_SHA256=${sha(Buffer.from(text))}`);
}

async function signStep() {
  const { facts, must } = loadFacts();
  const w = window();
  const scope = { kind: "kit", environment: "non-production-lab", operation: settings.operation };
  if (sub === "eligibility") {
    for (const id of must) {
      const finding = settings.findings[id];
      await signPayload(
        "reviewer",
        {
          schema_version: "risk-eligibility-v1",
          id: `eligibility-${id}-${revision}`,
          project: settings.project,
          actions,
          not_before: w.not_before,
          expires_at: w.expires_at,
          review_sha256: facts.review.sha256,
          finding_id: id,
          classification: finding.classification,
          rule_reference: finding.rule_reference,
          applicable_law: false,
          mandatory_requirement: finding.classification === "mandatory-with-exception",
          technical_deployment_possible: true,
          source_evidence: [workspaceRef(`eligibility-${id}${rev}.md`)],
        },
        `risk-eligibility-${id}${rev}.json`,
        `Eligibility assessment for ${id} (${finding.classification})`,
      );
    }
  } else if (sub === "exception") {
    for (const id of must.filter((x) => settings.findings[x].classification === "mandatory-with-exception")) {
      await signPayload(
        "ruleAuthority",
        {
          schema_version: "risk-mandatory-exception-v1",
          id: `exception-${id}-${revision}`,
          project: settings.project,
          actions,
          not_before: w.not_before,
          expires_at: w.expires_at,
          review_sha256: facts.review.sha256,
          finding_id: id,
          rule_reference: settings.findings[id].rule_reference,
          authority_evidence: settings.keys.ruleAuthority.authority_evidence,
          scope,
          source_evidence: [workspaceRef(`exception-${id}${rev}.md`)],
        },
        `risk-exception-${id}${rev}.json`,
        `Mandatory-rule exception for ${id}`,
      );
    }
  } else if (sub === "authorization") {
    const findings = must.map((id) => {
      const finding = settings.findings[id];
      const entry = {
        id,
        classification: finding.classification,
        rule_reference: finding.rule_reference,
        rationale: finding.rationale,
        residual_impact: finding.residual_impact,
        owner: settings.owner,
        eligibility_evidence: [workspaceRef(`risk-eligibility-${id}${rev}.json`)],
      };
      if (finding.classification === "mandatory-with-exception") entry.mandatory_exception = workspaceRef(`risk-exception-${id}${rev}.json`);
      return entry;
    });
    await signPayload(
      "owner",
      {
        schema_version: "risk-authorization-v1",
        id: authorizationId,
        project: settings.project,
        scope,
        actions,
        ...w,
        revocation_conditions: ["input-change", "scope-change", "authority-revoked", "authorization-revoked", "validity-expired"],
        authority_evidence: settings.keys.owner.authority_evidence,
        preserved_reviews: facts.preserved_reviews,
        bindings: [
          {
            review: facts.review,
            artifact: { path: facts.challenged_artifact, sha256: facts.cache_inputs.artifact_sha },
            cache_inputs: facts.cache_inputs,
            supporting_inputs: facts.supporting_inputs.map((s) => ({ path: s.path, sha256: s.sha256 })),
            findings,
          },
        ],
        obligations: settings.obligations,
      },
      `risk-authorization${rev}.json`,
      `Kit risk authorization, revision ${revision} (actions: ${actions.join(", ")}; permits NO deployment)`,
    );
  } else if (sub === "approval") {
    await signPayload(
      "owner",
      {
        schema_version: "risk-gate-approval-v1",
        id: `${authorizationId}-gate`,
        project: settings.project,
        authorization_sha256: workspaceRef(`risk-authorization${rev}.json`).sha256,
        actions,
        approved_at: utc(now - 30_000),
        not_before: w.not_before,
        expires_at: w.expires_at,
        verified_obligations: [],
      },
      `risk-gate-approval${rev}.json`,
      "Separate human gate approval of the validated authorization",
    );
  } else fail("sign needs one of: eligibility, exception, authorization, approval");
}

if (command === "keygen") keygen();
else if (command === "evidence") evidence();
else if (command === "trust") trust();
else if (command === "sign") await signStep();
else fail("commands: keygen | evidence | trust | sign <eligibility|exception|authorization|approval>");
