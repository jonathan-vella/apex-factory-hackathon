# Eligibility assessment: finding bc629836

Project: university. Review: agent-output/university/challenge-findings-plan-pass10.json (sha256 f78b1970c02027d37fa8acc2eed88e03f62a6427f938f7e2debcd9dc03e7b5e5).
Finding claim (quoted from the review): Unauthenticated public ingress can exercise the workload identity

Classification: mandatory-with-exception
Rule reference: IaC Security Baseline: App Service hosting a public-facing web application - public HTTPS ingress permitted; authentication and other security controls still apply
Applicable law: no. Technical deployment possible: yes. Mandatory requirement: yes.

## Assessment
The baseline states that public HTTPS ingress is permitted but that authentication and other security controls still apply. The reviewer treats this as a mandatory baseline requirement, not as optional guidance, so a rule-authority exception is required. No applicable law is identified. Deployment is technically possible.

## Limits
Kit-authoring authorization only for a non-production lab. It grants no deployment and no production reuse. Each adopting team must supply its own tenant authorization, event expiry, cleanup owner and teardown verification before any deployment. The three signing identities are held by the same person; independence is therefore limited to separate keys and separate principal records, and is accepted by the owner for a lab.
