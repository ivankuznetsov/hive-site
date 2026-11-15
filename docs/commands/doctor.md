---
title: doctor
layout: doc
parent: Command reference
nav_order: 12
permalink: /docs/commands/doctor/
description: Preflight check that verifies your configured stage and reviewer skills are actually installed.
---

# hive doctor

Checks that the skills your project is configured to use actually resolve to
installed slash-commands or skills on disk. It walks the `brainstorm` and `plan`
stage configs, every entry in `review.reviewers`, any `review.adhoc.reviewers`,
the browser-test hook when `review.browser_test` is enabled, the patrol reviewers
when patrol is enabled, and Hive's own operating skill for each agent. It verifies
each one for its agent and prints a status table. Reach for it after setup or
after changing agents to confirm nothing is missing. It never installs anything
or writes agent state.

It runs the managed-skill part of these checks automatically (non-fatally) at the
end of `hive init`, so install gaps surface as warnings without blocking setup.
On a terminal, it also offers to provision any unresolved skills.

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
| `--json` | Emit the typed `hive-doctor.v2` envelope (managed-skill rows, legacy check rows, and a summary) instead of the human table. |

## What it reports

- **Stage rows** — one per configured stage (`brainstorm`, `plan`), checking the
  skill that stage's agent will invoke.
- **Reviewer rows** — one per entry in `review.reviewers`, plus any
  `review.adhoc.reviewers` and, when patrol is enabled, `patrol.review.reviewers`.
  Each checks that reviewer's skill.
- **Browser-test row** — present only when `review.browser_test.enabled` is true.
  It checks the `ce-test-browser` skill for that hook's agent.
- **Dependency rows** — an agent CLI that is not on your PATH shows as
  `unavailable`, which is a non-blocking warning. A `wiki/qmd` row appears when
  the project has `.llm-wiki/` context.
- **Configuration guidance** — obsolete `claude.mode` and MCP grant problems are
  reported. Claude stage execution no longer requires tmux in v0.8.0.
- **Other warnings** — an exported `ANTHROPIC_API_KEY` or `CLAUDE_API_KEY`, an
  unparseable `.hive-state/config.yml`, and web environment alias problems.

`doctor` exits 65 when a managed skill is missing, stale, incompatible, or
conflicting, or when the `runtime/sqlite` row is `missing`. It exits 78 for a
config error and 0 otherwise. Unresolved skill rows print the `hive setup-agents`
command that fixes them. Unavailable agent CLIs and warnings never change the exit
code. The `wiki/qmd` check is **non-fatal**: a missing or broken QMD is reported as
a warning, since Hive falls back to plain wiki files.

## Examples

```bash
# Verify everything is installed after wiring up a new reviewer
hive doctor

# Get structured output to gate a setup script
hive doctor --json
```
