---
title: new
layout: doc
parent: Command reference
nav_order: 2
permalink: /docs/commands/new/
description: Capture a new task into the selected workflow's entry stage so you can move it through the process.
---

# hive new

Captures an idea into the selected workflow's entry stage. Hive turns your text
into a task folder, assigns it a stable id, and commits it to the state branch.
The entry stage and filename come from the workflow: the built-in coding
workflow starts at `1-inbox` with `idea.md`, while the editorial workflow below
starts at `1-brief` with `brief.md`.

## Usage

```bash
hive new <project> <text...>
hive new <project> --workflow <id> <text...>
```

`<project>` must already be registered with
[`hive init`]({{ '/docs/commands/init/' | relative_url }}). Everything after it
is the idea text, joined into a single description. Hive uses the project's
`default_workflow` unless `--workflow <id>` selects a built-in or
project-authored workflow for this task.

## Options

| Flag | What it does |
|------|--------------|
| `--workflow <id>` | Run this task through the named built-in or project-authored workflow. |
| `--depends-on <id-or-slug>` | Hold daemon advancement until a prerequisite task reaches the configured dependency gate. |
| `--json` | Accepted as a global flag, but Hive 0.6.5 still prints the human capture summary for `new`; do not expect a typed result. |

## What happens

- A readable slug is derived from your text (e.g. `add-inbox-filter-260603-abcd`).
- A task folder is created in the selected workflow's entry stage, using that
  stage's `state_file` to hold your text.
- The task gets a numeric id you'll see throughout `hive status` and the TUI.
- The capture is committed, and Hive starts generating a friendly display name
  in the background.

After capture, Hive prints the workflow-specific next step. For the built-in
coding workflow, the task starts at `1-inbox` in `idea.md` and advances to
brainstorm. For the editorial example, it starts at `1-brief` in `brief.md` and
advances to research. Follow the `next:` command Hive prints rather than
hard-coding a stage path.

```text
hive: captured <task>/<entry-state-file>
next: <workflow-specific transition/run command>
```

An entry-stage task is intentionally inert; nothing runs until you follow
Hive's printed transition and run its first active stage.

## Examples

```bash
# Capture an idea into the "hive" project
hive new hive "Add a filter to the inbox view so I can hide done tasks"

# Capture a quick bug report
hive new myapp "OAuth login redirects to a blank page on Safari"

# Use an owner-authored editorial workflow for this task
hive new myapp --workflow editorial "Explain the new import flow"
```

To capture an idea with images attached, use the new-idea composer inside
[`hive tui`]({{ '/docs/commands/tui/' | relative_url }}) (press `n`), which
supports pasting and drag-dropping image files.
