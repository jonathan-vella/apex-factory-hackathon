# Rule-authority exception: finding bc629836

Rule: IaC Security Baseline: App Service hosting a public-facing web application - public HTTPS ingress permitted; authentication and other security controls still apply
Scope: author reusable lab kit (Plan approval and CodeGen only) (kit, non-production lab). Actions: plan-complete, codegen.

## Exception
As maintainer and rule authority of the APEX IaC security baseline, the owner grants an exception to the 'authentication still applies' requirement for the public-facing web application of this kit only, for non-production lab authoring (Plan approval and CodeGen). The exception does not extend to deployment, production, or any other project, and each adopting team must separately authorize any deployment.

## Limits
Kit-authoring authorization only for a non-production lab. It grants no deployment and no production reuse. Each adopting team must supply its own tenant authorization, event expiry, cleanup owner and teardown verification before any deployment. The three signing identities are held by the same person; independence is therefore limited to separate keys and separate principal records, and is accepted by the owner for a lab.
