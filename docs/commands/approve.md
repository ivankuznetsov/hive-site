---
title: approve
layout: doc
parent: Command reference
nav_order: 6
permalink: /docs/commands/approve/
description: Advance a task to the next stage with marker checks, locking, and an atomic move-and-commit.
---

# hive approve

Moves a task from one stage to the next and records it on Hive's state branch.
It's the safe, agent-callable equivalent of manually `mv`-ing a task folder
into the next stage directory — same effect, plus a marker check that stops you
advancing unfinished work, idempotency assertions, locking, and an atomic
move-and-commit that rolls back if the commit fails.

## Usage

```bash
hive approve <slug>                 # advance current stage -> next stage
hive approve <slug> --to <stage>    # move to an explicit stage (forward or back)
hive approve <slug> --from <stage>  # assert the current stage before advancing
hive approve <slug> --project <name>
hive approve <slug> --force
hive approve <slug> --json
```

Stages accept either the full name (`3-plan`) or the short suffix (`plan`).

## Options

| Flag | What it does |
|------|--------------|
| `--to <stage>` | Move to an explicit destination. Backward moves (e.g. back to `3-plan`) are the recovery lever and skip the marker check. |
| `--from <stage>` | Assert the task is at this stage before moving — pass it on retries so a network blip can't silently double-advance the task. |
| `--project <name>` | Disambiguate a slug that exists in more than one project. |
| `--force` | Bypass the "must be complete" check on a forward move. |
| `--json` | Emit the typed `hive-approve` envelope on both success and failure. |

## How advancing works

A normal forward move requires the task to be complete — Hive only advances
tasks whose stage finished cleanly. If the task isn't ready, approve refuses and
tells you the current marker so you know why. Backward moves with `--to` don't
require a marker, which is how you send a task back to an earlier stage to
recover from a crash.

If the destination is the stage the task is already in, approve reports a no-op
and changes nothing.

## Examples

```bash
# Advance a finished brainstorm into the plan stage
hive approve add-inbox-filter-260603-abcd

# Idempotent advance an agent can safely retry
hive approve add-inbox-filter-260603-abcd --from 2-brainstorm --json

# Send a task back to planning after an execute crash
hive approve add-inbox-filter-260603-abcd --to 3-plan
```

To run the stage a task is currently in, see
[`hive run`]({{ '/docs/commands/run/' | relative_url }}); to see which tasks are
ready to approve, see
[`hive status`]({{ '/docs/commands/status/' | relative_url }}).
