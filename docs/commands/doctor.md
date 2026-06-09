---
title: doctor
layout: default
parent: Command reference
nav_order: 12
permalink: /docs/commands/doctor/
description: Preflight check that verifies your configured stage and reviewer skills are actually installed.
---

# hive doctor

Checks that the skills your project is configured to use actually resolve to
installed slash-commands or skills on disk. It walks the `brainstorm` and `plan`
stage configs plus every entry in `review.reviewers`, verifies each one for its
agent, and prints a status table. Reach for it after setup or after changing
agents to confirm nothing is missing.

It runs the same checks automatically (non-fatally) at the end of `hive init`,
so install gaps surface as warnings without blocking setup.

## Usage

```bash
hive doctor
hive doctor --json
```

Run it from a hive-initialized project — it loads that project's
`.hive-state/config.yml`.

## Options

| Flag | What it does |
|------|--------------|
| `--json` | Emit the typed `hive-doctor` envelope (per-check rows plus a summary count) instead of the human table. |

## What it reports

- **Stage rows** — one per configured stage (`brainstorm`, `plan`), checking the
  skill that stage's agent will invoke.
- **Reviewer rows** — one per entry in `review.reviewers`, checking that
  reviewer's skill.
- **Dependency rows** — `tmux >= 3.0` when Claude runs in tmux mode, and a
  `wiki/qmd` row for initialized projects.

A missing stage/reviewer skill or an out-of-date tmux makes `doctor` exit
non-zero. The `wiki/qmd` check is **non-fatal**: a missing or broken QMD is
reported as a warning, since Hive falls back to plain wiki files.

## Examples

```bash
# Verify everything is installed after wiring up a new reviewer
hive doctor

# Get structured output to gate a setup script
hive doctor --json
```
