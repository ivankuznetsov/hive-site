const { chromium } = require("playwright");
const fs = require("fs");
const path = require("path");

const base = process.env.HIVE_SITE_URL || "http://127.0.0.1:4173";
const evidenceDir = __dirname;
const log = [];

const captures = [
  ["homepage-how-it-works-desktop-1440x900.png", "/", { width: 1440, height: 900 }, false],
  ["homepage-how-it-works-mobile-390x844.png", "/", { width: 390, height: 844 }, false],
  ["concepts-full-desktop-1440x900.png", "/docs/concepts/", { width: 1440, height: 900 }, true],
  ["concepts-full-mobile-390x844.png", "/docs/concepts/", { width: 390, height: 844 }, true],
  ["custom-workflows-full-desktop-1440x900.png", "/docs/custom-workflows/", { width: 1440, height: 900 }, true],
  ["custom-workflows-full-mobile-390x844.png", "/docs/custom-workflows/", { width: 390, height: 844 }, true],
];

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function pass(message) {
  const line = `PASS ${message}`;
  log.push(line);
  console.log(line);
}

async function assertFocusVisible(locator, label) {
  await locator.focus();
  const focus = await locator.evaluate((node) => {
    const style = getComputedStyle(node);
    return {
      outlineStyle: style.outlineStyle,
      outlineWidth: parseFloat(style.outlineWidth),
      boxShadow: style.boxShadow,
    };
  });
  assert(
    (focus.outlineStyle !== "none" && focus.outlineWidth > 0) || focus.boxShadow !== "none",
    `${label} lacks a visible focus indicator`,
  );
}

async function assertTarget(locator, minimum, label) {
  const box = await locator.boundingBox();
  assert(box && box.width >= minimum && box.height >= minimum,
    `${label} target is ${box ? `${box.width}x${box.height}` : "not visible"}`);
}

async function assertNoOverlap(locators, label) {
  const boxes = [];
  for (let index = 0; index < await locators.count(); index += 1) {
    const box = await locators.nth(index).boundingBox();
    assert(box && box.width > 0 && box.height > 0, `${label} ${index + 1} is hidden or empty`);
    boxes.push(box);
  }
  for (let left = 0; left < boxes.length; left += 1) {
    for (let right = left + 1; right < boxes.length; right += 1) {
      const xOverlap = Math.min(boxes[left].x + boxes[left].width, boxes[right].x + boxes[right].width)
        - Math.max(boxes[left].x, boxes[right].x);
      const yOverlap = Math.min(boxes[left].y + boxes[left].height, boxes[right].y + boxes[right].height)
        - Math.max(boxes[left].y, boxes[right].y);
      assert(xOverlap <= 1 || yOverlap <= 1, `${label} ${left + 1} overlaps ${right + 1}`);
    }
  }
}

async function inspectPage(page, route, viewport) {
  const label = `${route} ${viewport.width}x${viewport.height}`;
  await page.setViewportSize(viewport);
  const response = await page.goto(base + route, { waitUntil: "networkidle" });
  assert(response && response.ok(), `${route} did not return 2xx`);
  assert(await page.locator("h1").count() === 1, `${route} must contain exactly one H1`);

  const headingLevels = await page.locator("h1, h2, h3, h4, h5, h6").evaluateAll((nodes) =>
    nodes.filter((node) => {
      const style = getComputedStyle(node);
      return style.display !== "none" && style.visibility !== "hidden";
    }).map((node) => Number(node.tagName.slice(1))),
  );
  for (let index = 1; index < headingLevels.length; index += 1) {
    assert(headingLevels[index] <= headingLevels[index - 1] + 1,
      `${route} heading hierarchy jumps from H${headingLevels[index - 1]} to H${headingLevels[index]}`);
  }

  const geometry = await page.evaluate(() => ({
    clientWidth: document.documentElement.clientWidth,
    scrollWidth: document.documentElement.scrollWidth,
  }));
  assert(geometry.scrollWidth <= geometry.clientWidth + 1,
    `${label} page overflows horizontally: ${geometry.scrollWidth} > ${geometry.clientWidth}`);

  const mainText = route === "/"
    ? page.locator(".workflow-explainer p, .workflow-explainer li").first()
    : page.locator("main p, main li").first();
  const fontSize = await mainText.evaluate((node) => parseFloat(getComputedStyle(node).fontSize));
  assert(fontSize >= 14, `${label} body text is too small: ${fontSize}px`);

  if (route === "/") {
    const section = page.locator("#how-it-works");
    await section.scrollIntoViewIfNeeded();
    assert(await section.count() === 1, "homepage must preserve #how-it-works");
    assert(await section.locator("ol > li").count() === 4, "workflow sequence must remain a four-step ordered list");
    await assertNoOverlap(section.locator(".workflow-explainer__steps > li"), `${label} workflow step`);

    const snapshot = await section.ariaSnapshot();
    assert(snapshot.includes('heading "A workflow turns one brief into a durable outcome" [level=2]'),
      "homepage accessibility tree loses the section heading");
    assert(snapshot.includes("- list:") && snapshot.match(/- listitem:/g)?.length >= 4,
      "homepage accessibility tree loses the ordered steps");
    assert(snapshot.includes('link "Learn how Hive workflows work"'),
      "homepage Concepts CTA lacks its accessible name and role");
    assert(!snapshot.match(/connector|decorative|→/i),
      "decorative connector leaked into the homepage accessibility tree");

    const cta = section.getByRole("link", { name: "Learn how Hive workflows work" });
    assert((await cta.getAttribute("href")) === "/docs/concepts/", "homepage Concepts link must resolve canonically");
    await assertTarget(cta, 44, `${label} Concepts CTA`);
    await assertFocusVisible(cta, `${label} Concepts CTA`);

    if (viewport.width === 390) {
      const columns = await section.locator(".workflow-explainer__steps").evaluate((node) =>
        getComputedStyle(node).gridTemplateColumns.split(" ").length,
      );
      assert(columns === 1, `mobile workflow sequence uses ${columns} columns instead of one`);
    }
    pass(`${label} accessibility tree, focus, targets, reading order, and non-overlap`);
    return;
  }

  const mainSnapshot = await page.locator("main").ariaSnapshot();
  assert(mainSnapshot.includes('- link "View as markdown"'), `${label} Markdown link lacks its accessible name and role`);
  assert(mainSnapshot.includes('- button "Copy for LLM"'), `${label} LLM copy control lacks its accessible name and role`);
  assert(mainSnapshot.includes('- button "Copy code to clipboard"'), `${label} code-copy controls lack accessible names and roles`);

  const llmButtons = page.locator(".llm-actions .llm-btn");
  assert(await llmButtons.count() === 2, `${route} must expose both raw-Markdown controls`);
  for (let index = 0; index < await llmButtons.count(); index += 1) {
    await assertTarget(llmButtons.nth(index), 44, `${label} raw-Markdown control ${index + 1}`);
    await assertFocusVisible(llmButtons.nth(index), `${label} raw-Markdown control ${index + 1}`);
  }

  const codeCopy = page.getByRole("button", { name: "Copy code to clipboard" }).first();
  await assertTarget(codeCopy, 24, `${label} code-copy control`);
  await assertFocusVisible(codeCopy, `${label} code-copy control`);

  const docsNavigation = page.locator("nav.site-nav a[href]").first();
  if (await docsNavigation.isVisible()) {
    await assertTarget(docsNavigation, 24, `${label} docs navigation link`);
    await assertFocusVisible(docsNavigation, `${label} docs navigation link`);
  } else {
    const menu = page.getByRole("button", { name: "Menu" });
    await assertTarget(menu, 24, `${label} docs menu control`);
    await assertFocusVisible(menu, `${label} docs menu control`);
  }

  const inPageLink = page.locator('main a[href^="#"]').first();
  assert(await inPageLink.count() === 1, `${label} needs an in-page heading link`);
  await assertFocusVisible(inPageLink, `${label} in-page link`);

  const codeBlocks = await page.locator("main pre").evaluateAll((nodes) => nodes.map((node) => {
    const box = node.getBoundingClientRect();
    return {
      left: box.left,
      right: box.right,
      clientWidth: node.clientWidth,
      scrollWidth: node.scrollWidth,
      overflowX: getComputedStyle(node).overflowX,
    };
  }));
  assert(codeBlocks.every((block) => block.left >= -1 && block.right <= viewport.width + 1),
    `${label} code block escapes the viewport`);
  if (route === "/docs/custom-workflows/" && viewport.width === 390) {
    assert(codeBlocks.some((block) => block.scrollWidth > block.clientWidth && ["auto", "scroll"].includes(block.overflowX)),
      "long mobile code blocks must scroll inside their containers");
  }

  pass(`${label} accessibility names/roles, focus, targets, code containment, and page overflow`);
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ colorScheme: "dark" });
  const page = await context.newPage();
  const runtimeErrors = [];
  page.on("pageerror", (error) => runtimeErrors.push(`pageerror: ${error.message}`));
  page.on("requestfailed", (request) => {
    const errorText = request.failure()?.errorText || "";
    if (request.resourceType() === "media" && errorText.includes("ERR_ABORTED")) return;
    runtimeErrors.push(`requestfailed: ${request.url()} ${errorText}`);
  });

  for (const [filename, route, viewport, fullPage] of captures) {
    await inspectPage(page, route, viewport);
    const target = path.join(evidenceDir, filename);
    if (fullPage) {
      await page.screenshot({ path: target, fullPage: true });
    } else {
      await page.locator(".site-header").evaluate((node) => { node.style.visibility = "hidden"; });
      await page.locator("#how-it-works").screenshot({ path: target });
      await page.locator(".site-header").evaluate((node) => { node.style.visibility = ""; });
    }
    pass(`capture ${filename}`);
  }

  await inspectPage(page, "/", { width: 1440, height: 900 });
  await page.evaluate(() => {
    for (const sheet of document.styleSheets) {
      try { sheet.disabled = true; } catch (_) {}
    }
  });
  assert(await page.locator("#how-it-works ol > li").count() === 4,
    "workflow sequence loses meaning with CSS disabled");
  assert(await page.locator("#how-it-works").getByText("A workflow turns one brief into a durable outcome", { exact: true }).count() === 1,
    "workflow definition disappears with CSS disabled");
  pass("homepage semantic reading order with CSS disabled");

  for (const route of ["/", "/docs/concepts/", "/docs/custom-workflows/"]) {
    await inspectPage(page, route, { width: 720, height: 450 });
    pass(`200% reflow equivalent ${route} at 720x450 CSS pixels`);
  }

  await page.goto(base + "/", { waitUntil: "networkidle" });
  await Promise.all([
    page.waitForURL("**/docs/concepts/"),
    page.getByRole("link", { name: "Learn how Hive workflows work" }).click(),
  ]);
  await Promise.all([
    page.waitForURL("**/docs/custom-workflows/"),
    page.locator('main a[href="/docs/custom-workflows/"]').first().click(),
  ]);
  pass("homepage to Concepts to Custom workflows navigation");

  assert(runtimeErrors.length === 0, runtimeErrors.join("\n"));
  const pngs = fs.readdirSync(evidenceDir).filter((name) => name.endsWith(".png")).sort();
  assert(pngs.length === 6, `expected exactly six PNG captures, found ${pngs.length}: ${pngs.join(", ")}`);
  for (const [filename] of captures) assert(pngs.includes(filename), `missing capture ${filename}`);
  pass("exactly six named captures");
  pass("browser acceptance complete");
  fs.writeFileSync(path.join(evidenceDir, "browser-acceptance.txt"), `${log.join("\n")}\n`);
  await browser.close();
})().catch((error) => {
  const line = `FAIL ${error.stack || error}`;
  fs.writeFileSync(path.join(evidenceDir, "browser-acceptance.txt"), `${log.concat(line).join("\n")}\n`);
  console.error(line);
  process.exitCode = 1;
});
