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
async function shot(p, name, locator) {
  const path = `${output}/${name}.png`;
  if (!locator) return p.screenshot({ path });
  // Full-width captures avoid cutting off mobile labels when Chromium's
  // screenshot mode omits the scrollbar gutter after locator clip sizing.
  if (p.viewportSize().width < 600) {
    await locator.scrollIntoViewIfNeeded();
    const box = await locator.evaluate((el) => {
      const r = el.getBoundingClientRect();
      return { y: r.y + scrollY, height: r.height };
    });
    const cdp = await p.context().newCDPSession(p);
    try {
      const capture = await cdp.send("Page.captureScreenshot", {
        format: "png",
        captureBeyondViewport: true,
        clip: { x: 0, width: p.viewportSize().width, ...box, scale: 1 },
      });
      return await fs.writeFile(path, Buffer.from(capture.data, "base64"));
    } finally {
      await cdp.detach();
    }
  }
  return locator.screenshot({ path });
}
try {
  for (const spec of [
    { name: "desktop-light", width: 1440, height: 1000, colorScheme: "light" },
    { name: "desktop-dark", width: 1440, height: 1000, colorScheme: "dark" },
    { name: "tablet-light", width: 768, height: 1024, colorScheme: "light" },
    { name: "mobile-dark", width: 390, height: 844, colorScheme: "dark" },
    { name: "mobile-light", width: 390, height: 844, colorScheme: "light" },
    { name: "small-light", width: 320, height: 740, colorScheme: "light" },
    { name: "small-dark", width: 320, height: 740, colorScheme: "dark" },
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
        await p.getByRole("tab", { name: "Writing Honeycomb" }).click();
        check("writing has seven published stages and an install command",
          await p.locator("[data-stations] button").count() === 7 &&
          await p.locator("[data-install-command]").innerText() === "hive workflow install honeycomb/writing");
        check("writing source is versioned and its council loop is visible",
          (await p.locator("[data-package-source]").getAttribute("href")).endsWith("/packages/writing/1.0.2") &&
          await p.locator("[data-return]").isVisible());
        await shot(p, "writing-overview", p.locator("#workflow-panel"));
        await p.locator("[data-stations] button").nth(4).click();
        const draftInputs = await p.locator("[data-saved]").innerText();
        check("all completed writing inputs are saved before drafting",
          ["brief.md", "repo-research.md", "web-research.md", "research.md"].every(f => draftInputs.includes(f)) &&
          !draftInputs.includes("draft.md") && !draftInputs.includes("outline.md"));
        await p.locator("[data-interrupt]").click();
        check("interruption stops advancement without losing research",
          await p.locator("[data-next]").isDisabled() &&
          await p.locator("[data-saved]").innerText() === draftInputs);
        await shot(p, "writing-interrupted", p.locator(".workflow-theatre"));
        await p.locator("[data-retry]").click();
        check("retry begins a second attempt at the same draft",
          (await p.locator("[data-stage-number]").innerText()).includes("Draft") &&
          await p.locator("[data-state-label]").innerText() === "Attempt 2");
        await p.locator("[data-next]").click();
        check("retry hands the saved draft to the editorial council",
          (await p.locator("[data-stage-number]").innerText()).includes("Editorial") &&
          (await p.locator("[data-saved]").innerText()).includes("draft.md"));
        await p.locator("[data-next]").click();
        check("editorial revision stays inside the same council stage",
          (await p.locator("[data-stage-number]").innerText()).includes("06 / 07 · Editorial") &&
          await p.locator("[data-state-label]").innerText() === "Council revision" &&
          await p.locator("[data-file]").innerText() === "draft.md" &&
          (await p.locator("[data-saved]").innerText()).includes("reviews/grounding-editor-01.md"));
        await shot(p, "writing-editorial-revision", p.locator(".workflow-theatre"));
        await p.locator("[data-next]").click();
        check("both editors recheck in round two",
          await p.locator("[data-state-label]").innerText() === "Review round 2");
        await p.locator("[data-next]").click();
        const deliveredInputs = await p.locator("[data-saved]").innerText();
        check("delivery retains the council audit trail",
          ["reviews/grounding-editor-01.md", "reviews/adversarial-editor-02.md", "editorial.md"].every(f => deliveredInputs.includes(f)));
        await p.locator("[data-next]").click();
        check("writing completes with article and verification, without promising publication",
          (await p.locator("[data-saved]").innerText()).includes("verification.md") &&
          (await p.locator("[data-saved]").innerText()).includes("article.md") &&
          (await p.locator("[data-sample]").innerText()).includes("NOT PUBLISHABLE"));
        await p.getByRole("tab", { name: "Architecture Honeycomb" }).click();
        check("architecture is the current eight-stage Honeycomb, not a fictional research package",
          await p.locator("[data-stations] button").count() === 8 &&
          (await p.locator("[data-package-source]").getAttribute("href")).endsWith("/packages/architecture/1.0.4"));
        await p.locator("[data-stations] button").nth(3).click();
        check("architecture synthesis keeps the raw evidence files separate",
          (await p.locator("[data-saved]").innerText()).includes("repo-research.txt") &&
          (await p.locator("[data-saved]").innerText()).includes("web-research.txt") &&
          (await p.locator("[data-sample]").innerText()).includes("Untested"));
        await shot(p, "architecture-evidence", p.locator(".workflow-theatre"));
        await p.locator("[data-stations] button").nth(5).click();
        await p.locator("[data-next]").click();
        await shot(p, "architecture-council-revision", p.locator(".workflow-theatre"));
        check("architecture revises within Review with both reviewer reports saved",
          (await p.locator("[data-stage-number]").innerText()).includes("06 / 08 · Review") &&
          (await p.locator("[data-saved]").innerText()).includes("reviews/constraints-01.md") &&
          (await p.locator("[data-saved]").innerText()).includes("reviews/operations-01.md"));
        await p.locator("[data-next]").click();
        check("the bounded architecture council does not promise consensus",
          (await p.locator("[data-stage-body]").innerText()).includes("without consensus"));
        await p.locator("[data-next]").click();
        await p.locator("[data-next]").click();
        check("Done is inert and retains architecture.md",
          (await p.locator("[data-stage-body]").innerText()).includes("no additional agent runs") &&
          (await p.locator("[data-saved]").innerText()).includes("architecture.md"));
        await p.locator("[data-next]").click();
        await shot(p, "architecture-complete", p.locator(".workflow-theatre"));
        check("replay is explicit after completion", await p.locator("[data-play]").innerText() === "Replay example");
        await p.locator(".factory-viewport").scrollIntoViewIfNeeded();
        await p.locator("[data-play]").click();
        await p.locator("[data-play]").click();
        check("replay resets the narrative and saved artifacts",
          await p.locator("[data-saved] li").count() === 1 &&
          (await p.locator("[data-stage-number]").innerText()).includes("Inbox"));
        const gate = p.locator("[data-gate-example]");
        check("human decisions are separate from installed packages and match the custom YAML",
          await gate.isVisible() && await gate.getAttribute("data-state") === "waiting" &&
          (await p.locator("#define").innerText()).includes("separate from the Writing and Architecture Honeycombs"));
        await shot(p, "custom-gate-waiting", p.locator("#define"));
        await p.locator("[data-gate-reject]").click();
        check("custom rejection preserves report and evidence and returns to synthesis",
          (await p.locator("[data-gate-title]").innerText()).includes("synthesis") &&
          (await p.locator("[data-gate-files]").innerText()).includes("research.md") &&
          (await p.locator("[data-gate-files]").innerText()).includes("approval.md") &&
          !await p.locator("[data-gate-approve]").isVisible());
        await p.locator("[data-gate-revise]").click();
        await p.locator("[data-gate-approve]").focus();
        await p.keyboard.press("Enter");
        check("keyboard approval records both decisions without external action",
          (await p.locator("[data-gate-history]").innerText()).includes("revision requested → approved") &&
          (await p.locator("[data-gate-detail]").innerText()).includes("Nothing was published or sent"));
        await p.locator("[data-gate-reset]").click();
        check("custom gate reset does not affect the package example",
          await gate.getAttribute("data-state") === "waiting" &&
          await p.locator("[data-workflow-app]").getAttribute("data-workflow") === "architecture");
        await p.getByRole("tab", { name: "Writing Honeycomb" }).click();
        check("workflow switch resets the package example",
          await p.locator("[data-saved] li").count() === 1 &&
          (await p.locator("[data-stage-number]").innerText()).includes("Inbox"));
        await p.getByRole("tab", { name: "Coding Built-in" }).focus();
        await p.keyboard.press("ArrowRight");
        check(
          "tabs support arrow-key selection",
          (await p
            .getByRole("tab", { name: "Writing Honeycomb" })
            .getAttribute("aria-selected")) === "true",
        );
        await p.locator("[data-stations] button").first().focus();
        await p.keyboard.press("End");
        check(
          "station keys use the selected workflow length",
          (await p.locator("[data-stage-number]").innerText()).includes(
            "07 / 07",
          ),
        );
        await p.getByRole("tab", { name: "Writing Honeycomb" }).click();
        await p.locator(".factory-viewport").scrollIntoViewIfNeeded();
        const dockTransform = await p.locator("[data-packet]").getAttribute("transform");
        const dockY = Number(dockTransform.match(/translate\([^ ]+ ([^)]+)/)[1]);
        await p.locator("[data-play]").click();
        await p.waitForFunction((startY) => {
          const packet = document.querySelector("[data-packet]");
          const y = Number(packet.getAttribute("transform").match(/translate\([^ ]+ ([^)]+)/)[1]);
          return packet.dataset.moving === "true" && y < startY - 100;
        }, dockY, { timeout: 6000 });
        await p.locator("[data-play]").click();
        const heldPacket = await p.locator("[data-packet]").getAttribute("transform");
        await shot(p, "writing-handoff-paused", p.locator(".factory-viewport"));
        check("pause freezes the lifted carrier between stages",
          heldPacket === await p.locator("[data-packet]").getAttribute("transform") &&
          await p.locator("[data-packet]").getAttribute("data-moving") === "true");
        await p.locator("[data-play]").click();
        await p.waitForFunction(
          () =>
            document
              .querySelector("[data-stage-number]")
              .textContent.includes("Repo research"),
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
      for (const [id, stageIndex] of [["writing", 5], ["architecture", 3]]) {
        await p.locator(`[data-workflow="${id}"][role="tab"]`).click();
        await p.locator("[data-stations] button").nth(stageIndex).click();
        if (id === "writing") await p.locator("[data-next]").click();
        await noOverflow(p, `${spec.name} ${id} selected`);
        await shot(p, `${spec.name}-${id}`, p.locator("[data-workflow-app]"));
        const stationLayout = await p.locator("[data-stations]").evaluate(el => ({
          width: el.clientWidth, scroll: el.scrollWidth,
          columns: getComputedStyle(el).gridTemplateColumns.split(" ").length,
        }));
        check(`${spec.name} ${id}: station labels fit the responsive grid`,
          stationLayout.scroll <= stationLayout.width + 1 &&
          stationLayout.columns === (spec.width <= 600 ? 3 : spec.width <= 850 ? 5 : id === "writing" ? 7 : 8));
      }
      if (spec.width < 600) {
        await shot(p, `${spec.name}-custom-gate`, p.locator("#define"));
        await noOverflow(p, `${spec.name} custom gate`);
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
      "no-JS exposes the real Architecture stages, installation, and unresolved findings",
      (await p.locator("[data-workflow-fallback] details").last().locator("ol > li").count()) === 8 &&
      (await p.locator("[data-workflow-fallback] details").last().innerText()).includes("hive workflow install honeycomb/architecture") &&
      (await p.locator("[data-workflow-fallback] details").last().innerText()).includes("Completion does not mean every finding is resolved or the design is approved"),
    );
    check("no-JS custom YAML explains the gate without dead interactive controls",
      (await p.locator("#define").innerText()).includes("rejection returns the task to synthesis") &&
      !(await p.locator("[data-gate-example]").isVisible()));
    await shot(p, "nojs-architecture", p.locator("[data-workflow-fallback] details").last());
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
