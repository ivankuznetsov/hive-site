---
title: Configuration
layout: doc
nav_order: 3
permalink: /docs/configuration/
description: Project configuration for agents, reviewers, patrol, services, budgets, and timeouts.
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
validated. An invalid value raises a configuration error. Arrays (like `review.reviewers`) are replaced
wholesale, never merged element-by-element.

## Claude permission mode

```yaml
claude:
  permission_mode: bypassPermissions
```

Claude-backed stages run as headless `claude -p` processes in v0.8.0. The old
`claude.mode` option is ignored; remove it when `hive doctor` warns. Follow
stage logs under `.hive-state/logs/<slug>/`.

- **`permission_mode`** — one of `acceptEdits`, `auto`, `bypassPermissions`,
  `default`, `dontAsk`, `plan`. `bypassPermissions` skips file-operation prompts
  (recommended for local runs); `auto` keeps Claude Code auto-mode rules.

## Agent profiles

Each stage runs on a named agent profile. The supported built-in profiles are
`claude` (default), `codex`, `grok`, `pi`, and opt-in `opencode`. OpenCode needs
an explicit provider/model and scoped configuration; see the
[OpenCode setup guide](https://github.com/ivankuznetsov/hive/blob/v0.8.0/docs/getting-started.md#optional-opencode-profile). You can point a stage at a different
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

## Budgets and timeouts
{: #token-cost-knobs-budgets--timeouts }

Claude budgets are **opt-in** in v0.8.0. Built-in defaults do not cap Claude;
existing project caps remain in force. The values below illustrate explicit
limits, not defaults or cost targets. Set limits appropriate to your work.

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

Choose a scan cadence with `mode`:

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
