---
title: Configuration
layout: default
nav_order: 3
permalink: /docs/configuration/
description: Project config, patrol mode, reviewers, agent profiles, the daemon, and token-cost knobs.
---

# Configuration
{: .no_toc }

Hive reads two YAML files. Most of what you'll tune lives in the per-project
file that `hive init` creates.

1. TOC
{:toc}

## The two config files

| File | Scope | Holds |
|------|-------|-------|
| `~/.config/hive/config.yml` | Global | Registered projects and bot settings (allowlist, voice transcription). |
| `<project>/.hive-state/config.yml` | Per-project | Default branch, worktree root, budgets, timeouts, stage agents, reviewers, daemon enrollment, patrol, and babysitter settings. |

Per-project values are deep-merged onto Hive's built-in defaults, then
validated. A bad value raises a clear config error rather than failing later —
so it's safe to edit and re-run. Arrays (like `review.reviewers`) are replaced
wholesale, never merged element-by-element.

## Launch & permission mode

```yaml
claude:
  mode: tmux                 # tmux (default) or headless
  permission_mode: bypassPermissions
```

- **`mode`** — `tmux` runs Claude-backed stages in attachable tmux sessions
  using your logged-in session; `headless` uses non-interactive spawns (good for
  service-only hosts).
- **`permission_mode`** — one of `acceptEdits`, `auto`, `bypassPermissions`,
  `default`, `dontAsk`, `plan`. `bypassPermissions` skips file-operation prompts
  (recommended for local runs); `auto` keeps Claude Code auto-mode rules.

## Agent profiles

Each stage runs on a named agent profile. The three built-in profiles are
`claude` (default), `codex`, and `pi`. You can point a stage at a different
agent, and override a profile's binary, env var, or minimum version:

```yaml
plan:    { agent: claude }
execute: { agent: codex }    # the rendered template recommends codex for execute

agents:
  codex:
    bin: codex
    env_override: HIVE_CODEX_BIN
    min_version: "0.125.0"
```

## Token-cost knobs: budgets & timeouts

These are **generous sanity caps for runaway agents, not cost targets**. Lower
them if you want a tighter ceiling per stage.

```yaml
budget_usd:
  brainstorm: 50
  plan: 100
  execute_implementation: 500
  review_fix: 500
  # …

timeout_sec:
  brainstorm: 1800
  plan: 3600
  execute_implementation: 14400
  # …
```

## Reviewers

The `6-review` stage runs a configurable set of reviewers. A fresh `hive init`
ships a populated, recommended list; you can add, remove, or reorder entries.
Each reviewer needs a unique `name` and `output_basename` (the basename keeps
concurrent review files from colliding).

```yaml
review:
  reviewers:
    - { name: claude-ce-code-review, agent: claude, output_basename: claude-ce-code-review }
    - { name: codex-ce-code-review,  agent: codex,  output_basename: codex-ce-code-review }
  triage: { enabled: true, agent: claude, bias: courageous }
  fix:    { agent: claude }
  max_passes: 2
  max_wall_clock_sec: 5400
```

## Patrol

Patrol is autonomous repository patrol: it maps feature slices, reviews them,
validates fixes, and opens PRs for the ones that pass. **Patrol is opt-in** — a
project with no patrol config, or a patrol section without an explicit `mode:`,
stays disabled.

Set a single `mode` dial instead of hand-tuning knobs:

```yaml
patrol:
  mode: medium    # ultrapatrol | high | medium | low | off
```

| Mode | Cadence |
|------|---------|
| `ultrapatrol` | Timer, every 30 min |
| `high` | Timer, every 2 h |
| `medium` | Timer, every 4 h |
| `low` | On new commits (baseline SHA-check cadence) |
| `off` | Disabled |

`hive init` offers `medium` as the suggested starting mode, but that's only a
prompt default — it's never applied unless you accept it (or set `mode:`
yourself). Patrol scans are **per-project**: each project runs at most one scan
at a time, and different projects patrol in parallel rather than competing for a
single global slot. See the [`patrol`]({{ '/docs/commands/patrol/' | relative_url }})
command page.

## Daemon enrollment

The daemon is global autostart infrastructure; per-project config only decides
whether **this** project is picked up for dispatch, and bounds concurrency:

```yaml
daemon:
  enabled: true
  max_concurrent_runs: 1          # task-dispatch slots for this project
  max_concurrent_patrol_scans: 1  # separate per-project cap for patrol scans
```

Patrol scans run on a **separate** in-flight budget from task dispatch, so a
long scan never consumes a task slot.

## Babysitter (experimental)

The PR babysitter keeps open PRs green and mergeable. It's opt-in and off by
default:

```yaml
babysitter:
  enabled: false
  interval: 10m
  max_concurrent_prs: 2
  labels_ignore: [wip, do-not-merge, draft]
  budget_minutes: 30
  budget_usd: 50
```

See [`babysit`]({{ '/docs/commands/babysit/' | relative_url }}) and
[Operating]({{ '/docs/operating/' | relative_url }}).

## Telegram bot

Global bot settings live in `~/.config/hive/config.yml`:

```yaml
bot:
  enabled: true
  chat_id_allowlist:
    - 123456789
```

Voice-note capture reads an OpenAI-compatible transcription key from the
environment (e.g. `HIVE_WHISPER_API_KEY`); the key is never written into config.
Full setup is on the [`bot`]({{ '/docs/commands/bot/' | relative_url }}) page.
