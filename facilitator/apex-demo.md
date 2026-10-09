# APEX archetype demo

- **Length:** 30 minutes
- **Audience:** event attendees, event owner and coaches
- **Presenter:** event deliverer
**Recording:** <!-- TODO: owner records this demo, paste the link here -->

## Before the demo

- Use a prepared APEX repo based on the pinned `apex-accelerator` commit in `archetype/README.md`, with the archetype brief and its review history available.
- Have a disposable event demo subscription and vended spoke ready. Confirm the `azd` environment is the intended one, the preview is understood and any deployment has an approved cleanup plan.
- Close terminals and browser tabs that could reveal credentials, tenant or subscription IDs, private email addresses or unrelated resources. Use placeholders when narrating inputs.
- Do not run APEX Deploy (`07b`) as the default deployment path. The member path is APEX for adaptation and review, then `azd provision --preview` and `azd provision`.
- SQL MI provisioning can outlast this presentation. Start the live deployment during the demo; never start a second deployment to make the timing look better.

## Run of show

| Time | Section | Presenter actions and talking points |
|---|---|---|
| 00:00–03:00 | What APEX is | Describe APEX as an accelerator for turning a workload brief into reviewed architecture and deployment artifacts. The accelerator does not replace human decisions, challenger reviews or validation. |
| 03:00–07:00 | This workload | Open `archetype/BRIEF.md`. Explain the existing Corp spoke, private backends, public HTTPS web front end, managed identity, Entra-only SQL and the two documented public exceptions. The archetype creates the platform; C6/C7 modernize and go live with the application. |
| 07:00–15:00 | Steps 1–5 and challenger reviews | Walk the audience through the APEX run: **1.** turn the brief into explicit requirements; **2.** assess the workload and constraints; **3.** compare architecture choices and record ADRs; **4.** plan the implementation and validate governance; **5.** produce the implementation reference and Bicep. At each stage, show the challenger review, the question it tested, and the resulting decision or correction. Show the corresponding requirements, assessment, ADRs, plan and implementation reference in `agent-output/university/`. |
| 15:00–18:00 | Adapt, preview and explain | Show the `adapt-archetype` prompt in built-in agent mode. It asks only for tenant ID, subscription ID and suffix, checks the vended spoke and governance, creates the `azd` environment, runs preflight and stops at `azd provision --preview`. Explain that the preview omits some resource types even though the template deploys them. |
| 18:00–20:00 | Start the live deployment | From `infra/bicep/university/`, run `azd provision`. Say: “The preview is the review gate; this command is the explicit deployment.” Point out that the pre- and post-provision hooks run their checks and write the deployment summary. |
| 20:00–28:00 | Read the deployment while it runs | Walk through the expected resource groups: App Service, ACR, SQL MI, Blob, Service Bus, Key Vault and monitoring. Explain that the MI may still be provisioning after the other resources are ready. Review the identities, private endpoints, central DNS, diagnostics, AHB and zone settings from the reviewed artifacts. |
| 28:00–30:00 | Verify and hand off | Show the deployment result if it has completed, then the post-deploy checks and As-Built output. If MI provisioning is still in progress, say so, leave the one deployment running, and show a previously verified deployment record rather than claiming success. Hand off to C6 and the modernization playbook. |

## Presenter notes

- Keep the distinction clear: APEX produced and reviewed the archetype; `azd` applies it. The default event path is not an autonomous agent deployment.
- Show the reviewer feedback and how the team resolved it; do not present generated output as correct merely because it was generated.
- The app is not modernized or deployed by this demo. The kit's application code remains the attendee's responsibility.
- The live demo must use an approved, disposable environment. No Azure deployment is part of B12.
