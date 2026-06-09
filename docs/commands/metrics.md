---
title: metrics
layout: default
parent: Command reference
nav_order: 13
permalink: /docs/commands/metrics/
description: Report how often Hive fix-agent commits get reverted, optionally scoped by project and time window.
---

# hive metrics

Reports how often Hive's review fix-agent commits are later reverted — a quick
signal for whether automated fixes are sticking or getting backed out. Reach for
it when you want to gauge the quality of the fix pass across your projects.

## Usage

```bash
hive metrics rollback-rate [--days N] [--project NAME] [--json]
```

`rollback-rate` is the default, so plain `hive metrics` runs the same report.

## Options

| Flag | What it does |
|------|--------------|
| `--days N` | Only look at commits from the last `N` days. Must be a positive integer. |
| `--project NAME` | Limit the report to one registered project (matched by its registry name). |
| `--json` | Emit the typed `hive-metrics-rollback-rate` envelope instead of the text report. |

The report walks the git history of your registered projects, finds fix-agent
commits, detects which ones were later reverted, and groups the totals.

## Examples

```bash
# Rollback rate across every registered project
hive metrics rollback-rate

# Last 30 days, one project, as JSON
hive metrics rollback-rate --days 30 --project demo --json
```

The text output prints one section per project with total fix commits, the
reverted count, the rollback percentage, and grouped breakdowns. The `--json`
envelope carries the same numbers (`total_fix_commits`, `reverted_commits`,
`rollback_rate`, plus per-project grouping) for scripting.
