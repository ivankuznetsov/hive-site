---
title: Changelog
layout: doc
nav_order: 20
permalink: /docs/changelog/
description: What changed in Hive, grouped by the work you do.
---

# Changelog

## Hive 0.7.3

Hive 0.7.3 makes it easier to see what your agents are doing, review their work, and keep tasks moving when a provider or process fails.

### A clearer, faster web workspace

- Open a task workspace with its progress, conversation, artifacts, and review context in one place. Running work, waiting decisions, and final outcomes are easier to distinguish.
- See the last saved board immediately after a web restart while Hive refreshes it in the background. A dated loading notice explains what is happening; task actions become available once the status is fresh.
- Navigate more comfortably on phones, keep Kanban columns readable, and collapse board clutter without losing the current task state.
- Find installable workflows and modules together under **Honeycombs**.
- Answer waiting brainstorm questions reliably, including after status updates and reconnects.

### A daily record of your work

- Read a daily digest in Hive web or with `hive digest`, with project activity, task and PR outcomes, and items needing attention.
- Filter by project or revisit a recorded day. Late updates and gaps remain visible instead of silently rewriting the day's history.
- Enable scheduled collection and optional Telegram delivery when you want them. Digests are opt-in; installing this release does not turn them on or backfill days before collection began.

### More reliable unattended work

- Recover more reliably after interrupted agents, daemon restarts, rewritten PRs, stale reviews, and provider limits. Valid review progress is preserved across retries.
- Keep queued work moving fairly as capacity changes, without repeated dispatches or stale recovery records occupying available slots.
- Get fresher status with less scanning of completed tasks and historical attempt data. Numeric task lookup goes directly to the task's folder.
- Cancel unwanted tasks through the cancellation flow, so removing a task does not mark it as successfully delivered.
- Keep execution pauses actionable. Missing optional screenshots or other best-effort evidence no longer stalls otherwise valid work.

### Planning, review, and Patrol

- Have coding plans critiqued before execution, with automatic recovery for failed or interrupted reviews and clearer escalation when your input is needed.
- Check completed work against outcome evidence, returning implementation defects to execution while keeping optional capture failures nonblocking.
- Route ordinary and architecture Patrol findings through the same fix workflow. Resume interrupted fixes and retire rejected, obsolete, or externally completed work more reliably.
- Park publications blocked by detected secrets for attention instead of repeatedly trying to publish them. Secret scanning is bundled, and publication diagnostics omit URL credentials.
- Stop silent validation and CI processes at their idle deadline, and handle hosted CI account limits without repeatedly hammering the service.

### Agents and benchmarks

- Use OpenCode as a first-class agent, with runtime discovery, permissions, session output, and provider-limit recovery integrated into Hive.
- Run Pi workflows more reliably through rate limits and review stages. Claude quota detection and Grok provider-limit handling also improve.
- Trusted workflow agents retain their ordinary environment; workflow restrictions are opt-in.
- Run benchmarks with stronger checks before paid execution and judging. A failed planner stops the run, command arguments are preserved, and judges receive the correct candidate output.

### Installation and upgrading

- Repeating a systemd user-service installation is safer. Managed QMD installation and packaged web dependencies also receive fixes.
- Runtime status identifies the exact active dogfood build, making it easier to confirm which version the CLI, daemon, and web are using.
- **Older installations need attention before upgrading.** Hive now supports current state formats only. Automatic historical migrations, `hive migrate`, and `hive runtime resume` have been removed. Back up retained state and follow the [current-format conversion guide](https://github.com/ivankuznetsov/hive/blob/v0.7.3/docs/guides/current-format-migration.md) before using an older installation with this release. Healthy databases already using the current format need no conversion.

[Full technical changelog](https://github.com/ivankuznetsov/hive/blob/v0.7.3/docs/releases/0.7.3-technical.md) · [All changes since 0.7.2](https://github.com/ivankuznetsov/hive/compare/v0.7.2...v0.7.3)

[Earlier releases](https://github.com/ivankuznetsov/hive/releases)
