---
title: findings
layout: default
parent: Command reference
nav_order: 7
permalink: /docs/commands/findings/
description: List and toggle the reviewer's findings so accepted ones feed the next implementation pass.
---

# hive findings

Lists the review findings the reviewer wrote for a task and lets you accept or
reject each one without hand-editing the review file. Accepting a finding
re-injects it into the next implementation pass; rejecting it drops it back out.

Findings are stored as markdown checkboxes in the task's review file. `hive
findings` reads them, and `hive accept-finding` / `hive reject-finding` flip the
checkboxes for you, with safe atomic writes and locking so they never race a
running task.

## Usage

```bash
hive findings <slug>                  # list findings of the latest review pass
hive findings <slug> --pass 1         # a specific pass
hive findings <slug> --json           # machine-readable output

hive accept-finding <slug> 1 3 5      # accept findings by ID
hive accept-finding <slug> --severity high   # accept all High findings
hive accept-finding <slug> --all      # accept everything

hive reject-finding <slug> 2          # reject finding 2
hive reject-finding <slug> --severity nit    # reject all Nit findings
```

IDs are 1-based and assigned in the order findings appear in the review file.

## Options

| Flag | What it does |
|------|--------------|
| `--pass N` | Target a specific review pass instead of the latest. |
| `--stage <stage>` | Disambiguate when the same slug exists in more than one stage. |
| `--project <name>` | Resolve the slug in a specific registered project. |
| `--severity <level>` | (accept/reject) Select every finding of that severity, e.g. `high`, `medium`, `nit`. |
| `--all` | (accept/reject) Select every finding in the file. |
| `--json` | Emit the typed `hive-findings` envelope instead of the human table. |

## Examples

```bash
# Review what the reviewer flagged, then accept the high-severity items
hive findings fix-login-bug
hive accept-finding fix-login-bug --severity high

# Accept two specific findings and get JSON back for scripting
hive accept-finding fix-login-bug 1 4 --json
```

After accepting findings, the next development pass (`hive develop <slug>`)
picks them up automatically.
