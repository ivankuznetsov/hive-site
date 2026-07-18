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
_plugins/             AI-native outputs + local catalog build validation
_sass/custom/         Brand overrides for the Just the Docs theme
assets/               CSS (landing.scss), images, demo media
honeycombs/            Static catalog discovery page
lib/                   Offline catalog validation and internal v2 contracts
test/                  Focused sync, rendering, and build proof
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
`_data/honeycombs.json` snapshot. The snapshot is the byte-for-byte upstream
`honeycomb-catalog/v2` payload: it has no site envelope, generated timestamp,
or entries derived from package manifests. There is no catalog fetch during
sync, site build, or browser use.

To update it, first refresh and review a trusted local Honeycomb checkout. Use
the full commit SHA already merged into its local `origin/main`:

```bash
HONEYCOMB_ROOT=/path/to/honeycomb
git -C "$HONEYCOMB_ROOT" fetch origin main
HONEYCOMB_SHA=$(git -C "$HONEYCOMB_ROOT" rev-parse origin/main)
git -C "$HONEYCOMB_ROOT" show --stat "$HONEYCOMB_SHA"

ruby script/bundle exec ruby script/sync-honeycombs \
  --catalog "$HONEYCOMB_ROOT/catalog.json" \
  --source-sha "$HONEYCOMB_SHA"
```

The sync command itself performs no fetch. It verifies the repository-root
path, canonical Honeycomb `origin` identity, full SHA, local `origin/main`
ancestry, and exact committed `catalog.json` bytes. Those checks prove the
operator's local checkout is internally consistent; they do not authenticate a
compromised checkout or remote. Record the reviewed source SHA in the site
change's commit or pull request.

The command parses and validates the whole document in memory against the two
internal upstream v2 contracts plus the site's consumer-visible coherence
rules. Only after every check succeeds does it atomically replace the snapshot
with the exact upstream bytes. Usage, source, validation, and write failures are
reported separately; all failures preserve the last-known-good snapshot byte
for byte. A Jekyll hook revalidates the raw checked-in snapshot before rendering,
so a direct invalid edit also fails closed without Git or network access.

Run the focused gate and a clean site build before committing the snapshot:

```bash
ruby script/bundle exec ruby -Itest test/run.rb
ruby script/bundle exec jekyll build
```

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
