/*
 * Browser-only progress for the challenge pages. No accounts, no server: everything lives in
 * localStorage under one key, so other components can read it.
 *
 *   localStorage["apex-factory-progress:v1"] = {
 *     version: 1,
 *     pages: {
 *       "/challenges/c03-assess-the-source/": {
 *         id: "c03",
 *         tasks:    { total: 6, done: ["0:1x9k2a", "2:q81bz0"] },   // "index:text hash"
 *         evidence: { total: 4, done: [] },
 *         updated: "2026-10-20T13:05:00.000Z"
 *       }
 *     }
 *   }
 *
 * An item counts as done when its "index:hash" pair matches, or when its text hash matches at
 * another index (the list was re-ordered). An edited item has a new hash, so it starts unticked.
 */

const KEY = "apex-factory-progress:v1";
const CHANGE_EVENT = "apex-factory-progress-change";
const CHALLENGE_PATH = /\/challenges\/(c\d+)-[^/]+\/$/;

export function readProgress() {
  try {
    const data = JSON.parse(localStorage.getItem(KEY) ?? "null");
    if (data && data.version === 1 && data.pages && typeof data.pages === "object") return data;
  } catch {
    // Storage blocked or corrupt: start empty.
  }
  return { version: 1, pages: {} };
}

function writeProgress(data) {
  try {
    localStorage.setItem(KEY, JSON.stringify(data));
    return true;
  } catch {
    return false;
  }
}

function hashText(text) {
  const normalized = text.replace(/\s+/g, " ").trim();
  let h = 5381;
  for (let i = 0; i < normalized.length; i++) h = ((h << 5) + h + normalized.charCodeAt(i)) | 0;
  return (h >>> 0).toString(36);
}

function findSectionList(headingId, tagName) {
  const heading = document.getElementById(headingId);
  if (!heading) return null;
  let el = (heading.closest(".sl-heading-wrapper") ?? heading).nextElementSibling;
  while (el && !el.matches(".sl-heading-wrapper.level-h2, h2")) {
    if (el.tagName === tagName) return el;
    el = el.nextElementSibling;
  }
  return null;
}

function srOnly(text) {
  const span = document.createElement("span");
  span.className = "task-sr-only";
  span.textContent = text;
  return span;
}

function createControl(kind, number) {
  const label = document.createElement("label");
  label.className = `task-check task-check--${kind}`;
  const input = document.createElement("input");
  input.type = "checkbox";
  input.className = "task-check__input";
  label.append(input);
  if (kind === "task") {
    const text = document.createElement("span");
    text.className = "task-check__text";
    text.textContent = "Done";
    label.append(text, srOnly(` task ${number}`));
  } else {
    label.append(srOnly(`Evidence item ${number} collected`));
  }
  return { label, input };
}

function collectItems(list, kind) {
  return [...list.children]
    .filter((li) => li.tagName === "LI")
    .map((li, index) => {
      const hash = hashText(li.textContent ?? "");
      const title = (li.textContent ?? "").replace(/\s+/g, " ").trim();
      const { label, input } = createControl(kind, index + 1);
      li.classList.add(kind === "task" ? "task-item" : "evidence-item");
      li.prepend(label);
      return { li, input, index, hash, title, key: `${index}:${hash}` };
    });
}

function isStored(item, done) {
  return done.some((entry) => entry === item.key || entry.split(":")[1] === item.hash);
}

function createBar(total) {
  const bar = document.createElement("div");
  bar.className = "task-bar not-content";
  bar.setAttribute("role", "region");
  bar.setAttribute("aria-label", "Task progress");

  const count = document.createElement("p");
  count.className = "task-bar__count";
  count.setAttribute("aria-live", "polite");
  count.setAttribute("aria-atomic", "true");

  const meter = document.createElement("progress");
  meter.className = "task-bar__meter";
  meter.max = total;
  meter.value = 0;
  meter.setAttribute("aria-hidden", "true");

  const toggle = document.createElement("button");
  toggle.type = "button";
  toggle.className = "task-bar__toggle";
  toggle.setAttribute("aria-expanded", "false");
  toggle.setAttribute("aria-controls", "task-bar-panel");
  toggle.textContent = "Jump to task";

  const panel = document.createElement("div");
  panel.className = "task-bar__panel";
  panel.id = "task-bar-panel";

  const nav = document.createElement("nav");
  nav.className = "task-bar__jump";
  nav.setAttribute("aria-label", "Jump to task");

  const reset = document.createElement("button");
  reset.type = "button";
  reset.className = "task-bar__reset";
  reset.textContent = "Reset";

  panel.append(nav, reset);
  bar.append(count, meter, toggle, panel);
  return { bar, count, meter, toggle, nav, reset };
}

function setupChallengePage(path) {
  const taskList = findSectionList("your-tasks", "OL");
  if (!taskList) return;
  const content = document.querySelector(".sl-markdown-content");
  if (!content) return;

  const tasks = collectItems(taskList, "task");
  if (tasks.length === 0) return;
  const evidenceList = findSectionList("evidence", "UL");
  const evidence = evidenceList ? collectItems(evidenceList, "evidence") : [];

  const ui = createBar(tasks.length);
  tasks.forEach((task, i) => {
    if (!task.li.id) task.li.id = `task-${i + 1}`;
    const chip = document.createElement("a");
    chip.className = "task-bar__chip";
    chip.href = `#${task.li.id}`;
    chip.title = task.title.length > 70 ? `${task.title.slice(0, 67)}...` : task.title;
    const state = srOnly("");
    chip.append(srOnly("Task "), document.createTextNode(String(i + 1)), state);
    task.chip = chip;
    task.chipState = state;
    ui.nav.append(chip);
  });
  content.prepend(ui.bar);

  const challengeId = path.match(CHALLENGE_PATH)?.[1] ?? "";

  function render() {
    let done = 0;
    for (const item of tasks) {
      const checked = item.input.checked;
      if (checked) done++;
      item.li.classList.toggle("is-done", checked);
      item.chip.dataset.done = String(checked);
      item.chipState.textContent = checked ? " (done)" : "";
    }
    for (const item of evidence) item.li.classList.toggle("is-done", item.input.checked);
    ui.count.textContent =
      done === tasks.length
        ? `All ${tasks.length} tasks done`
        : `Tasks ${done} of ${tasks.length} done`;
    ui.meter.value = done;
    ui.bar.classList.toggle("is-complete", done === tasks.length);
  }

  function applyStored() {
    const entry = readProgress().pages[path];
    for (const item of tasks)
      item.input.checked = Boolean(entry) && isStored(item, entry.tasks?.done ?? []);
    for (const item of evidence)
      item.input.checked = Boolean(entry) && isStored(item, entry.evidence?.done ?? []);
    render();
  }

  function save() {
    const data = readProgress();
    const doneKeys = (items) => items.filter((i) => i.input.checked).map((i) => i.key);
    const taskKeys = doneKeys(tasks);
    const evidenceKeys = doneKeys(evidence);
    if (taskKeys.length === 0 && evidenceKeys.length === 0) {
      delete data.pages[path];
    } else {
      data.pages[path] = {
        id: challengeId,
        tasks: { total: tasks.length, done: taskKeys },
        evidence: { total: evidence.length, done: evidenceKeys },
        updated: new Date().toISOString(),
      };
    }
    writeProgress(data);
    document.dispatchEvent(new CustomEvent(CHANGE_EVENT));
  }

  for (const item of [...tasks, ...evidence]) {
    item.input.addEventListener("change", () => {
      render();
      save();
    });
  }

  ui.toggle.addEventListener("click", () => {
    const open = ui.toggle.getAttribute("aria-expanded") !== "true";
    ui.toggle.setAttribute("aria-expanded", String(open));
    ui.bar.classList.toggle("is-open", open);
  });

  let resetTimer;
  function cancelReset() {
    clearTimeout(resetTimer);
    delete ui.reset.dataset.confirm;
    ui.reset.textContent = "Reset";
  }
  ui.reset.addEventListener("click", () => {
    if (ui.reset.dataset.confirm !== "true") {
      ui.reset.dataset.confirm = "true";
      ui.reset.textContent = "Confirm reset";
      resetTimer = setTimeout(cancelReset, 4000);
      return;
    }
    cancelReset();
    for (const item of [...tasks, ...evidence]) item.input.checked = false;
    render();
    save();
  });
  ui.reset.addEventListener("blur", cancelReset);

  window.addEventListener("storage", (event) => {
    if (event.key === KEY) applyStored();
  });

  applyStored();

  // The bar shifts the page when it is inserted, so re-apply a deep link such as #task-3.
  if (location.hash.length > 1) {
    try {
      document.getElementById(decodeURIComponent(location.hash.slice(1)))?.scrollIntoView();
    } catch {
      // Malformed hash: leave the scroll position alone.
    }
  }
}

function markDoneLinks() {
  const pages = readProgress().pages;
  const scope = location.pathname.endsWith("/challenges/")
    ? ".sidebar-content a, .sl-markdown-content a"
    : ".sidebar-content a";
  for (const link of document.querySelectorAll(scope)) {
    link.querySelectorAll(":scope > .progress-flag").forEach((el) => el.remove());
    const pathname = new URL(link.href, location.href).pathname;
    if (!CHALLENGE_PATH.test(pathname)) continue;
    const entry = pages[pathname];
    if (!entry?.tasks?.total || entry.tasks.done.length < entry.tasks.total) continue;
    const flag = document.createElement("span");
    flag.className = "progress-flag";
    const mark = document.createElement("span");
    mark.setAttribute("aria-hidden", "true");
    mark.textContent = "\u2713";
    flag.append(mark, srOnly(" (all tasks done)"));
    link.append(flag);
  }
}

export function initProgress() {
  const path = location.pathname;
  if (CHALLENGE_PATH.test(path)) setupChallengePage(path);
  markDoneLinks();
  document.addEventListener(CHANGE_EVENT, markDoneLinks);
  window.addEventListener("storage", (event) => {
    if (event.key === KEY) markDoneLinks();
  });
}
