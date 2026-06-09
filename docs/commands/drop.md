---
title: drop
layout: default
parent: Command reference
nav_order: 16
permalink: /docs/commands/drop/
description: Permanently delete an active task — its worktree, branch, stage folders, and logs. There is no undo.
---

# hive drop

Permanently deletes an active task. It stops any running agent for that task,
closes the draft PR if one is open, removes the task's worktree and branch,
deletes the task folder from every active stage, removes its logs, and records
an audit entry. There is no archive, no undo, and no confirmation prompt — reach
for it when you want a task gone for good.

## Usage

```bash
hive drop TARGET [--project NAME] [--from STAGE] [--json]
```

`TARGET` can be a task slug or a full path to the task folder.

## Options

| Flag | What it does |
|------|--------------|
| `--project NAME` | Disambiguate when the same slug exists in more than one project. |
| `--from STAGE` | Assert the task's current stage (e.g. `4-execute`); the drop fails if it doesn't match. Useful on retries. |
| `--json` | Emit the typed `hive-drop` envelope reporting exactly what was cleaned up. |

## Behavior notes

- Tasks already in `9-done` are archive records — `drop` refuses them and leaves
  the folder untouched.
- If `gh` isn't installed, closing the draft PR is skipped silently; the rest of
  the drop still succeeds.
- Drop is idempotent: if a previous run was interrupted, re-running it converges.
  Already-missing processes, folders, worktrees, branches, and PRs are treated as
  done.

## Examples

```bash
# Drop a task by slug
hive drop my-task-260522-abcd

# Disambiguate by project and assert the current stage
hive drop my-task-260522-abcd --project demo --from 4-execute

# Drop by full path and capture the result as JSON
hive drop /path/to/.hive-state/stages/4-execute/my-task-260522-abcd --json
```

In the [`hive tui`]({{ '/docs/commands/tui/' | relative_url }}) dashboard,
`Shift+X` drops the focused task using this command.
