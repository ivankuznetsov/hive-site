// Read-only browser regression/screenshot check. Serve _site first.
// PLAYWRIGHT_MODULE may name an existing Playwright installation; no browser
// dependency is added to the production site. BROWSER_CDP attaches in an owned context.
import assert from "node:assert/strict";
import fs from "node:fs/promises";
const { chromium } = await import(
  process.env.PLAYWRIGHT_MODULE || "playwright"
);
const base = process.env.SITE_URL || "http://127.0.0.1:8797";
const output = process.env.REVIEW_OUTPUT || "test-results/browser";
await fs.mkdir(output, { recursive: true });
const browser = process.env.BROWSER_CDP
  ? await chromium.connectOverCDP(process.env.BROWSER_CDP)
  : await chromium.launch({ headless: true });
const checks = [],
  errors = [],
  blocked = [];
const check = (name, condition) => {
  assert.ok(condition, name);
  checks.push(name);
};
async function context(options = {}) {
  const c = await browser.newContext(options);
  await c.route("**/*", (route) => {
    const r = route.request();
    if (!["GET", "HEAD"].includes(r.method())) {
      blocked.push(`${r.method()} ${r.url()}`);
      return route.abort();
    }
    return route.continue();
  });
  c.on("page", (p) => p.on("pageerror", (e) => errors.push(e.message)));
  return c;
}
async function home(p) {
  await p.goto(base, { waitUntil: "load" });
  await p.locator("[data-workflow-app]:not([hidden])").waitFor();
  await p.evaluate(() => document.fonts.ready);
  await p.addStyleTag({ content: "html{scroll-behavior:auto!important}" });
}
async function noOverflow(p, name) {
  const size = await p.evaluate(() => ({
    client: document.documentElement.clientWidth,
    scroll: document.documentElement.scrollWidth,
  }));
  check(
    `${name}: no page overflow (${size.scroll}/${size.client})`,
    size.scroll <= size.client + 1,
  );
}
const shot = (p, name, locator) =>
  locator
    ? locator.screenshot({ path: `${output}/${name}.png` })
    : p.screenshot({ path: `${output}/${name}.png` });
try {
  for (const spec of [
    { name: "desktop-light", width: 1440, height: 1000, colorScheme: "light" },
    { name: "desktop-dark", width: 1440, height: 1000, colorScheme: "dark" },
    { name: "tablet-light", width: 768, height: 1024, colorScheme: "light" },
    { name: "mobile-dark", width: 390, height: 844, colorScheme: "dark" },
    { name: "small-light", width: 320, height: 740, colorScheme: "light" },
  ]) {
    const c = await context({
      viewport: { width: spec.width, height: spec.height },
      colorScheme: spec.colorScheme,
    });
    try {
      const p = await c.newPage();
      await home(p);
      check(
        `${spec.name}: hero and framework CTA`,
        (await p.locator("h1").innerText()).replace(/\s+/g, " ") ===
          "Durable workflows for AI agents" &&
          (await p.locator(".fw-actions a").first().getAttribute("href")) ===
            "#install",
      );
      await noOverflow(p, spec.name);
      await shot(p, `${spec.name}-hero`);
      await p
        .locator(".fw-platform")
        .last()
        .evaluate((el) => (el.open = true));
      await noOverflow(p, `${spec.name} Linux install expanded`);
      if (spec.width < 600) {
        await p.locator(".site-menu summary").click();
        check(
          `${spec.name}: mobile docs and menu`,
          (await p.locator(".site-nav>a").first().isVisible()) &&
            (await p.locator('.site-menu a[href="/honeycombs/"]').isVisible()),
        );
        await p.locator(".site-menu summary").click();
      }
      if (spec.name === "desktop-light") {
        check(
          "coding starts with nine stations and no automatic playback",
          (await p.locator("[data-stations] button").count()) === 9 &&
            (await p.locator("[data-play]").innerText()) === "Play example",
        );
        check(
          "coding shows its review-to-fix return route",
          await p.locator("[data-return]").isVisible(),
        );
        await shot(p, "coding-overview", p.locator(".workflow-theatre"));
        await p.locator("[data-stations] button").nth(5).click();
        await shot(p, "coding-review", p.locator(".workflow-theatre"));
        await p.locator("[data-next]").click();
        await shot(p, "coding-fix", p.locator(".workflow-theatre"));
        await p.locator("[data-next]").click();
        check(
          "review finding returns to execution and recheck before evidence",
          (await p.locator("[data-state-label]").innerText()) ===
            "Stage output" &&
            (await p.locator("[data-stage-number]").innerText()).includes(
              "Review",
            ),
        );
        await p.getByRole("tab", { name: "Content Built-in" }).click();
        check(
          "content has six stations",
          (await p.locator("[data-stations] button").count()) === 6,
        );
        check(
          "content has no coding-only return route",
          !(await p.locator("[data-return]").isVisible()),
        );
        await p.locator("[data-stations] button").nth(3).click();
        check(
          "content draft receives saved research and outline",
          (await p.locator("[data-saved]").innerText()).includes(
            "research.md",
          ) &&
            (await p.locator("[data-saved]").innerText()).includes(
              "outline.md",
            ),
        );
        await p.locator("[data-interrupt]").click();
        check(
          "interruption stops advancement without losing inputs",
          (await p.locator("[data-next]").isDisabled()) &&
            (await p.locator("[data-saved]").innerText()).includes(
              "outline.md",
            ),
        );
        await shot(p, "content-interrupted", p.locator(".workflow-theatre"));
        await p.locator("[data-retry]").click();
        check(
          "retry begins a second attempt at the same stage",
          (await p.locator("[data-stage-number]").innerText()).includes(
            "Draft",
          ) &&
            (await p.locator("[data-state-label]").innerText()) === "Attempt 2",
        );
        await p.locator("[data-next]").click();
        check(
          "retry hands the saved draft to critique",
          (await p.locator("[data-stage-number]").innerText()).includes(
            "Critique",
          ) &&
            (await p.locator("[data-saved]").innerText()).includes("draft.md"),
        );
        await p.getByRole("tab", { name: "Research Custom example" }).click();
        await p.locator("[data-stations] button").last().click();
        check(
          "human stage requires an explicit demo decision",
          (await p.locator("[data-approve]").isVisible()) &&
            (await p.locator("[data-next]").isDisabled()) &&
            (await p.locator("[data-play]").isDisabled()),
        );
        await shot(p, "research-decision", p.locator(".workflow-theatre"));
        await p.locator("[data-reject]").click();
        check(
          "rejection returns to synthesis with research intact",
          (await p.locator("[data-stage-number]").innerText()).includes(
            "Synthesize",
          ) &&
            (await p.locator("[data-saved]").innerText()).includes(
              "research.md",
            ),
        );
        await p.locator("[data-next]").click();
        await p.locator("[data-approve]").click();
        check(
          "approval completes locally and records both decisions",
          (await p.locator("[data-context]").innerText()).includes(
            "revision requested → approved",
          ) &&
            (await p.locator("[data-sample]").innerText()).includes(
              "No report was published",
            ),
        );
        await shot(p, "research-approved", p.locator(".workflow-theatre"));
        await p.getByRole("tab", { name: "Content Built-in" }).click();
        check(
          "workflow switch resets the example",
          (await p.locator("[data-saved] li").count()) === 1 &&
            (await p.locator("[data-stage-number]").innerText()).includes(
              "Inbox",
            ),
        );
        await p.getByRole("tab", { name: "Coding Built-in" }).focus();
        await p.keyboard.press("ArrowRight");
        check(
          "tabs support arrow-key selection",
          (await p
            .getByRole("tab", { name: "Content Built-in" })
            .getAttribute("aria-selected")) === "true",
        );
        await p.locator("[data-stations] button").first().focus();
        await p.keyboard.press("End");
        check(
          "station keys use the selected workflow length",
          (await p.locator("[data-stage-number]").innerText()).includes(
            "06 / 06",
          ),
        );
        await p.getByRole("tab", { name: "Content Built-in" }).click();
        await p.locator(".factory-viewport").scrollIntoViewIfNeeded();
        await p.locator("[data-play]").click();
        await p.waitForFunction(
          () =>
            document
              .querySelector("[data-stage-number]")
              .textContent.includes("Research"),
          {},
          { timeout: 9000 },
        );
        await p.locator("[data-play]").click();
        check(
          "explicit playback advances and pauses",
          (await p.locator("[data-play]").innerText()) === "Play example",
        );
        const beforeOffscreen = await p
          .locator("[data-stage-number]")
          .innerText();
        await p.locator("[data-play]").click();
        await p.locator("#agents").scrollIntoViewIfNeeded();
        await p.waitForTimeout(4100);
        check(
          "playback suspends while the scene is offscreen",
          (await p.locator("[data-stage-number]").innerText()) ===
            beforeOffscreen,
        );
        await p.getByRole("tab", { name: "Coding Built-in" }).click();
        check(
          "switching workflow cancels playback and resets the task",
          (await p.locator("[data-play]").innerText()) === "Play example" &&
            (await p.locator("[data-stage-number]").innerText()).includes(
              "Inbox",
            ),
        );
        await p.locator("#agents").scrollIntoViewIfNeeded();
        await shot(p, "agent-choice", p.locator("#agents"));
        check(
          "agent grid links OpenCode to its setup guide",
          (await p.locator(".fw-agent-grid li").count()) === 5 &&
            (await p.getByRole("link", { name: "OpenCode", exact: true }).getAttribute("href")) ===
              "https://github.com/ivankuznetsov/hive/blob/v0.8.0/docs/getting-started.md#optional-opencode-profile",
        );
        const links = await p
          .locator(".fw-actions a,.site-nav a,.fw-hosted a")
          .evaluateAll((as) => as.map((a) => a.getAttribute("href")));
        check(
          "framework and hosted destinations stay distinct",
          links.includes("/docs/") &&
            links.includes("https://github.com/ivankuznetsov/hive") &&
            links.includes("https://hivedev.ai/"),
        );
        const ids = await p
          .locator("[id]")
          .evaluateAll((els) => els.map((e) => e.id));
        check(
          "rendered page has no duplicate IDs",
          new Set(ids).size === ids.length,
        );
      }
      if (spec.name === "mobile-dark") {
        await p.getByRole("tab", { name: "Research Custom example" }).click();
        await p.locator("[data-stations] button").last().click();
        await shot(
          p,
          "mobile-research-decision",
          p.locator(".workflow-theatre"),
        );
        await noOverflow(p, "mobile human gate");
      }
    } finally {
      await c.close();
    }
  }
  const reduced = await context({
    viewport: { width: 390, height: 844 },
    colorScheme: "dark",
    reducedMotion: "reduce",
  });
  try {
    const p = await reduced.newPage();
    await home(p);
    check(
      "reduced motion retains manual controls and disables animation",
      !(await p.locator("[data-play]").isVisible()) &&
        (await p.locator("[data-next]").isVisible()),
    );
    await p.locator("[data-next]").click();
    check(
      "reduced-motion handoff works",
      (await p.locator("[data-stage-number]").innerText()).includes(
        "Brainstorm",
      ),
    );
  } finally {
    await reduced.close();
  }
  const nojs = await context({
    viewport: { width: 320, height: 740 },
    javaScriptEnabled: false,
    colorScheme: "light",
  });
  try {
    const p = await nojs.newPage();
    await p.goto(base, { waitUntil: "load" });
    check(
      "no-JS exposes all three workflow explanations",
      (await p.locator("[data-workflow-fallback]").isVisible()) &&
        (await p.locator("[data-workflow-fallback] details").count()) === 3,
    );
    await p
      .locator("[data-workflow-fallback] details")
      .last()
      .locator("summary")
      .click();
    check(
      "no-JS explains the human decision and local result",
      (
        await p.locator("[data-workflow-fallback] details").last().innerText()
      ).includes("Neither publishes or sends it"),
    );
    await noOverflow(p, "no-JS small screen");
  } finally {
    await nojs.close();
  }
  const smoke = await context({ viewport: { width: 1440, height: 1000 } });
  try {
    const p = await smoke.newPage();
    for (const [path, title] of [
      ["/docs/", "Hive documentation"],
      ["/docs/custom-workflows/", "Creating custom workflows"],
      ["/honeycombs/", "Reviewed workflows for Hive"],
      ["/bench/", "Which coding agents hold up end to end?"],
    ]) {
      const response = await p.goto(base + path, { waitUntil: "load" });
      check(
        `${path}: existing route renders`,
        response.ok() &&
          (await p.locator("h1").first().innerText()).includes(title),
      );
    }
    await p.goto(base + "/docs/concepts/", { waitUntil: "load" });
    await p.locator(".pagefind-ui__search-input").fill("durable");
    await p.locator(".pagefind-ui__result-link").first().waitFor();
    check(
      "Pagefind UI returns document results",
      (await p.locator(".pagefind-ui__result-link").count()) > 0,
    );
    const docs = await (
      await p.request.get(base + "/docs/getting-started.md")
    ).text();
    check(
      "raw markdown uses current release and native setup",
      docs.includes("/v0.8.0/install.sh") &&
        docs.includes("hive web status") &&
        !docs.includes("mode: tmux"),
    );
    const llms = await (await p.request.get(base + "/llms.txt")).text();
    check(
      "agent-facing introduction describes the framework",
      llms.includes("local-first workflow engine") &&
        llms.includes("coding, content, bench, and custom"),
    );
    const schema = await p.request.get(base + "/schemas/catalog-v2.json");
    check("public Honeycomb schema remains available", schema.ok());
  } finally {
    await smoke.close();
  }
  check("no browser JavaScript errors", errors.length === 0);
  check("no network mutations attempted", blocked.length === 0);
  console.log(
    JSON.stringify({ passed: checks.length, checks, errors, blocked }, null, 2),
  );
  await fs.writeFile(
    `${output}/results.json`,
    JSON.stringify({ passed: checks.length, checks, errors, blocked }, null, 2),
  );
} catch (error) {
  await fs.writeFile(
    `${output}/failure.json`,
    JSON.stringify({ error: error.message, checks, errors, blocked }, null, 2),
  );
  throw error;
} finally {
  await browser.close();
}
