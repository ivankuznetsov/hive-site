---
title: tui
layout: default
parent: Command reference
nav_order: 3
permalink: /docs/commands/tui/
description: The interactive two-pane dashboard for watching tasks and driving every workflow verb with a keystroke.
---

# hive tui

The interactive dashboard. It's a two-pane terminal UI over `hive status`: a
left pane of your registered projects and a right pane of their tasks, each
showing an icon, id, name, stage, status, and age. It refreshes once a second
and lets you drive any workflow verb with a single keystroke. This is the
recommended way to watch and steer Hive day to day.

## Usage

```bash
hive tui
```

The TUI is human-only — it needs a real terminal and does not accept `--json`.
For machine-readable output, use
[`hive status --json`]({{ '/docs/commands/status/' | relative_url }}) instead.

## Layout

- **Left pane:** registered projects, with a `★ All projects` entry on top.
- **Right pane:** tasks for the selected scope, grouped by status, with a
  status icon and humanized age.

On terminals narrower than 70 columns the project pane is hidden and tasks take
the full width.

## Key bindings

| Key | Action |
|-----|--------|
| `Tab` / `Shift+Tab` | Toggle focus between the two panes. |
| `j` / `k` (or arrows) | Move the cursor within the focused pane. |
| `1`–`9` | Scope the right pane to the Nth project; `0` returns to all projects. |
| `Enter` | Contextual action on the selected task (edit waiting input, tail a running agent's log, open a red-status detail, or run the suggested command). |
| `b` `p` `d` `r` `P` `F` `a` | Run brainstorm / plan / develop / review / open-pr / finalize / archive on the selected task. |
| `n` | Capture a new idea (with an image-paste composer). |
| `i` | Open a read-only info panel for the selected task. |
| `o` | Open the task's folder in your editor for read-only browsing. |
| `s` | Manually steer a task — open it in the dev agent inside its worktree. |
| `z` | Open the archive pane (all done tasks, no age cutoff). |
| `X` | Drop the selected task (kills its agent, removes folders, worktree, branch — no undo). |
| `/` | Filter tasks by id, slug, or name. |
| `?` | Help overlay. |
| `q` / `Esc` | Quit, or back out of a sub-mode. |

## How it behaves

- Workflow verbs run in the background, so multiple agents across multiple
  projects run concurrently while the dashboard keeps painting.
- Pressing a verb key on a task whose agent is still running flashes a hint
  instead of dispatching, so you don't collide with a live run.
- Red (error / recovery) rows open a detail view that explains what went wrong
  and offers Hive's automatic recovery before you have to intervene.
- Done tasks older than three days are hidden from the grid; press `z` to see
  the full archive.

## Examples

```bash
# Open the dashboard
hive tui
```
