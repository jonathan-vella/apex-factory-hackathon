# Event owner: make and maintain a kit copy

## Create the event copy

1. Create the event repository from the kit's GitHub template. Keep the upstream repository as a separate remote if you plan to pull updates.
2. Update event branding, the event dates, room instructions and local escalation contacts in your copy. Keep private contact details in your event's private channel, not in this public template.
3. Set the region to `swedencentral`, or use `germanywestcentral` when the default is unavailable. Do not pin zones or enable zone redundancy.
4. Preserve the two-subscription model, names, private networking, security constraints and the challenge point/time contract. If you intentionally change a technical contract, validate it and update the affected attendee and coach material together.
5. Keep `versions.md` as the compatibility record. Before each event, compare its pinned versions and validation dates with the current upstream file; validate any update in a disposable environment before adopting it.
6. Check that the event copy includes the lifeline branches. Template copies may omit non-default branches; use the mirror procedure below if coaches need local copies.

## Mirror coach-only lifelines

Lifelines are public, coach-only checkpoints. Members must not fetch or apply them without a coach. From a clone of the event repository, fetch each upstream branch and push it to the event repository:

```powershell
$upstream = 'https://github.com/jonathan-vella/apex-factory-hackathon.git'
git fetch $upstream lifeline/L1-net10:refs/remotes/upstream/lifeline/L1-net10
git fetch $upstream lifeline/L2-blob:refs/remotes/upstream/lifeline/L2-blob
git fetch $upstream lifeline/L3-servicebus:refs/remotes/upstream/lifeline/L3-servicebus
git fetch $upstream lifeline/L4-ready:refs/remotes/upstream/lifeline/L4-ready
git fetch $upstream lifeline/L5-cutover:refs/remotes/upstream/lifeline/L5-cutover
git push origin refs/remotes/upstream/lifeline/L1-net10:refs/heads/lifeline/L1-net10
git push origin refs/remotes/upstream/lifeline/L2-blob:refs/heads/lifeline/L2-blob
git push origin refs/remotes/upstream/lifeline/L3-servicebus:refs/heads/lifeline/L3-servicebus
git push origin refs/remotes/upstream/lifeline/L4-ready:refs/heads/lifeline/L4-ready
git push origin refs/remotes/upstream/lifeline/L5-cutover:refs/heads/lifeline/L5-cutover
git ls-remote --heads origin "lifeline/*"
```

The last command should list all five branches. If GitHub refuses a push because the token lacks the `workflow` scope, ask the repository owner to refresh the token with the required scope rather than copying the workflow files by hand.

## Keep copies current

- Review upstream release notes and `versions.md` before each event. Bring in content and security fixes, then rerun the repository's checks.
- Do not update pinned software versions in isolation. Use the version's published migration notes and repeat the relevant validation.
- Keep coach keys and lifelines in coach hands. Public availability is not attendee instruction.
- Record local changes in the event repository's history so the next event owner can distinguish branding from technical changes.
