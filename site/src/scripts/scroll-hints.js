export function initScrollHints() {
  const targets = document.querySelectorAll(
    ".sl-markdown-content .expressive-code pre, .sl-markdown-content table",
  );
  const updates = new Map();
  const observer = new ResizeObserver((entries) => {
    for (const update of new Set(entries.map(({ target }) => updates.get(target)))) update();
  });

  targets.forEach((target, index) => {
    const block = target.closest(".expressive-code") ?? target;
    const hint = document.createElement("p");
    hint.className = "doc-scroll-hint";
    hint.id = `doc-scroll-hint-${index + 1}`;
    hint.hidden = true;
    hint.textContent = `Scroll horizontally to see the full ${target.matches("pre") ? "command or example" : "table"}.`;
    block.after(hint);
    const tabIndex = target.getAttribute("tabindex");
    const description = target.getAttribute("aria-describedby");
    const update = () => {
      const overflows = target.clientWidth > 0 && target.scrollWidth - target.clientWidth > 1;
      hint.hidden = !overflows;
      if (overflows) {
        target.tabIndex = 0;
        target.setAttribute("aria-describedby", [description, hint.id].filter(Boolean).join(" "));
      } else {
        if (tabIndex === null) target.removeAttribute("tabindex");
        else target.setAttribute("tabindex", tabIndex);
        if (description === null) target.removeAttribute("aria-describedby");
        else target.setAttribute("aria-describedby", description);
      }
    };

    // Code and table contents can grow after fonts load without resizing their scrollport.
    for (const element of [target, ...target.children]) {
      updates.set(element, update);
      observer.observe(element);
    }
  });
}
