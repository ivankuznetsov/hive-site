# hive-site

The public website for [Hive](https://github.com/ivankuznetsov/hive) —
**[hivecli.sh](https://hivecli.sh)**. An outcome-first marketing landing page
plus curated documentation, built with [Jekyll](https://jekyllrb.com) and
[Just the Docs](https://just-the-docs.com), deployed to Cloudflare Pages.

## Local development

Requires Ruby 3.4.

```bash
bundle install
bundle exec jekyll serve   # http://localhost:4000
```

To preview search locally, build the Pagefind index over the rendered site:

```bash
bundle exec jekyll build
npx -y pagefind@^1 --site _site
bundle exec jekyll serve --skip-initial-build   # or serve _site/ directly
```

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
_headers, _redirects  Cloudflare Pages config (markdown content-type + CORS)
.github/workflows/    Build (Jekyll + Pagefind) → deploy to Cloudflare Pages
```

## Content

Docs are a curated, user-facing subset of Hive's engineering wiki, authored
here directly (no build-time coupling to the main repo). Internal wiki pages
are never published. The AI-native outputs — `/llms.txt`, `/llms-full.txt`, and
per-page `.md` — are generated from the docs collection, so they track exactly
the published set.

## Deploying

Deployed to Cloudflare (Workers static assets — the unified Pages flow) via the
repo's Git connection — no GitHub Actions, no secrets. On push, Cloudflare runs:

- **Build command:** `bundle exec jekyll build && npx -y pagefind@^1 --site _site`
- **Deploy command:** `npx wrangler deploy` (uploads `_site/` per `wrangler.jsonc`)

`wrangler.jsonc` declares the assets directory (`./_site`); `_headers` and
`_redirects` in `_site` are honored automatically. Non-production branches get
preview deployments.

MIT licensed.
