# Hive sitewide Unslop — 4 November 2026

## Scope and method

Implemented by the requested **GPT-6 Astra, max reasoning**, in the existing
isolated `feat/durable-workflows-20261104` worktree. Starting HEAD:
`26ed0780b01fbf28f2e00df2708d9c50f0d9cb3c`; checkout was clean. No delegation,
primary-checkout changes, framework/HiveDev edits, publication, or agent runs.

Method: **Unslop by Damir Sokolovsky** ([heydamir](https://x.com/heydamir),
[Unslop](https://heydamir.design/unslop)), CC BY 4.0. Read `SKILL.md` and its
signs, tokens, visuals, and references. This credit belongs in the report, not
product marketing. The user explicitly requested implementation, and the
existing brand direction is approved; the skill's “skip the wait … when the
user already said to just do it” applies.

Existing-solutions preflight: retain Jekyll, Just the Docs, Pagefind, native
SVG, existing stylesheet hooks and Playwright checks. No dependency, new UI
framework, generated art, or animation library is needed.

## Audit recorded before product edits

Mode: **light polish**, with older secondary-page styles needing alignment.
Round 1 captured the local build at the starting HEAD, not production as a
replacement baseline. It enumerated 35 HTML routes and extracted every rendered
main body. 140 viewport/theme probes found no document overflow; Box had two
competing H1s. 88 before screenshots cover 22 representative views at desktop
1440 and mobile 390, light and dark preferences. Secondary landing pages did
not yet support light mode; their before light captures therefore remain dark.

- Home agent grid: OpenCode's “Opt-in / Explicit provider/model and scoped
  setup” exposes setup internals in an agent-choice card.
- Docs introduction/concepts/custom workflows: repeated “flagship” framing,
  “load-bearing” jargon, slogans, italic emphasis, and blanket easy/autonomous
  claims delay concrete explanations.
- Custom workflow guide: repeated daemon reassurance and “push past a gate”
  phrasing obscure actual intervention/decision behavior. Its writing-template
  example is stale against v0.8.0.
- Command index: claims every command is covered and recommends only the TUI,
  despite the native web UI and additional commands. Migration appears current
  although the release notes record its removal.
- Bench run guide: still calls v0.4.1 latest and directs readers to an old PR
  for a workflow shipped in v0.8.0. Leaderboard introduction contradicts its
  actual default discussion-score ordering.
- Box archive: discontinuation warning competes with an H1 promising “shipped
  while you sleep,” alpha promotion, three hero actions, a no-config guarantee,
  and a release/support promise. Its recording autoplays and loops.
- Honeycombs: “Canonical order” and “registry snapshot is valid” are maintainer
  narration. Trust/risk/permission evidence is decision-relevant and must stay.
- Docs shell: emoji theme button, purple default navigation, bright honey links
  on white, bold wordmark, conspicuous outlined export controls, and unsupported
  “Built by Hive itself” footer.
- Secondary landing shell: older blue-grey palette, tracked uppercase labels,
  heavy headings, tiny pill metadata, uneven fractional-rem spacing, glass
  header, and Box radial wash.
- 404: a joke substitutes for a clear missing-page heading.

Preserve: approved home layout/hero, 9/6/3 demo stages, necessary retry/approval
limits, all command/config facts except verified stale instructions, private
import availability and setup/security requirements, changelog history,
catalog snapshot/schema/permission disclosure, benchmark numbers/definitions/
unknown values/withdrawals/public evidence, installer URLs, and all routes.

## Five-line direction recorded before product edits

1. **Product:** Local agent workflows with saved outputs, human decisions, and
   recoverable stages.
2. **Character:** Precise, warm, practical.
3. **World:** A document workbench with named stages and inspectable files.
4. **Moments:** The existing factory illustration and the benchmark's actual
   evidence, not decorative chrome.
5. **Signature:** Honey-colored artifact handoffs, with quiet navigation
   everywhere else.

## Pass order

Spacing → color → icons → copy → type → layout → details → visuals → motion.
Apply this order to the shared style edits and page copy. Keep sections and
features, do not force copy changes on good pages. At most three grouped visual
review rounds; screenshots are evidence, not animation frame sweeps.

## Nine-pass decisions

1. **Spacing.** Normalize secondary-page padding, gaps, and metadata spacing
   to the existing 4px rhythm. Keep the homepage's approved composition. The
   fifth agent tile now occupies the same column width as the other four.
2. **Color.** Extend the approved warm neutral/honey ramp to Honeycombs, Bench,
   Box, 404, and both Just the Docs themes. Secondary landing pages now honor
   the system light preference. Docs keep their existing persistent theme
   switch. Remove the old blue-grey surfaces, translucent header, radial wash,
   and purple docs navigation. Distinguish hover/focus/active states without
   adding decorative colors.
3. **Icons.** Retain the coherent existing SVG set. Replace the docs moon/sun
   emoji button with an explicit destination label: “Light theme” or “Dark
   theme.” Remove the ornamental checkmark from clipboard success. No new
   agent logos or icon dependency.
4. **Copy.** Read every authored page and active partial, the eight generated
   catalog records, and every rendered main body. Edit for the reader's task:
   agent choice on the homepage, precise setup and operation in docs, evidence
   interpretation in Bench, and maintenance/migration in the Box archive.
   Remove repeated slogans and internal narration, not operational conditions.
   Six pages retain their copy after review; details below.
5. **Type.** Reuse the existing Space Grotesk asset for secondary-page and docs
   headings; retain system body and monospace code text. Reduce heavy heading
   weights, uppercase tracking, italic emphasis, and tiny badge text. Code
   uses neutral high-contrast text and one honey syntax accent. Tabular numbers
   remain useful for comparison tables.
6. **Layout.** Keep every page section and information feature. Constrain long
   prose, not benchmark tables. Keep all candidate rows, score matrices,
   permission fields, and long code examples; their existing responsive or
   internal-scroll behavior remains. Give Box one primary H1 and a coherent
   discontinued-product hierarchy. Navigation destinations and anchor IDs stay.
7. **Details.** Calm export buttons, tags, borders, and search chrome; add
   visible focus treatment. Clipboard and theme actions stay hidden without
   their JavaScript capability. Markdown copying checks the HTTP response.
   Fix the permissions example's exposed code fence and preserve old heading
   anchors when improving their labels. Generated Markdown strips those
   Kramdown attributes instead of leaking template syntax.
8. **Visuals.** Keep the existing architectural factory/bee SVG and archived
   Box recording. No image generation, stock art, new font, or decorative
   graphic. The actual workflow, catalog permissions, and benchmark evidence
   remain the visual content.
9. **Motion.** Do not change the approved workflow state machine or add an
   animation library. Preserve its manual controls, human decision, retry,
   keyboard, reduced-motion, and no-JavaScript paths. Box's archive recording
   now has user controls instead of autoplay/loop. Shared reduced-motion rules
   remove unnecessary transitions.

## Editorial examples and correctness boundaries

| Area | Before | After / reason |
|---|---|---|
| Homepage agent card | `OpenCode` / `Opt-in` / `Explicit provider/model and scoped setup` | **OpenCode**, linked directly to its tagged setup guide. No badge or setup subtitle. Provider/model, opt-in, and permission requirements remain in Configuration and that guide. |
| Homepage agents | “Agent configuration”; “Set each agent stage’s CLI and model in your workflow configuration.” | “Choose agents by stage”; “Choose an agent and model for each stage.” The card supports choosing an agent, not reading implementation notes. |
| Homepage recovery | A separate deterministic-replay/exactly-once disclaimer repeats the retry explanation. | “Recovery behavior and limits →” links to the full explanation. The adjacent paragraph still says recovery checks may require human intervention; Concepts retains the exact limits. |
| Concepts | “three load-bearing ideas”; “flagship”; repeated engine justification | Explain task folders, stages, markers, and saved outputs directly. Keep SQLite runtime coordination, retry semantics, and the difference between worktree isolation and security sandboxing. |
| Custom workflows | “in a few minutes”; “You don't touch a thing”; “push past a gate” | Describe the descriptor, instruction files, enrollment, inspection, and recovery. `kind: human` uses an explicit `hive decide` outcome; moving a folder is not a substitute. |
| Command index | “Every user-facing hive command”; TUI as the sole recommended human surface | “common CLI operations,” a link to the complete v0.8.0 reference, and both native web UI and TUI. No invented coverage claim. |
| `new` / `status` | Inbox is always inert; status “never changes anything” | No agent runs in the inbox, but an enrolled daemon can advance ready tasks. Status is read-only by default, with its existing `--diagnose --write` exception made explicit. |
| `drop` | “reach for it when you want a task gone for good” | Directly state no archive, undo, or confirmation prompt, and tell the reader to check the target. Destructive behavior is not softened. |
| Honeycombs | “Canonical order”; “The registry snapshot is valid” | “Listed releases, ordered by name and version”; a straightforward empty state. Approval, trust tier, lifecycle, risk, full permissions, and evidence links remain. |
| Bench | “Two independent rulers”; contradictory opening rank description | “Two independent judges”; accurately describe the default after-discussion sort while keeping independent scores as primary evidence. No data or methodology simplification. |
| Box | “Your software ideas, shipped while you sleep”; Alpha; “No config files, ever” | “Hivebox is discontinued”; archive context and native-install/migration links. Preserve demo, setup history, installer commands, and ownership/proxy warning. |
| 404 | “That page flew off somewhere” | “Page not found,” with home and docs recovery links. |

### Verified release-sensitive corrections

These are corrections to instructions, not marketing simplifications. Public
v0.8.0 source was read and local reference copies are under the ignored
`test-results/sitewide/reference/` directory.

- **Bench is shipped:** replace the v0.4.1/PR #734 unreleased notice with the
  v0.8.0 packaged workflow and its
  [tagged workflow reference](https://github.com/ivankuznetsov/hive/blob/v0.8.0/docs/workflows.md#run-the-built-in-benchmark-workflow).
- **Scaffolding:** the tagged workflow reference lists `blank` and `research`
  as scaffold templates; `writing` is a reviewed Honeycomb, not that old
  template. The template example now uses `research`. The writing walkthrough
  explicitly saves its descriptor and three instruction files, validates, and
  commits them before creating a task.
- **Migration:** the [tagged historical command page](https://github.com/ivankuznetsov/hive/blob/v0.8.0/wiki/commands/migrate.md),
  release notes, and CLI source confirm removal of `hive migrate`. Keep its
  URL and old reference, mark it removed, remove it from the current lifecycle
  row, and link the
  [current-format conversion guide](https://github.com/ivankuznetsov/hive/blob/v0.8.0/docs/guides/current-format-migration.md).
- **Inbox dispatch:** the [tagged README](https://github.com/ivankuznetsov/hive/blob/v0.8.0/README.md)
  and workflow guidance support enrolled-daemon advancement, not a blanket
  inert-inbox claim.
- **OpenCode:** retain the actual prerequisites in
  [the tagged setup guide](https://github.com/ivankuznetsov/hive/blob/v0.8.0/docs/getting-started.md#optional-opencode-profile)
  and `/docs/configuration/#agent-profiles`.
- **Historical changelog:** scope the existing browser-capture limitation and
  Hivebox availability statement to its 0.7.3 entry, rather than presenting
  it as the current distribution status.

Retained deliberately: private import is **unreleased**; repository permission
does not enable an absent importer; credentials stay outside repository URLs;
pin/review/import configuration guidance remains; patrol is opt-in; babysitter
is experimental; provider usage costs money; permission enforcement depends
on the agent profile; no universal sandbox, deterministic replay, or exactly-once
claim is introduced. No command, provider, signup, or benchmark campaign was run.

## Complete generated-route inventory

**35/35 HTML routes** enumerated from `_site` after the existing build. This is
**28 documentation routes (19 command routes: index plus 18 details)**, the
homepage, Honeycombs, three Bench pages, Box, and 404. Every source and rendered
main body was inspected. Copy changed on **29** routes and was intentionally
retained on **6**. Shared styling applies to all; it is not counted as a copy
review or as an individual visual inspection.

All docs use `_layouts/doc.html` over Just the Docs, with
`_includes/{head_custom,header_custom}.html` and `_sass/{color_schemes,custom}/`.
Other pages use `_layouts/home.html`, shared landing header/footer, and
`assets/css/landing.scss`; home additionally uses `framework.css`.

| Generated route | Source / page partials | Copy disposition and reason |
|---|---|---|
| `/` | `index.md`, `_includes/landing/{hero,workflows,cards,proof,authoring,install}.html` | **Changed:** simplify agent choice and recovery link; remaining approved hero, 9/6/3 workflow stories, proof, authoring, install and hosted distinction reviewed and retained. |
| `/404.html` | `404.html` | **Changed:** clear missing-page label and recovery options. |
| `/bench/` | `bench/index.md`, `_includes/bench/{about,leaderboard,run}.html` and data-driven subpartials | **Changed:** clearer terms and correct sort explanation; all evidence and caveats retained. |
| `/bench/methodology/` | `bench/methodology.md` | **Reviewed, no copy change:** technical provenance, missing values, withdrawal, sampling, judge bias and accounting detail are necessary for interpreting results. Shared typography only. |
| `/bench/run/` | `bench/run.md` | **Changed:** shipped v0.8.0 guidance replaces obsolete release/PR notice; campaign and publication safeguards retained. |
| `/box/` | `box/index.md`, `_includes/box/{hero,demo,how,install,cta}.html` | **Changed:** consistently archived voice, one H1, controlled recording, native-install recommendation; all historical sections and installers retained. |
| `/docs/` | `docs/index.md` | **Changed:** direct engine/task explanation and task-oriented entry links; private import availability stays explicit. |
| `/docs/build-private-workflow/` | `docs/build-private-workflow.md` | **Reviewed, no copy change:** publishing structure, permissions, contract and review requirements are directly actionable. Shared typography only. |
| `/docs/changelog/` | `docs/changelog.md` | **Changed:** scope the 0.7.3 limitation to that version; release history preserved. |
| `/docs/commands/` | `docs/commands/index.md` | **Changed:** accurate scope, native UI choices, historical migration link separated from current lifecycle commands. |
| `/docs/commands/approve/` | `docs/commands/approve.md` | **Changed:** precise marker/locking behavior and distinction from recorded human decisions; options retained. |
| `/docs/commands/babysit/` | `docs/commands/babysit.md` | **Changed:** remove redundant recommendation; experimental status and mutation conditions retained. |
| `/docs/commands/bot/` | `docs/commands/bot.md` | **Changed:** direct capability description; chat allowlist and shared workflow behavior retained. |
| `/docs/commands/daemon/` | `docs/commands/daemon.md` | **Changed:** enrolled-project scope, concrete dry-run comments and service wording; gates/configuration retained. |
| `/docs/commands/doctor/` | `docs/commands/doctor.md` | **Reviewed, no copy change:** diagnostic behavior, options and examples are already concrete. Shared typography only. |
| `/docs/commands/drop/` | `docs/commands/drop.md` | **Changed:** direct destructive-action warning; no archive/undo/confirmation facts retained. |
| `/docs/commands/findings/` | `docs/commands/findings.md` | **Changed:** name atomic writes and locking without the absolute “never race” claim. |
| `/docs/commands/init/` | `docs/commands/init.md` | **Changed:** “project settings” replaces “full list of knobs”; setup choices and noninteractive defaults retained. |
| `/docs/commands/metrics/` | `docs/commands/metrics.md` | **Changed:** explain rollback-rate measurement without a vague quality promise. |
| `/docs/commands/migrate/` | `docs/commands/migrate.md` | **Changed:** clearly historical removed command, backup/conversion guidance; old URL and reference preserved. |
| `/docs/commands/new/` | `docs/commands/new.md` | **Changed:** accurate inbox/daemon distinction and direct capture explanation. |
| `/docs/commands/patrol/` | `docs/commands/patrol.md` | **Changed:** trim repeated recommendation; opt-in, validation and cost/permission details retained. |
| `/docs/commands/run/` | `docs/commands/run.md` | **Changed:** concrete example comment replaces “rebase ceremony”; flags and safety behavior retained. |
| `/docs/commands/status/` | `docs/commands/status.md` | **Changed:** qualify read-only default with the documented diagnostic-write exception. |
| `/docs/commands/tui/` | `docs/commands/tui.md` | **Changed:** present terminal interface alongside native web UI; keys and behavior retained. |
| `/docs/commands/uninstall/` | `docs/commands/uninstall.md` | **Changed:** remove redundant recommendation; default preservation and destructive options retained. |
| `/docs/commands/update/` | `docs/commands/update.md` | **Reviewed, no copy change:** update behavior, options and examples are concrete. Shared typography only. |
| `/docs/commands/wiki/` | `docs/commands/wiki.md` | **Reviewed, no copy change:** compilation, fragments, search, and concurrency explanations are useful reference material. Shared typography only. |
| `/docs/concepts/` | `docs/concepts.md` | **Changed:** direct task/stage/state explanation; all recovery, runtime-control-plane, workflow and sandbox limits retained. |
| `/docs/configuration/` | `docs/configuration.md` | **Changed:** plain labels and validation wording; OpenCode prerequisites, budget defaults and full YAML examples retained. Old section anchor retained. |
| `/docs/custom-workflows/` | `docs/custom-workflows.md` | **Changed:** remove repeated slogans/automation promises, correct scaffolding, clarify human decisions and agent-dependent permissions, repair fenced YAML rendering. Old anchor retained. |
| `/docs/getting-started/` | `docs/getting-started.md` | **Changed:** built-in coding example rather than “flagship”; native setup, command sequence and prerequisites reviewed and retained. |
| `/docs/operating/` | `docs/operating.md` | **Changed:** task-oriented service wording; loopback boundary, dry-run/cost guidance, enrollment and hosted status retained. Old anchor retained. |
| `/docs/private-workflows/` | `docs/private-workflows.md` | **Reviewed, no copy change:** unreleased availability and installation/access/pinning requirements must remain visible. Shared typography only. |
| `/honeycombs/` | `honeycombs/index.md`, `_includes/honeycombs/catalog.html`, `_data/honeycombs.json` | **Changed:** remove maintainer narration, simplify install label; all canonical listing content and security evidence preserved. |

### Generated details and non-HTML surfaces

- **Honeycombs:** eight inline catalog releases, not eight extra HTML routes:
  `architecture` 1.0.1 and 1.0.2, `async-fix` 0.1.0, `reviewer-panel` 1.0.0,
  `root-cause-repair` 1.0.0, `seo-content` 1.0.1, `task-inspect` 0.1.0, and
  `writing` 1.0.1. Read the descriptions, lifecycle/tier/risk, requested access,
  version/review provenance, and install commands. Preserve these canonical
  records rather than rewriting registry data as marketing. Empty-state copy
  is also reviewed; existing Ruby tests exercise its rendered branch.
- **Bench:** all 15 candidate rows, 90 quality cells, 90 efficiency cells,
  180 discussion-final judge decisions, task notes, sample counts, tooltip
  definitions, unknown/partial values, and withdrawal context remain. Data and
  all public patch files are unchanged. `/bench/results.json` is a data route,
  not a missing HTML page.
- **Machine-readable docs:** all 28 `/docs…md` exports match the authored
  sources after version/URL resolution and template-attribute removal. Both
  `/llms.txt` and `/llms-full.txt` include the expected 26 non-index document
  bodies/links. No separate stale copy was hand-edited.
- **Public contracts:** retain the five schema URLs: `catalog-v1.json`,
  `catalog-v2.json`, `listing-approval-v1.json`, `listing-evidence-v1.json`,
  `security-lint-evidence-v1.json`. Catalog data, benchmark data/patches,
  `box.sh`, `box.ps1`, install URLs and dependency lockfile are untouched.
- **Chrome:** inspect header, main navigation, mobile disclosure, docs sidebar
  and command submenu, search results, theme/export controls, footer, and
  framework-versus-hosted links. Existing site navigation destinations remain;
  the unsupported docs footer “Built by Hive itself” is removed.

## Verification and evidence

Technical counts are separate from the editorial coverage above.

| Check | Final result |
|---|---|
| `PATH=/home/asterio/.local/share/gem/ruby/3.4.0/bin:$PATH npm run build` | **Pass:** 7 JavaScript tests; 25 Ruby tests, 2,631 assertions; Jekyll build; 28 Pagefind-indexed docs. |
| `npm run test:browser` | **Pass:** 54 homepage/interaction assertions; no browser errors or attempted network mutations. Includes 9/6/3 examples, human decision/retry, keyboard, reduced motion, no-JS, mobile navigation and existing routes. |
| `npm run test:sitewide` | **Pass:** 638 assertions; 35 routes × 2 widths × 2 themes = **140 probes**; 106 final screenshots; no failures, page overflow, duplicate IDs, unnamed visible controls, missing image alt attributes, exposed fences/orphaned HTML, browser errors, or attempted network mutations. |
| Local destinations | **356 unique local link/file/fragment targets** resolve; no broken internal targets. Comparing before/after route IDs finds **zero removed anchors**. |
| Functional checks | Pagefind returns linked results in all four viewport/theme combinations; docs mobile menu and theme persistence work; docs/catalog clipboard content matches sources; benchmark mobile cost sorting and keyboard tooltips work; all rows/cells remain; archive recording is user-controlled. |
| No-JavaScript narrow view | Honeycombs, Bench, Box and Custom workflows retain main content without page overflow at 320px; homepage fallback is covered by the existing checker. |
| Export consistency | All 28 raw Markdown exports and the two LLM files match current source/version content. |
| Palette checks | Declared light body/link contrasts are 6.32:1 / 6.09:1; dark body/link 9.86:1 / 11.18:1. Main code text 13.12:1 light / 14.83:1 dark. These are sampled token-pair checks, not a claim of complete accessibility certification. |
| Hover/focus contrast | **16 computed-style checks pass** across Box ghost links, Honeycomb copy buttons, and Bench sort/info controls in both themes. Lowest observed text contrast is 5.59:1. Final color-only corrections use the text accent, not the bright filled-button color. |
| Source integrity | `git diff --check` passes. No data/schema/patch/installer/dependency or workflow-state-machine changes. |

Browser commands use the existing Playwright module, loopback CDP endpoint,
owned contexts, and GET/HEAD-only routing. Reproduction settings:

```sh
export PLAYWRIGHT_MODULE=/home/asterio/Dev/hivedevai-site.worktrees/factory-polish-20261104/node_modules/playwright/index.mjs
export BROWSER_CDP=http://127.0.0.1:18800
export NO_PROXY=127.0.0.1,localhost
export no_proxy=127.0.0.1,localhost
REVIEW_OUTPUT=test-results/sitewide/final npm run test:sitewide
REVIEW_OUTPUT=test-results/sitewide/framework-final npm run test:browser
```

Serve the completed `_site` on `http://127.0.0.1:8797` first. Checks do not
install or execute Hive, spend model quota, submit a campaign, or mutate an
external service. `script/check-sitewide.mjs` is a small extension of existing
site tooling, not a new testing platform. It introduces no production dependency.
The existing homepage test now asserts the plain OpenCode link rather than
requiring the rejected badge.

### Three grouped visual review rounds

1. **Before:** `test-results/sitewide/before/` — 88 screenshots, 22 selected
   views × four viewport/theme combinations, plus extracted main content from
   every route. Read the contact sheets for each layout family.
2. **Implementation review:** `test-results/sitewide/after/` — 94 screenshots
   (the same 88 plus search/mobile menu states); read desktop-light/mobile-dark
   contact sheets and alternate desktop-dark/mobile-light sheets. Read all
   rendered-copy diffs, not only screenshot headings. This caught an intermediate
   Box markup remnant and the permissions guide's pre-existing exposed fence;
   both are fixed. Improve code contrast and quiet inactive navigation.
3. **Final:** `test-results/sitewide/final/` — 106 screenshots: 25 selected
   views × four combinations plus four search and two mobile-menu views. The
   added views cover permissions YAML, high-risk catalog access, and the long
   methodology table. Review `contact-0.png` through `contact-3.png`,
   `final-risk-0.png`, `final-risk-1.png`, and native-size mobile search/menu
   captures. Check both themes at desktop and mobile, plus homepage scenario
   evidence in `test-results/sitewide/framework-final/`. No fourth visual
   review round or animation-frame sweep.

Representative before/after pairs have the same names in `before/` and `final/`:
`agents-{1440,390}-{light,dark}.png`, `docs-…`, `commands-…`,
`configuration-…`, `custom-…`, `honeycombs-…`, `leaderboard-…`, `bench-run-…`,
`box-…`, and `not-found-…`. Extra page-specific and interaction captures are
listed in `final/audit.json`. Screenshots are intentionally ignored, local
review evidence, not committed product assets.

Logs: `test-results/sitewide/build.log`, `final-browser.log`,
`final-framework-serial.log`; main copy: `before/rendered-content.txt` and
`final/rendered-content.txt`; visual audit inventory/results: `final/audit.json`.
After the final hover/focus-only color correction, the site was rebuilt.
Computed-style results are in `interaction-contrast.json`; the screenshot-free
sitewide rerun passes all 638 checks in `final-verification/audit.json`
(`final-verification.log`).
This is a technical verification, not a fourth visual review round.
During development, two Honeycomb contract assertions were satisfied by
retaining required guarantee/approval language, not changing the tests.
The first browser harness attempt needed correct stylesheet selection and
asynchronous clipboard waiting. One concurrently run homepage check failed
its reduced-motion visibility assertion; an isolated inspection and the
complete serial rerun both pass, without a product-code change. The concurrent
failure log is retained; its root cause is not claimed as established.

### Limits and handoff

This is source, rendered-content, visual, and browser-behavior review of the
local built site. It is not exhaustive runtime validation of every Hive CLI
operation, every external destination, every browser, or accessibility
certification. Public source was consulted for the specific stale instructions
listed above. No content/data was deleted to make tables or docs fit.

Publication belongs to the parent task: this work does **not** push, update a
PR, deploy, or verify a viewer-rendered public preview. Production remains
unchanged. The parent should inspect the committed result, publish to existing
PR #34, and check the refreshed preview before reporting public delivery.

The README now records the durable project lesson: marketing agent cards name
agents and link to setup; setup internals belong in decision-relevant docs.
Sitewide claims require per-page copy review as well as technical tests. No
learned skill or unrelated workspace configuration was edited.

## Exact changed files

The following list is generated from this pass's diff and newly authored files;
ignored review evidence and generated `_site` output are not committed.

```text
404.html
README.md
_config.yml
_includes/bench/about.html
_includes/bench/leaderboard.html
_includes/bench/run.html
_includes/box/cta.html
_includes/box/demo.html
_includes/box/hero.html
_includes/box/how.html
_includes/box/install.html
_includes/head_custom.html
_includes/header_custom.html
_includes/honeycombs/catalog.html
_includes/landing/cards.html
_includes/landing_head.html
_layouts/doc.html
_plugins/llm_markdown.rb
_sass/color_schemes/dark.scss
_sass/color_schemes/light.scss
_sass/custom/custom.scss
assets/css/framework.css
assets/css/landing.scss
bench/run.md
box/index.md
docs/changelog.md
docs/commands/approve.md
docs/commands/babysit.md
docs/commands/bot.md
docs/commands/daemon.md
docs/commands/drop.md
docs/commands/findings.md
docs/commands/index.md
docs/commands/init.md
docs/commands/metrics.md
docs/commands/migrate.md
docs/commands/new.md
docs/commands/patrol.md
docs/commands/run.md
docs/commands/status.md
docs/commands/tui.md
docs/commands/uninstall.md
docs/concepts.md
docs/configuration.md
docs/custom-workflows.md
docs/getting-started.md
docs/index.md
docs/operating.md
implementation/UNSLOP-SITEWIDE-20261104.md
package.json
script/check-framework.mjs
script/check-sitewide.mjs
```

52 files in this pass; no deletions.
