---
title: new
layout: doc
parent: Command reference
nav_order: 2
permalink: /docs/commands/new/
description: Capture a new idea into a Hive project's inbox so you can move it through the pipeline.
---

# hive new

Captures an idea into a project's inbox. It turns your text into a task folder
under the `1-inbox` stage, assigns it a stable id, and commits it to Hive's
state branch. Use it from a terminal or an automation script.

## Usage

```bash
hive new <project> <text...>
```

`<project>` must already be registered with
[`hive init`]({{ '/docs/commands/init/' | relative_url }}). Everything after it
is the idea text, joined into a single description.

## What happens

- A readable slug is derived from your text (e.g. `add-inbox-filter-260603-abcd`).
- A task folder is created at `1-inbox/<slug>/` with an `idea.md` holding your text.
- The task gets a numeric id you'll see throughout `hive status` and the TUI.
- The capture is committed, and Hive starts generating a friendly display name
  in the background.

After capture, Hive prints the next step — move the task into the brainstorm
stage and run it:

```text
hive: captured <task>/idea.md
next: mv <task> <hive-state>/stages/2-brainstorm/ && hive run <id-or-task>
```

No agent runs inside `1-inbox`. An enrolled daemon can advance a ready task
automatically; the printed manual hint is useful when daemon dispatch is off.

## Examples

```bash
# Capture an idea into the "hive" project
hive new hive "Add a filter to the inbox view so I can hide done tasks"

# Capture a quick bug report
hive new myapp "OAuth login redirects to a blank page on Safari"
```

To capture an idea with images attached, use the new-idea composer inside
[`hive tui`]({{ '/docs/commands/tui/' | relative_url }}) (press `n`), which
supports pasting and drag-dropping image files.
