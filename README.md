# hive-site

The public website for [Hive](https://github.com/ivankuznetsov/hive) —
**[hivecli.sh](https://hivecli.sh)**. A framework-first marketing landing page
plus curated documentation, built with [Jekyll](https://jekyllrb.com) and
[Just the Docs](https://just-the-docs.com), deployed to Cloudflare Pages.

## Local development

Requires Ruby 3.4.

```bash
ruby script/bundle install
npm ci
ruby script/bundle exec jekyll serve   # http://localhost:4000
```

To preview search locally, build the Pagefind index over the rendered site:

```bash
npm run build
ruby script/bundle exec jekyll serve --skip-initial-build   # or serve _site/ directly
```

Run the workflow-state, catalog, and rendering test suite with `npm test`.

### Framework homepage checks

Workflow examples live in `_data/workflow_examples.json`. The native SVG
renderer shares the original HiveDev machines and motion grammar; see
[asset sources](implementation/ASSET-SOURCES.md). Keep built-in stage lists
aligned with a published Hive release and label custom/illustrative examples.

After `npm run build`, serve `_site/` and run the optional browser checks with
an existing Playwright installation (no production browser dependency):

```bash
python -m http.server 8797 --bind 127.0.0.1 --directory _site
# In another terminal:
SITE_URL=http://127.0.0.1:8797 npm run test:browser
```

If Playwright is installed elsewhere, set `PLAYWRIGHT_MODULE` to its absolute
`index.mjs` path. `BROWSER_CDP` can attach to an existing Chromium endpoint;
checks create and close only their own contexts. Otherwise Playwright launches
its installed headless Chromium. Screenshots and results go to ignored
`test-results/browser/` (override with `REVIEW_OUTPUT`). Checks cover desktop,
tablet, narrow mobile, explicit playback, recovery, human decisions, keyboard,
reduced motion, no JavaScript, and existing Docs/search/catalog routes.

On hosts with system libvips, Sharp may try to compile during `npm ci`.
`SHARP_IGNORE_GLOBAL_LIBVIPS=1 npm ci` uses its packaged binary instead.

### Sitewide editorial and rendering review

After a build, `npm run test:sitewide` inventories every generated HTML route,
checks desktop/mobile in both themes, local links and fragments, raw Markdown
and LLM exports, search/navigation, catalog copying, and benchmark controls.
It uses the same Playwright/CDP environment variables as the homepage checker.
Evidence goes to `test-results/sitewide/after/`; use `REVIEW_OUTPUT` to change
the directory or `REVIEW_SCREENSHOTS=0` for a check without screenshot capture.
Neither browser checker runs agents or allows network mutations.

Before calling a change sitewide:

- Read each page's copy, including generated catalog entries, not just shared
  templates. Record changed and reviewed-no-change routes separately.
- Ask what the reader needs here. Agent-choice cards name agents and link to
  setup; provider/model configuration, permissions, and opt-in requirements
  belong in the setup guide, not badges or subtitles on marketing cards.
- Keep commands, limits, destructive-action warnings, availability, benchmark
  definitions, and permission evidence where readers make those decisions.
  Simplification must not become a stronger claim.
- Check release-sensitive instructions against a tagged release. An archive
  must not promote the discontinued installation as a current recommendation.
- Review rendered copy and representative layouts in both themes and mobile.
  Test counts are technical evidence, not proof of an editorial review.

## Structure

```
index.md              Marketing landing (layout: home)
_includes/landing/    Landing section partials
_layouts/             home (landing) + doc (docs, wraps content for Pagefind)
docs/                 Curated docs — getting-started, concepts, configuration,
                      operating, and commands/* (user-facing subset of the wiki)
bench/                hive-bench leaderboard, methodology, run guide, and the
                      published candidate patches (rendered from _data/bench.json)
honeycombs/           Honeycomb catalog page (rendered from _data/honeycombs.json)
box/, box.sh, box.ps1 Archived Hivebox page; installer scripts stay served for
                      existing installs but are no longer advertised
_data/                Checked-in data snapshots: bench, honeycombs, workflow examples
_plugins/             AI-native generator: per-page .md, llms.txt, llms-full.txt
_sass/                Brand color schemes + overrides for the Just the Docs theme
assets/               CSS (landing.scss, framework.css), JS, fonts, images, media
schemas/              Public Honeycomb JSON schemas served at /schemas/*
_headers, _redirects  Cloudflare Pages config (markdown content-type + CORS)
lib/, script/         Honeycomb catalog sync, Bundler wrapper, browser checkers
test/                 Workflow-state (node) and data/rendering (minitest) suites
implementation/       Provenance of reused design assets
```

## Content

Docs are a curated, user-facing subset of Hive's engineering wiki, authored
here directly (no build-time coupling to the main repo). Internal wiki pages
are never published. The AI-native outputs — `/llms.txt`, `/llms-full.txt`, and
per-page `.md` — are generated from the docs collection, so they track exactly
the published set.

## Honeycomb catalog

`/honeycombs/` is generated only from the checked-in
`_data/honeycombs.json` snapshot. There is no catalog fetch during sync, site
build, or browser use. To update it from a merged Honeycomb checkout:

```bash
HONEYCOMB_ROOT=/path/to/honeycomb
HONEYCOMB_SHA=$(git -C "$HONEYCOMB_ROOT" rev-parse origin/main)
npm run sync:honeycombs -- \
  --catalog "$HONEYCOMB_ROOT/catalog.json" \
  --source-sha "$HONEYCOMB_SHA"
```

The command validates the complete `honeycomb-catalog/v2` document and its
cross-field invariants against the checked-in public schemas. It accepts
designated HTTPS review anchors while keeping fragments forbidden on package,
author, verification, lifecycle, advisory, and community-review URLs. It then
verifies that the SHA exists locally, is merged into local `origin/main`, and
contains the exact input bytes. Only then does it atomically replace the
snapshot; failure preserves the last-known-good file byte for byte.
The production build reruns the test suite, including validation of the
checked-in snapshot envelope and entries, before Jekyll renders it.

The five Honeycomb contracts under `schemas/` are also published at
`https://hivecli.sh/schemas/`. Current contracts use canonical `hivecli.sh`
identifiers; archived catalog v1 retains its historical `$id`. The sync command
resolves schema references locally and never over HTTP.

## Deploying

Deployed to Cloudflare (Workers static assets — the unified Pages flow) via the
repo's Git connection — no GitHub Actions, no secrets. On push, Cloudflare runs:

- **Build command:** `ruby script/bundle install && npm run build`
- **Deploy command:** `npm run deploy` (uploads `_site/` per `wrangler.jsonc`)

`wrangler.jsonc` declares the assets directory (`./_site`); `_headers` and
`_redirects` in `_site` are honored automatically. Non-production branches get
preview versions through `npm run preview`. `package-lock.json` pins the
Pagefind dependency graph and Wrangler itself is pinned exactly.

MIT licensed.
