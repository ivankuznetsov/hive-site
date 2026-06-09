---
title: status
layout: doc
parent: Command reference
nav_order: 4
permalink: /docs/commands/status/
description: Show the live state and next useful action for every task across your registered projects.
---

# hive status

Reports the current stage and next useful action for every task across your
registered projects, grouped by what needs to happen next. This is what the
dashboard renders and what an agent reads to decide what to do. It is read-only
and never changes anything.

## Usage

```bash
hive status
hive status --json
hive status --diagnose <slug>
```

## Options

| Flag | What it does |
|------|--------------|
| `--json` | Emit the typed status payload (every task row, with slug, id, name, stage, timestamps, and recovery hints) instead of the human table. |
| `--diagnose <slug>` | Print a focused diagnosis of one red row (why it's stuck and what Hive can do). Read-only. |
| `--write` | With `--diagnose`, let the dev agent write a `diagnostics/red-status.md` for the task. This is the only mutating mode. |
| `--project <name>` | Scope `--diagnose` to one registered project. |
| `--stage <stage>` | Scope `--diagnose` when the same slug exists in multiple stages. |

## Output

Tasks are grouped under headers like "Ready to brainstorm", "Ready to develop",
and "Agent running". Empty groups are hidden. Each row shows a status icon, the
task id and display name, its current state, the suggested command, and how
long ago it last changed.

| Icon | Meaning |
|------|---------|
| `·` | No marker yet (fresh capture). |
| `⏸` | Waiting for you. |
| `✓` | Complete — ready to advance. |
| `🤖` | An agent is actively running. |
| `⚠` | Stale or errored — needs recovery. |

The human view hides done tasks older than three days (with a count summary);
`hive status --json` always lists every task so daemons and agents see the full
picture. Use [`hive tui`]({{ '/docs/commands/tui/' | relative_url }}) for the
interactive version.

## Examples

```bash
# Which tasks are waiting for me?
hive status

# Full machine-readable snapshot for an agent or script
hive status --json

# Why is this task red?
hive status --diagnose add-inbox-filter-260603-abcd
```
