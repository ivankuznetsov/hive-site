# Workflow examples grounded in published Honeycombs

4 November 2026. Implementation branch: `fix/workflow-examples-20261104`.
Base: `bf3d26930cd848579695bc61830b0dee4c5c3497` (`origin/main`).
Worktree: `/home/asterio/Dev/hive-site.worktrees/workflow-examples-20261104`.

## Scope and outcome

The homepage now demonstrates **Coding (Built-in)**, **Writing (Honeycomb)**,
and **Architecture (Honeycomb)**. Architecture replaces the superficial
three-stage Research tab with an existing, installable, research-heavy workflow.
The approved factory illustration, bees, palette, type, page structure, Coding
story, and Hive/HiveDev distinction remain intact. No Hive engine or HiveDev
files were modified. This branch was not pushed, submitted as a PR, or deployed.

Writing is not presented as built-in. The released engine does contain a
separate built-in `content` workflow; the technical docs retain that fact and
explicitly distinguish it from `honeycomb/writing`.

## Source verification and existing-solutions preflight

Inspected the current public catalog, package descriptors, READMEs, and all
Writing/Architecture instruction files before choosing the examples. Also
compared the SEO Content descriptor; its twelve-stage search-content workflow
is less suitable than the focused eight-stage Architecture example here.

- **Honeycomb catalog:**
  [`49a5d313c0498fe3170e71c544fc97877fe9c574`](https://github.com/ivankuznetsov/honeycomb/tree/49a5d313c0498fe3170e71c544fc97877fe9c574).
- **Writing 1.0.2:**
  [descriptor](https://github.com/ivankuznetsov/honeycomb/blob/49a5d313c0498fe3170e71c544fc97877fe9c574/packages/writing/1.0.2/workflow.yml),
  [instructions](https://github.com/ivankuznetsov/honeycomb/tree/49a5d313c0498fe3170e71c544fc97877fe9c574/packages/writing/1.0.2/instructions),
  [README](https://github.com/ivankuznetsov/honeycomb/blob/49a5d313c0498fe3170e71c544fc97877fe9c574/packages/writing/1.0.2/README.md).
- **Architecture 1.0.4:**
  [descriptor](https://github.com/ivankuznetsov/honeycomb/blob/49a5d313c0498fe3170e71c544fc97877fe9c574/packages/architecture/1.0.4/workflow.yml),
  [instructions](https://github.com/ivankuznetsov/honeycomb/tree/49a5d313c0498fe3170e71c544fc97877fe9c574/packages/architecture/1.0.4/instructions),
  [README](https://github.com/ivankuznetsov/honeycomb/blob/49a5d313c0498fe3170e71c544fc97877fe9c574/packages/architecture/1.0.4/README.md).
- **Released Hive v0.8.0:** commit
  `55e8dadca23ff0b8a7f357b56181d757b1e3441d`.
  Read [content.rb](https://github.com/ivankuznetsov/hive/blob/v0.8.0/lib/hive/workflows/content.rb),
  [registry.rb](https://github.com/ivankuznetsov/hive/blob/v0.8.0/lib/hive/workflows/registry.rb),
  [descriptor_parser.rb](https://github.com/ivankuznetsov/hive/blob/v0.8.0/lib/hive/workflows/descriptor_parser.rb),
  and the council runner/reviewer/triage source at that tag—not dirty working files.
  The runner saves numbered reviewer and triage files, plus a latest triage copy.

The existing verified catalog-sync script refreshed `_data/honeycombs.json`
from a fresh local Honeycomb clone pinned to the inspected SHA. Snapshot moved
from `95890f7476048deec6addabb7de940577d4e1afa` (8 releases) to the current SHA
(16 releases, 9 package names). No catalog redesign or trust-policy changes.

Current latest package versions: Architecture 1.0.4, Writing 1.0.2, SEO Content
1.0.2, Docs Sync 0.1.1, Reviewer Panel 1.0.1, Root Cause Repair 1.0.0, Async Fix
0.1.0, Task Inspect 0.1.1, Video Production 0.1.1.

## Chosen storyboards and exact semantics

### Writing: an honest backup guide

| Published stage | Stage artifact |
| --- | --- |
| Inbox | `brief.md` |
| Repo research | `repo-research.md` |
| Web research | `web-research.md` |
| Research | `research.md` |
| Draft | `draft.md` |
| Editorial | `editorial.md` |
| Deliver | `article.md` (also writes `verification.md`) |

The source-to-claim ledger distinguishes supported evidence from an untested
one-hour recovery promise. The grounding editor removes the unsupported claim;
the adversarial editor asks for a more useful restore-test checklist. The
council revises the existing draft, then both editors recheck it. Those are
rounds **inside Editorial**, not invented extra top-level stages. Their review
files and `reviews/triage-01.md`, `reviews/triage-02.md`, and latest
`reviews/triage.md` survive into delivery.

The illustration reaches consensus in round two. Copy explicitly preserves
the actual package's other outcomes: ungrounded research or the five-round cap
produces a **NOT PUBLISHABLE** notice, not a guaranteed publishable article.
Delivering `article.md` does not publish it. The retry demonstration now starts
at Writing's real Draft stage and retains its brief and three research files;
there is no invented `outline.md` stage in this package.

### Architecture: a backup design the team can test

| Published stage | Stage artifact |
| --- | --- |
| Inbox | `brief.md` |
| Repo research | `repo-research.txt` |
| Web research | `web-research.txt` |
| Research | `research.md` |
| Draft | `draft.md` |
| Review | `review.md` |
| Architecture | `architecture.md` |
| Done | `architecture.md` (inert; no new agent) |

The brief asks for off-site PostgreSQL backups and a one-hour restore target
without changing hosting. Repository research finds an existing backup path
but no timed restore evidence. External sources concern recovery behavior and
storage contracts, with dates and applicability limits. Synthesis separates
facts, assumptions, and owner choices; storage durability is not treated as
proof of recovery time.

The constraints and operations reviewers challenge the design. Revision adds
a timed restore drill and separately recoverable credentials; recheck preserves
the still-unmeasured restore-time assumption. The final architecture retains
owner cost decisions and deferred findings. The package allows completion at
its two-round limit **without consensus**; the example does not equate Done
with approval, implementation, deployment, or resolution of every finding.

The tasks and sample outputs are illustrative, not claims about an inspected
customer repository or an executed Hive run. No fake URLs, citations, benchmark
measurements, parallelism claims, or exactly-once/replay guarantees were added.

### Separate custom human gate

Neither package declares a human approval stage. The existing human-decision
interaction therefore lives beside its **separate minimal custom YAML** in
“Define stages in YAML,” rather than being attributed to a Honeycomb.

Approve records a local example decision and completes the sample report.
Reject records the decision and returns to the declared `synthesis` target;
a revision must finish before approval is available again. The decision
history and artifact names remain visible. Reset is explicit. There are no
network writes, file writes, real task execution, publication, or sending from
these browser controls.

The shared state machine now routes rejection by stage ID, not `position - 1`.
It also supports multiple completed outputs and council substeps without
resetting the retry attempt number inside the same stage. A first-stage human
gate starts waiting and cannot be bypassed through Next.

## Proportional design review

Applied the existing `unslop` skill in polish mode (Damir Sokolovsky,
[@heydamir](https://x.com/heydamir), CC BY 4.0). No new direction approval was
needed: the user-authorized correction stays inside the approved direction.

- **Product:** a local-first engine that carries agent work through inspectable stages.
- **Character:** warm, precise, mechanical.
- **World:** the existing honey-colored factory and its saved documents.
- **Moments:** the factory handoff and the concrete artifact inspector.
- **Signature:** the bee carrying the task's changing document between stations.

Audit: the former Research example had no meaningful evidence assessment or
revision process; Content's label did not demonstrate the separately installable
Writing workflow the user meant; fixed stage counts and previous-index rejection
would not safely support the revised examples. The existing visual system itself
was retained.

Passes: kept spacing on the existing scale; reused colors, icons and typography;
replaced vague sample copy with source-backed roles, files and outcomes; made the
station grid follow each workflow's count; added a compact wrapping installation
row and a separate approval panel; retained the existing lift/carry/land motion.
“Next step” correctly covers both top-level stages and council rounds. Revision
uses the reviser role and a draft-shaped artifact while remaining inside the
council station. No raster assets, new visual direction, or decorative motion.

## Verification

| Check | Result |
| --- | --- |
| Published-source contract check | Both package descriptors parse under the extracted v0.8.0 parser; every displayed stage ID, state artifact, and stage kind matches. Custom YAML parses with its two referenced instruction files supplied in a temporary directory. Homepage and docs contain the same YAML. No agent was executed. |
| `npm run build` | **Pass:** 11 JavaScript tests; 25 Ruby tests / 2,631 assertions; Jekyll; 28 Pagefind-indexed documents. |
| `npm run test:browser` | **Pass:** 107 checks, 38 representative screenshots, no browser errors or attempted network mutations. |
| `REVIEW_SCREENSHOTS=0 npm run test:sitewide` | **Pass:** 638 checks across 35 routes × 2 widths × 2 themes (140 probes); 356 internal link targets; no broken targets, overflow, browser errors, or attempted network mutations. |
| `git diff --check` | Pass. |

Unit tests cover the package contracts, Coding's existing fix/recheck path,
saved-input preservation, interrupted draft and council retries, real council
rounds and extra outputs, explicit approval, rejection through a non-adjacent
named target, initial human gates, reset state, and carrier endpoints through
both forward and return/same-station routes.

Browser coverage: 1440px light/dark; 768px light; 390px light/dark; 320px
light/dark. It checks package switching, stage-grid counts, source/install links,
review/revision/recheck, failure/retry, completion, explicit replay, arrow/Home/End
keys, keyboard approval, offscreen suspension, and a paused lifted handoff.
Reduced motion retains manual stepping. No-JavaScript fallback exposes all three
real stage lists, the install/source links and limits, and the separate YAML gate
without dead controls. Existing docs routes, native setup snippets, search,
framework/hosted links and public Honeycomb schema are also checked.

Two intermediate browser expectations were corrected during implementation:
the new actual label is “Repo research” (not the previous “Research”), and the
static completion statement uses “Completion does not mean every finding is
resolved…” rather than the literal word “unresolved.” Assertions still check the
substantive behavior. Mobile evidence uses full-width page clips to avoid a tall
locator screenshot reflowing after its clip width was measured; DOM bounds were
also inspected directly. No product overflow was hidden to make tests pass.

### Local evidence

All following paths are relative to this worktree and are intentionally ignored
build/review output, not production assets:

- `test-results/workflow-examples/source-validation.json`
- `test-results/workflow-examples/final/results.json`
- `test-results/workflow-examples/sitewide/audit.json`
- `test-results/workflow-examples/final/desktop-dark-architecture.png`
- `test-results/workflow-examples/final/writing-overview.png`
- `test-results/workflow-examples/final/writing-editorial-revision.png`
- `test-results/workflow-examples/final/architecture-council-revision.png`
- `test-results/workflow-examples/final/architecture-complete.png`
- `test-results/workflow-examples/final/writing-handoff-paused.png`
- `test-results/workflow-examples/final/small-light-writing.png`
- `test-results/workflow-examples/final/small-dark-writing.png`
- `test-results/workflow-examples/final/mobile-light-architecture.png`
- `test-results/workflow-examples/final/mobile-dark-architecture.png`
- `test-results/workflow-examples/final/small-light-custom-gate.png`
- `test-results/workflow-examples/final/nojs-architecture.png`

The pre-change reference was inspected at the previous worktree's
`test-results/sitewide/framework-final/research-decision.png`. Final screenshots
were visually reviewed for actual content, stage roles, artifact poses, readable
mobile rows, both themes, and the separate gate—not an exhaustive frame sweep.

Build/browser/sitewide logs are copied into `test-results/workflow-examples/`.
The local server uses port 8804; this is a worker-local review address, not proof
of a delivered hosted preview or a production deployment.

### Reproduce

```bash
PATH=/home/asterio/.local/share/gem/ruby/3.4.0/bin:$PATH npm run build
python3 -m http.server 8804 --bind 127.0.0.1 --directory _site
```

With that server running, in a separate shell:

```bash
export NO_PROXY=127.0.0.1,localhost
export no_proxy=127.0.0.1,localhost
export PLAYWRIGHT_MODULE=/home/asterio/Dev/hivedevai-site.worktrees/factory-polish-20261104/node_modules/playwright/index.mjs
export BROWSER_CDP=http://127.0.0.1:18800
export SITE_URL=http://127.0.0.1:8804
REVIEW_OUTPUT=test-results/workflow-examples/final npm run test:browser
REVIEW_OUTPUT=test-results/workflow-examples/sitewide REVIEW_SCREENSHOTS=0 npm run test:sitewide
```

Catalog sync used:

```bash
PATH=/home/asterio/.local/share/gem/ruby/3.4.0/bin:$PATH npm run sync:honeycombs -- \
  --catalog /tmp/hive-honeycomb-catalog-checkout-20261104/catalog.json \
  --source-sha 49a5d313c0498fe3170e71c544fc97877fe9c574
```

## Changed files

- `_data/workflow_examples.json`: actual package contracts, storyboards, round outputs and source links.
- `_data/approval_example.json`: the separate minimal gate's state data.
- `_data/honeycombs.json`: verified current catalog snapshot.
- `_includes/landing/workflows.html`: installation row and matching static fallback.
- `_includes/landing/authoring.html`: explicit custom-gate distinction and local interaction.
- `assets/js/workflow-state.mjs`: multi-artifact output, council attempt continuity, named rejection, layouts.
- `assets/js/workflow-view.mjs`: package metadata, round states/roles/artifact forms, Writing retry and accurate controls.
- `assets/js/approval-example.mjs`: the isolated, local-only custom decision example.
- `assets/css/framework.css`: dynamic stage counts, wrapping package row and custom-gate spacing.
- `docs/index.md`, `docs/concepts.md`, `docs/custom-workflows.md`: precise built-in/package/custom taxonomy and installation links.
- `test/workflow-state.test.mjs`, `script/check-framework.mjs`: behavioral and responsive regression checks.
- This report.

## Limits and follow-up ownership

This is a browser illustration, not an executed end-to-end package acceptance
run. The displayed sample facts are invented scenario inputs, clearly labeled
as illustrative, not new factual product claims. The custom YAML still requires
its instruction files and project setup as the linked guide explains. Package
installation uses current catalog resolution; the inspected versions and source
links are pinned in the example and this report.

The existing lockfile was unchanged. `npm ci` reported four high-severity
transitive advisories; no unrelated dependency upgrade was attempted. Existing
Sass deprecation warnings remain non-fatal. Parent review owns any hosted preview,
PR, merge, or production publication.
