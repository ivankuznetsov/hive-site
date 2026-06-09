---
title: wiki
layout: doc
parent: Command reference
nav_order: 18
permalink: /docs/commands/wiki/
description: Rebuild a project's wiki/log.md changelog from per-change fragments, or check whether it's stale.
---

# hive wiki

Manages a project's LLM-maintained wiki changelog. Its one subcommand rebuilds
`wiki/log.md` from the individual change fragments under `wiki/log.d/*.md`.
Reach for it after a merge or rebase to refresh the compiled changelog, or to
check that the changelog is up to date.

## Usage

```bash
hive wiki compile-log [PROJECT_PATH] [--check]
```

`PROJECT_PATH` defaults to the current directory, which must contain a `wiki/`
directory.

## Subcommands and options

| Command | What it does |
|---------|--------------|
| `hive wiki compile-log` | Regenerate `wiki/log.md` for the current project. |
| `hive wiki compile-log PATH` | Regenerate the changelog for another checkout. |
| `hive wiki compile-log --check` | Don't write anything; exit non-zero if `wiki/log.md` is stale. |

## How it works

Each wiki change adds a uniquely named fragment under `wiki/log.d/`, for example
`wiki/log.d/20260605-220000-short-topic.md`. The compiler reads those fragments,
sorts them, and writes a regenerated section into `wiki/log.md`, leaving older
legacy entries below it. Running it again is idempotent — it won't duplicate
entries.

Adding fragments instead of editing `wiki/log.md` directly is what keeps
concurrent changes from conflicting on one shared file. Use the mutating
`compile-log` for cleanup after merges or rebases, and prefer `--check` for
verification.

## Examples

```bash
# Rebuild the changelog for the current project
hive wiki compile-log

# Verify the changelog is current (e.g. in CI), without writing
hive wiki compile-log --check
```
