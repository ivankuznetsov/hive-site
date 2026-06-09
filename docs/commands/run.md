---
title: run
layout: default
parent: Command reference
nav_order: 5
permalink: /docs/commands/run/
description: The low-level dispatcher that executes whatever stage a task is currently in.
---

# hive run

The low-level dispatcher. It resolves a task, figures out which stage it's in,
auto-rebases the worktree onto the latest default branch when needed, runs that
stage's agent, commits the result, and reports the next step. Most of the time
you'll reach for the friendlier stage verbs
(`hive brainstorm | plan | develop | open-pr | review | finalize | archive`)
or [`hive tui`]({{ '/docs/commands/tui/' | relative_url }}) — `hive run` is what
they call underneath, and what you use for recovery or scripting.

## Usage

```bash
hive run <slug>
hive run <slug> --project <name>
hive run <slug> --stage <stage>
hive run <slug> --json
hive run <slug> --no-rebase
```

You can also pass an exact task-folder path instead of a slug.

## Options

| Flag | What it does |
|------|--------------|
| `--project <name>` | Disambiguate when the same slug exists in more than one project. |
| `--stage <stage>` | Disambiguate when the same slug exists in more than one stage. |
| `--no-rebase` | Skip the auto-rebase pre-step for this run only. |
| `--json` | Emit the typed `hive-run` envelope (current marker, a `rebase` block, and a `next_action` hint) instead of human text. |

## Auto-rebase

Before running an execute, open-pr, review, artifacts, or finalize stage,
`hive run` checks whether the task's branch has fallen behind the default branch
and rebases it if so. This stops reviewers from seeing "phantom" deletions of
code that landed on main after the branch was created. If the rebase hits
conflicts, Hive dispatches the project's dev agent to resolve them; if anything
goes wrong it aborts cleanly and continues against the old base (fail-soft). Use
`--no-rebase` for a one-off skip, or set `rebase.enabled: false` in the
project's config to turn it off permanently.

## Examples

```bash
# Run whatever stage this task is currently in
hive run add-inbox-filter-260603-abcd

# Recover a stuck task without the rebase ceremony, machine-readable
hive run add-inbox-filter-260603-abcd --no-rebase --json

# Disambiguate a slug shared across two projects
hive run fix-login --project myapp
```

When a task is complete and ready to advance,
[`hive approve`]({{ '/docs/commands/approve/' | relative_url }}) moves it to the
next stage.
