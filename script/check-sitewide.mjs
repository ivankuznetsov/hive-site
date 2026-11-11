// Read-only audit of every generated HTML route. Serve _site first.
// Uses the same optional Playwright/CDP setup as check-framework.mjs.
import assert from "node:assert/strict";
import fs from "node:fs/promises";
import path from "node:path";
const { chromium } = await import(process.env.PLAYWRIGHT_MODULE || "playwright");
const base = process.env.SITE_URL || "http://127.0.0.1:8797";
const output = process.env.REVIEW_OUTPUT || "test-results/sitewide/after";
const capture = process.env.REVIEW_SCREENSHOTS !== "0";
await fs.mkdir(output, { recursive: true });
async function files(dir) {
  const found = [];
  for (const entry of await fs.readdir(dir, { withFileTypes: true })) {
    const file = path.join(dir, entry.name);
    if (entry.isDirectory()) found.push(...await files(file));
    else found.push(file);
  }
  return found;
}
const routes = (await files("_site")).filter(f => f.endsWith(".html"))
  .map(f => f.replace(/^_site/, "").replace(/index\.html$/, "")).sort();
const views = [
  ["home", "/"], ["agents", "/", "#agents"], ["docs", "/docs/"],
  ["getting-started", "/docs/getting-started/"],
  ["concepts", "/docs/concepts/", "#durability-and-recovery"],
  ["configuration", "/docs/configuration/", "#agent-profiles"],
  ["custom", "/docs/custom-workflows/", "#human-approval"],
  ["custom-permissions", "/docs/custom-workflows/", "#advanced-options"],
  ["private", "/docs/private-workflows/"], ["build-private", "/docs/build-private-workflow/"],
  ["commands", "/docs/commands/"], ["drop", "/docs/commands/drop/"],
  ["migrate", "/docs/commands/migrate/"], ["honeycombs", "/honeycombs/"],
  ["catalog", "/honeycombs/", ".honeycomb-card"], ["bench", "/bench/"],
  ["catalog-high-risk", "/honeycombs/", ".honeycomb-card:nth-child(3)"],
  ["leaderboard", "/bench/", ".bench-board"], ["methodology", "/bench/methodology/"],
  ["methodology-table", "/bench/methodology/", ".bench-config-table"],
  ["bench-run", "/bench/run/"], ["box", "/box/"],
  ["not-found", "/404.html"], ["footer", "/", ".site-footer"],
];
const result = { routes, pages: [], screenshots: [], checks: [], failures: [], errors: [], blocked: [] };
function check(name, condition) {
  (condition ? result.checks : result.failures).push(name);
}
const browser = process.env.BROWSER_CDP
  ? await chromium.connectOverCDP(process.env.BROWSER_CDP)
  : await chromium.launch({ headless: true });
async function context(options) {
  const c = await browser.newContext(options);
  await c.route("**/*", r => {
    if (!["GET", "HEAD"].includes(r.request().method())) {
      result.blocked.push(r.request().url()); return r.abort();
    }
    return r.continue();
  });
  c.on("page", p => p.on("pageerror", e => result.errors.push(e.message)));
  return c;
}
async function screenshot(p, name) {
  if (!capture) return;
  await p.screenshot({ path: `${output}/${name}.png` });
  result.screenshots.push(`${name}.png`);
}
async function documentData(p) {
  return p.evaluate(() => {
    const main = document.querySelector("[data-pagefind-body]") || document.querySelector("main");
    const ids = [...document.querySelectorAll("[id]")].map(e => e.id);
    const unnamed = [...document.querySelectorAll("button,input,select,textarea")].filter(el => {
      if (!el.getClientRects().length || el.closest("[hidden]") || el.type === "hidden") return false;
      return !(el.getAttribute("aria-label") || el.getAttribute("aria-labelledby") || el.innerText.trim() || el.labels?.length || el.title);
    }).map(el => el.outerHTML.slice(0, 150));
    return {
      title: document.title, text: main?.innerText || "",
      h1: [...(main?.querySelectorAll("h1") || [])].map(el => el.textContent.trim()),
      overflow: document.documentElement.scrollWidth - document.documentElement.clientWidth,
      ids, duplicates: ids.filter((id, i) => ids.indexOf(id) !== i), unnamed,
      missingAlt: [...document.images].filter(el => !el.hasAttribute("alt")).map(el => el.src),
      links: [...document.querySelectorAll("a[href]")].map(el => ({ href: el.getAttribute("href"), text: el.textContent.trim() })),
    };
  });
}
try {
  for (const theme of ["light", "dark"]) for (const width of [1440, 390]) {
    const c = await context({ viewport: { width, height: width === 1440 ? 1000 : 844 }, colorScheme: theme, reducedMotion: "reduce" });
    try {
      await c.addInitScript(t => { try { localStorage.setItem("hive-theme", t); } catch {} }, theme);
      const p = await c.newPage();
      for (const route of routes) {
        const response = await p.goto(base + route, { waitUntil: "load" });
        await p.evaluate(() => document.fonts.ready);
        const data = await documentData(p);
        result.pages.push({ route, theme, width, ...data });
        const name = `${route} ${width} ${theme}`;
        check(`${name}: renders one main heading`, response.ok() && data.text.length > 0 && data.h1.length === 1);
        check(`${name}: no page overflow`, data.overflow <= 1);
        check(`${name}: unique IDs and named controls/images`, !data.duplicates.length && !data.unnamed.length && !data.missingAlt.length);
        check(`${name}: no exposed fences or orphaned HTML`, !/```|<\/(?:div|section)>/.test(data.text));
        for (const [name, , selector] of views.filter(v => v[1] === route)) {
          if (selector) {
            await p.locator(selector).first().evaluate(el => el.scrollIntoView({ block: "start" }));
            await p.evaluate(() => scrollBy(0, -80));
          } else await p.evaluate(() => scrollTo(0, 0));
          await screenshot(p, `${name}-${width}-${theme}`);
        }
      }
      await p.goto(base + "/docs/", { waitUntil: "load" });
      if (width === 390) {
        await p.locator("#menu-button").click();
        check(`${theme}: mobile docs navigation opens`, await p.locator(".site-nav").isVisible());
        await screenshot(p, `docs-menu-${width}-${theme}`);
      }
      await p.locator(".pagefind-ui__search-input").fill("workflow");
      await p.locator(".pagefind-ui__result-link").first().waitFor();
      check(`${width} ${theme}: Pagefind returns linked documents`, (await p.locator(".pagefind-ui__result-link").count()) > 0);
      await screenshot(p, `search-${width}-${theme}`);
      await p.locator(".pagefind-ui__search-input").fill("");
      const sheetBefore = await p.locator('link[rel="stylesheet"][href*="just-the-docs-"]:not([id])').getAttribute("href");
      await p.locator("#theme-toggle").click();
      const sheetAfter = await p.locator('link[rel="stylesheet"][href*="just-the-docs-"]:not([id])').getAttribute("href");
      check(`${width} ${theme}: theme control changes stylesheet and stored preference`, sheetBefore !== sheetAfter && await p.evaluate(() => localStorage.getItem("hive-theme")) === (theme === "dark" ? "light" : "dark"));
    } finally { await c.close(); }
  }
  // Resolve all authored local links and fragments once, including downloadable evidence.
  const unique = result.pages.filter(p => p.theme === "light" && p.width === 1440);
  const byRoute = new Map(unique.map(p => [p.route, p]));
  const linkIssues = [];
  const targets = new Set();
  for (const page of unique) for (const link of page.links) {
    const url = new URL(link.href, base + page.route);
    if (![new URL(base).origin, "https://hivecli.sh"].includes(url.origin)) continue;
    if (link.href === "#") continue;
    targets.add(url.pathname + url.hash);
    const file = `_site${decodeURIComponent(url.pathname)}${url.pathname.endsWith("/") ? "index.html" : ""}`;
    try { await fs.access(file); } catch { linkIssues.push(`${page.route} → ${url.pathname}`); continue; }
    const target = byRoute.get(url.pathname);
    if (url.hash && target && !target.ids.includes(decodeURIComponent(url.hash.slice(1)))) linkIssues.push(`${page.route} → ${url.pathname}${url.hash}`);
  }
  result.linkTargets = targets.size;
  result.linkIssues = [...new Set(linkIssues)];
  check(`all ${targets.size} internal link targets/files/fragments resolve`, !result.linkIssues.length);
  // Raw Markdown must resolve the same source and current version; no stale parallel copy.
  const version = (await fs.readFile("_config.yml", "utf8")).match(/hive_version: "([^"]+)"/)[1];
  const corpus = await fs.readFile("_site/llms-full.txt", "utf8");
  const index = await fs.readFile("_site/llms.txt", "utf8");
  for (const file of (await files("docs")).filter(f => f.endsWith(".md"))) {
    const source = await fs.readFile(file, "utf8");
    const route = source.match(/^permalink: (.+)$/m)[1].trim();
    const expected = source.replace(/^---\s*\n[\s\S]*?\n---\s*\n/, "")
      .replace(/\{\{\s*'([^']+)'\s*\|\s*relative_url\s*\}\}/g, (_, p) => `https://hivecli.sh${p}`)
      .replace(/\{\{\s*site\.hive_version\s*\}\}/g, version)
      .replace(/^\{:\s*(?:\.no_toc|#[\w-]+)\s*\}\s*$/gm, "").replace(/^1\.\s*TOC\s*$/gm, "").replace(/^\{:toc\}\s*$/gm, "").trim();
    const rawPath = `${route.replace(/\/$/, "")}.md`;
    const raw = (await fs.readFile(`_site${rawPath}`, "utf8")).trim();
    check(`${route}: raw Markdown matches authored source`, raw === expected);
    if (!file.endsWith("/index.md")) check(`${route}: LLM corpus and index include current content`, corpus.includes(raw) && index.includes(`https://hivecli.sh${rawPath}`));
  }
  const c = await context({ viewport: { width: 390, height: 844 }, colorScheme: "light" });
  try {
    await c.grantPermissions(["clipboard-read", "clipboard-write"]);
    const p = await c.newPage();
    await p.goto(base + "/honeycombs/");
    const entries = JSON.parse(await fs.readFile("_data/honeycombs.json", "utf8")).entries.filter(e => e.discoverable);
    check("all catalog releases retain install commands and permissions", await p.locator(".honeycomb-card").count() === entries.length && await p.locator(".honeycomb-permissions").count() === entries.length);
    await p.locator("[data-honeycomb-copy]").first().click();
    check("catalog copy copies the visible command", await p.evaluate(() => navigator.clipboard.readText()) === entries[0].install_command);
    await p.goto(base + "/bench/");
    const rows = p.locator(".bench-summary-table tbody tr");
    check("benchmark retains all 15 candidates and 90 quality/efficiency cells", await rows.count() === 15 && await p.locator(".bench-score-matrix tbody td").count() === 90 && await p.locator(".bench-efficiency-matrix tbody td").count() === 90);
    await p.locator("[data-bench-sort-select]").selectOption("cost");
    await p.locator("[data-bench-sort-direction]").click();
    const costs = await rows.evaluateAll(rs => rs.map(r => r.dataset.sortCost));
    const known = costs.filter(Boolean).map(Number);
    check("mobile cost sort is ascending with missing values last", known.every((v, i) => !i || v >= known[i - 1]) && costs.slice(known.length).every(v => v === ""));
    await p.locator(".bench-info:visible").first().focus();
    check("benchmark tooltip opens from the keyboard", await p.locator("#bench-tooltip").isVisible());
    await p.keyboard.press("Escape");
    check("benchmark tooltip closes on Escape", !(await p.locator("#bench-tooltip").isVisible()));
    await p.goto(base + "/docs/");
    await p.locator(".llm-copy").click();
    await p.getByRole("button", { name: "Copied", exact: true }).waitFor();
    check("docs copy returns current Markdown", await p.evaluate(() => navigator.clipboard.readText()) === await fs.readFile("_site/docs.md", "utf8"));
    await p.goto(base + "/box/");
    check("archive video has user controls, no autoplay or loop", await p.locator("video").evaluate(v => v.controls && !v.autoplay && !v.loop));
  } finally { await c.close(); }
  const nojs = await context({ viewport: { width: 320, height: 740 }, javaScriptEnabled: false });
  try {
    const p = await nojs.newPage();
    for (const route of ["/honeycombs/", "/bench/", "/box/", "/docs/custom-workflows/"]) {
      await p.goto(base + route);
      check(`${route}: no-JS narrow viewport retains main content without overflow`, await p.locator("main").innerText().then(t => t.length > 100) && await p.evaluate(() => document.documentElement.scrollWidth <= innerWidth + 1));
    }
  } finally { await nojs.close(); }
  check("no browser errors or attempted network mutations", !result.errors.length && !result.blocked.length);
} catch (error) {
  result.failures.push(error.stack);
} finally {
  await browser.close();
  await fs.writeFile(`${output}/audit.json`, JSON.stringify(result, null, 2));
  await fs.writeFile(`${output}/rendered-content.txt`, result.pages.filter(p => p.width === 1440 && p.theme === "light").map(p => `\n\n===== ${p.route} =====\n${p.text}`).join(""));
  console.log(JSON.stringify({ routes: routes.length, viewportChecks: result.pages.length, screenshots: result.screenshots.length, passed: result.checks.length, failures: result.failures, linkIssues: result.linkIssues, errors: result.errors, blocked: result.blocked }, null, 2));
}
assert.equal(result.failures.length, 0, "sitewide checks failed; see audit.json");
