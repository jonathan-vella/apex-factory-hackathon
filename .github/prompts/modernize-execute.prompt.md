---
name: modernize-execute
description: 'B06: execute the reviewed Contoso University modernization plan'
agent: modernize
model: GPT-5.6 Luna
---

# Execute the reviewed modernization plan

Execute the reviewed plan in `.github/modernize/` for `app/ContosoUniversity`, task by task, in the plan's order. Don't change the plan's scope or order.

- After each task, run `dotnet build app/ContosoUniversity` and fix every error before you move on.
- Keep all the constraints in the plan: `DefaultAzureCredential` with no keys, SAS or connection strings with secrets; no password in any committed file; SQL authentication to `10.10.n.4` keeps working locally; App Service for Linux (containers) as the target.
- Don't provision, change or delete any Azure resources.
- Stop after each task, tell me what changed and whether it builds, and wait for me to reply `continue`.
