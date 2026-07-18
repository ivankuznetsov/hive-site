# hive-site

The public website for [Hive](https://github.com/ivankuznetsov/hive) —
**[hivecli.sh](https://hivecli.sh)**. An outcome-first marketing landing page
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

Run the complete catalog and rendering test suite with `npm test`.

## Structure

```
index.md              Marketing landing (layout: home)
_includes/landing/    Landing section partials
_layouts/             home (landing) + doc (docs, wraps content for Pagefind)
docs/                 Curated docs — getting-started, concepts, configuration,
                      operating, and commands/* (user-facing subset of the wiki)
_plugins/             AI-native generator: per-page .md, llms.txt, llms-full.txt
_sass/custom/         Brand overrides for the Just the Docs theme
assets/               CSS (landing.scss), images, demo media
schemas/              Public Honeycomb JSON schemas served at /schemas/*
_headers, _redirects  Cloudflare Pages config (markdown content-type + CORS)
script/               Bundler wrapper + explicit Honeycomb catalog sync
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
