# Durable workflows homepage — implementation review

Date: 2026-11-04. Branch: `feat/durable-workflows-20261104`.
Base: canonical `origin/main` at `57426b403c63b1ce08a51fdd90c9bf6edfcd026b`.
Work was isolated from the primary site checkout and the framework checkout.
No push, PR, deployment, signup, or external notification was performed.

## What changed

- **Framework-first positioning:** “Durable workflows for AI agents.” Hive is
  the open-source, local-first engine; HiveDev is the separate hosted product,
  accurately labeled coming soon / waitlist. Install, Docs, and GitHub lead.
- **Shared visual family:** warm light/dark surfaces, honey accents, self-hosted
  Space Grotesk with its OFL, a shorter first fold, restrained section hierarchy,
  and original HiveDev isometric SVG machinery, artifacts, and carrier bee.
  Provenance is in [ASSET-SOURCES.md](ASSET-SOURCES.md).
- **Generalized existing animation:** one native renderer, no library/runtime
  addition. Coding uses nine stages and a finding → fix → recheck loop. Content
  has six different stages, document artifacts, and an article result. Research
  is explicitly a three-stage **custom example**, not a built-in or recorded run.
- **Durability made inspectable:** saved inputs remain through an interrupted
  Content draft and a second attempt. The Research gate actually waits for a
  demo decision; rejection returns the same task to synthesis, approval records
  the result. Neither control publishes or sends anything.
- **User control:** no autoplay or automatic workflow cycling; finite playback,
  Next, stage inspection, overview, pause, and replay. Playback suspends offscreen
  and on document visibility changes. Workflow selection resets the example.
  Keyboard tabs/stations, announcements, reduced-motion manual controls, and
  server-rendered no-JavaScript explanations remain available.
- **Agent choice:** the user-supplied Tessl composition becomes “Your workflow.
  Your agents.” with a compact supported-CLI grid. Claude Code, Codex, Grok, Pi,
  and opt-in OpenCode are named; model choice is not conflated with harness
  choice. OpenCode's explicit route and scoped-setup requirements are linked.
- **Intake feedback:** the reused stepped pedestal/upright request was changed
  to a shallow document tray with a flat isometric request. Its dock is on the
  tray surface, so the same packet lifts into the handoff. The stray accent
  marks and monumental plinth are removed; other machinery is unchanged.
- **Evidence:** the existing historical Screenote PR #36 finding/fix/recheck is
  linked and labeled, including the missing-libvips validation limitation. No
  noncoding recording or new runtime reliability evidence is invented.
- **Responsive access:** Docs stays visible, a native mobile menu exposes the
  other destinations, and long install commands no longer widen the page.

## Released-capability and documentation corrections

The latest public stable release was verified as **v0.8.0 (2026-10-27)**.
Capability checks used the release tag, not the dirty local framework checkout:

- [Release](https://github.com/ivankuznetsov/hive/releases/tag/v0.8.0)
- [Native install / optional OpenCode](https://github.com/ivankuznetsov/hive/blob/v0.8.0/docs/getting-started.md)
- [Workflow and human-stage contract](https://github.com/ivankuznetsov/hive/blob/v0.8.0/docs/workflows.md)
- [Native web experience](https://github.com/ivankuznetsov/hive/blob/v0.8.0/README.md#hive-web-default-native-experience)

Site config/install/docs now agree on v0.8.0. The public introduction, metadata,
OG artwork, generated `llms.txt`, and raw Markdown describe the generic engine
and native web/TUI/CLI surfaces. The docs acknowledge the machine-local SQLite
runtime control plane rather than claiming “no database”; describe guarded
recovery rather than process replay; list coding/content/bench plus custom
workflows; remove obsolete tmux launch-mode promotion; and explain opt-in Claude
budgets. Native `hive setup`, `hive init`, and `hive web status` lead the quickstart.

The discontinued Box URL and installers are retained, with an explicit archive
notice and migration route. Existing changelog history remains below the new
0.8.0 entry. Honeycombs catalog/schema/sync, Bench pages, docs/sidebar/Pagefind,
community links, security headers, and lockfiles are preserved. No framework
migration, paid service, or new production dependency was introduced.

## Verification

Dependencies were installed with `SHARP_IGNORE_GLOBAL_LIBVIPS=1 npm ci` to use
Sharp's packaged binary on this host, and `ruby script/bundle install`. The
existing lockfiles were retained. This host needs its existing Ruby gem bin
folder on `PATH` for Jekyll.

Final normal build:

```bash
PATH=/home/asterio/.local/share/gem/ruby/3.4.0/bin:$PATH npm run build
```

- **6 JavaScript tests passed:** distinct built-ins/results, finite coding
  recheck, saved-state continuity/retry, explicit human gate, revision history,
  surface-to-surface carrier handoffs.
- **25 Ruby tests / 2,631 assertions passed**, no failures, errors, or skips.
- Jekyll and Pagefind completed; 28 documents indexed and raw/LLM exports built.
- Existing Just the Docs Sass deprecation warnings and Pagefind's legacy-UI
  migration notice remain nonfatal; unrelated toolchain migration was not done.

Optional browser command (the absolute module path points to an existing local
Playwright install; it is not a production dependency):

```bash
PLAYWRIGHT_MODULE=/home/asterio/Dev/hivedevai-site.worktrees/factory-polish-20261104/node_modules/playwright/index.mjs \
BROWSER_CDP=http://127.0.0.1:18800 \
NO_PROXY=127.0.0.1,localhost no_proxy=127.0.0.1,localhost \
npm run test:browser
```

**54 browser assertions passed**, including:

- Desktop 1440 light/dark, tablet 768, mobile 390 dark, narrow mobile 320 light.
- No horizontal page overflow, including expanded Linux install commands.
- Different stage counts/artifacts, coding-only return route, review recheck,
  interruption/retry continuity, human approve/revise loop, keyboard controls,
  tab reset, explicit playback, and offscreen suspension.
- Reduced motion and no JavaScript; mobile Docs/menu and primary/hosted links.
- Existing Docs, Pagefind UI search, Honeycombs, Bench, public schema, raw
  Markdown, and LLM introduction smoke checks.
- No browser JavaScript errors or network mutation attempts. Checks used owned
  browser contexts and blocked all non-GET/HEAD requests.

`git diff --check` passed. Browser tests and screenshots are development-only;
`implementation/` and `test-results/` are excluded from the published site.

## Rendered evidence

Screenshots/logs are deliberately ignored, not committed. Under `test-results/`:

- `before-hive-desktop.png`, `before-hive-mobile.png`: original public site.
- `browser/desktop-light-hero.png`, `desktop-dark-hero.png`,
  `tablet-light-hero.png`, `mobile-dark-hero.png`, `small-light-hero.png`.
- Six distinct story states, not a frame sweep: `browser/coding-overview.png`,
  `coding-review.png`, `coding-fix.png`, `content-interrupted.png`,
  `research-decision.png`, `research-approved.png`.
- `browser/agent-choice.png`, `desktop-dark-agents.png`, `mobile-dark-agents.png`:
  the new supported-agent section in light/dark and mobile.
- `browser/mobile-gate-viewport.png`: narrow-screen human decision controls.
- `build.log`, `browser.log`, and `browser/results.json`: exact results.

The preview was inspected through a local loopback server on port 8797. This is
render verification, not a public deployment or proof of delivery to a viewer.

## Boundaries and remaining limitations

- The generalized factory is an **illustration**, not a live agent run or a new
  recorded benchmark. The separately linked coding proof is historical.
- Copy does not promise deterministic code replay, exactly-once external
  effects, arbitrary process checkpoint/resume, Temporal compatibility, or a
  universal security sandbox. Retry eligibility and agent permissions vary.
- Browser tests verify page behavior; they do not certify Hive's runtime or
  execute real agents. Document-hidden suspension is implemented; the browser
  regression explicitly exercises offscreen suspension, not OS tab throttling.
- Operations remains outside these two approved phases. No integrations,
  hosted availability, unsupported agent brands, or universal switching claims
  were added.
- The distinct HiveDev intake correction will be reviewed in its own isolated
  worktree and commit. Parent owns publication/release review for both sites.
