# Event owner: make and maintain a kit copy

## Create the event copy

1. Create the event repository from the kit's GitHub template. Keep the upstream repository as a separate remote if you plan to pull updates.
2. Update event branding, the event dates, room instructions and local escalation contacts in your copy. Keep private contact details in your event's private channel, not in this public template.
3. Set the region to `swedencentral`, or use `germanywestcentral` when the default is unavailable. Do not pin zones or enable zone redundancy.
4. Preserve the two-subscription model, names, private networking, security constraints and the challenge point/time contract. If you intentionally change a technical contract, validate it and update the affected attendee and coach material together.
5. Keep `versions.md` as the compatibility record. Before each event, compare its pinned versions and validation dates with the current upstream file; validate any update in a disposable environment before adopting it.
6. Know what the copy does and doesn't control. Attendees run `Import-Kit.ps1`, the datacenter deployment's script download and the `vm-dev01` clone against the upstream `jonathan-vella/apex-factory-hackathon` repository at `main`, so an event copy doesn't change what they run. Keep technical changes upstream, or agree with attendees and coaches which copy they use before the event. Pull upstream changes only when you've reviewed them, because `main` moves under attendees.
7. Work through the [T-30 to T-14 checklist](guide.md#t-30-to-t-14-event-owner) in the facilitator guide: roster, member indexes, platform lead, team-repo creator and access.

## Lifelines

Lifelines are public, coach-only checkpoints. Members must not fetch or apply them without a coach. Coaches fetch them from the upstream repository, which is the `origin` of the clone on `vm-dev01`, so there is one source and nothing to mirror (see the [lifeline index](../coach/lifelines.md)). The known-good image is also pulled from upstream.

## Keep copies current

- Review upstream release notes and `versions.md` before each event. Bring in content and security fixes, then rerun the repository's checks.
- Do not update pinned software versions in isolation. Use the version's published migration notes and repeat the relevant validation.
- Keep coach keys and lifelines in coach hands. Public availability is not attendee instruction.
- Record local changes in the event repository's history so the next event owner can distinguish branding from technical changes.
