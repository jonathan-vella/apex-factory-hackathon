import assert from "node:assert/strict";
import test from "node:test";
import { readFile, stat } from "node:fs/promises";
import { createEventDrafts } from "../site/src/scripts/event-materials.js";

test("event drafts retain placeholders and the documented preparation sequence", () => {
  const drafts = createEventDrafts();
  assert.deepEqual(
    drafts.map(({ id }) => id),
    ["overview-email", "briefing-invite", "hackathon-invite"],
  );
  const email = drafts[0].text;
  assert.match(email, /\[organizer name\]/);
  assert.match(email, /\[briefing date and time, including time zone\]/);
  const preparation = email.split("Preparation happens in stages:")[1].split("\n")[0];
  assert.deepEqual(preparation.match(/\bT-(?:14|7|3|1)\b/g), ["T-14", "T-7", "T-3", "T-1"]);
  assert.match(email, /No coach is on duty during pre-event setup/);
  assert.doesNotMatch(drafts.map(({ text }) => text).join("\n"), /attached PDF|three-page/i);
});

test("event details appear in the appropriate editable drafts", () => {
  const [email, briefing, hackathon] = createEventDrafts({
    organizer: "  Event owner  ",
    contact: "Team lead",
    briefingWhen: "10 November, 10:00-11:00 CET",
    briefingLocation: "Briefing room",
    dayOne: "24 November",
    dayOneTime: "08:30-16:45",
    dayTwo: "25 November",
    dayTwoTime: "08:30-17:00",
    timeZone: "CET",
    eventLocation: "Event room",
    resources: "https://example.test/event-materials/",
  });

  assert.match(email.text, /Know Before You Go: 10 November, 10:00-11:00 CET/);
  assert.match(email.text, /Best,\nEvent owner$/);
  assert.match(briefing.text, /Location: Briefing room/);
  assert.match(hackathon.text, /Day 1: 24 November, 08:30-16:45 CET/);
  assert.match(hackathon.text, /Day 2: 25 November, 08:30-17:00 CET/);
  assert.match(hackathon.text, /Location: Event room/);
  for (const draft of [email, briefing, hackathon]) {
    assert.match(draft.text, /https:\/\/example\.test\/event-materials\//);
    assert.match(draft.text, /Contact: Team lead/);
    assert.doesNotMatch(draft.text, /\[[^\]]+\]/);
  }
});

test("blank event details remain visible placeholders", () => {
  const [email, , hackathon] = createEventDrafts({
    organizer: "  ",
    dayOne: "",
    dayTwoTime: "",
  });
  assert.match(email.text, /Best,\n\[organizer name\]$/);
  assert.match(hackathon.text, /Day 1: \[day 1 date\], \[day 1 time\] \[time zone\]/);
  assert.match(hackathon.text, /Day 2: \[day 2 date\], \[day 2 time\] \[time zone\]/);
});

  test("every draft links to the current guides without fixed event dates", () => {
    for (const { text } of createEventDrafts()) {
      for (const target of [
        "https://factory.apexops.pro/getting-started/requirements/",
        "https://factory.apexops.pro/getting-started/roles/",
        "https://factory.apexops.pro/deploy/",
      ]) {
        assert.ok(text.includes(target));
      }
      assert.doesNotMatch(text, /VS Code 1\.100|three-page|25-minute|\b20\d{2}\b/);
    }
    assert.match(createEventDrafts()[0].text, /tenant-owner approval/);
    assert.match(createEventDrafts()[2].text, /Keep vm-dev01 running throughout the event/);
  });

  test("event page downloads exist and describe the approved output set", async () => {
    const page = await readFile(
      new URL("../site/src/content/docs/getting-started/event-materials.mdx", import.meta.url),
      "utf8",
    );
    const links = [...page.matchAll(/href="\/downloads\/([^"]+)"/g)];
    assert.equal(links.length, 10);
    for (const [, filename] of links) {
      const file = new URL(`../site/public/downloads/${filename}`, import.meta.url);
      assert.ok((await stat(file)).size > 0, `${filename} must not be empty`);
    }
    assert.doesNotMatch(page, /need an update|outdated details|1\.100|24 November 2026/);
    assert.match(page, /remain placeholders/);
    const description = await readFile(
      new URL("../site/public/downloads/description.txt", import.meta.url),
      "utf8",
    );
    assert.match(description, /classification to Public/);
    assert.doesNotMatch(description, /carries the same Microsoft Confidential/);
  });
