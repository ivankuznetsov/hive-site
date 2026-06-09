---
title: Operating
layout: doc
nav_order: 5
permalink: /docs/operating/
description: Run the daemon, Telegram bot, and babysitter as services, and drive Hive from OpenClaw.
---

# Operating
{: .no_toc }

Day-2 guide for running Hive's background services — the daemon, the
experimental PR babysitter, and the Telegram bot — plus driving Hive from a
coding agent.

1. TOC
{:toc}

## The daemon

The daemon is the worker: it polls `hive status --json` and dispatches workflow
verbs for enrolled projects, stopping at human-input or recovery gates. It's
installed as a **per-user service** — systemd-user on Linux, launchd on macOS —
and enabled by default at install time. Per-project config only decides whether
**that** project is picked up.

```bash
hive daemon install     # write + enable the per-user service (idempotent; repairs autostart)
hive daemon status      # is it running?
hive daemon start --detach   # start once in the background while troubleshooting
hive daemon tail        # follow the daemon log
hive daemon stop
hive daemon disable     # stop and remove autostart
```

Enroll or unenroll a project by editing its `.hive-state/config.yml`
(`daemon.enabled`) — see [Configuration]({{ '/docs/configuration/' | relative_url }}#daemon-enrollment).
Full reference: [`daemon`]({{ '/docs/commands/daemon/' | relative_url }}).

### Before you go live: the dry-run shakedown

Hive is token-heavy and acts on real repositories. Do a `--dry-run` shakedown
on a project before letting the daemon drive it unattended, watch the queue in
`hive tui`, and keep budgets/timeouts (and patrol/babysitter enrollment)
conservative until you trust the loop. If costs run away, `hive daemon stop`
halts dispatch immediately.

## The Telegram bot

The bot notifies you, shows the queue, and accepts approvals from your phone.
It uses long polling, so there's **no webhook, public URL, or tunnel** to set
up.

1. Create a bot with `@BotFather` (`/newbot`) and copy the token.
2. Message your new bot once (`/start`) so Telegram exposes your chat id.
3. Get your numeric chat id from `getUpdates` (see the [`bot`]({{ '/docs/commands/bot/' | relative_url }}) page for the exact command).
4. Allow that chat in `~/.config/hive/config.yml`:

   ```yaml
   bot:
     enabled: true
     chat_id_allowlist:
       - 123456789
   ```

5. Start it:

   ```bash
   hive bot start
   hive bot status --json
   ```

Then send `/help`, `/status`, or `/queue` in Telegram. Voice-note idea capture
needs an OpenAI-compatible transcription key in the environment (e.g.
`HIVE_WHISPER_API_KEY`); it's read from the environment and never written into
config. If a token leaks, rotate it in `@BotFather` with `/revoke` and restart
the bot.

## The PR babysitter (experimental)

`hive babysit` watches your open PRs and keeps them green and mergeable: it runs
bounded agent-repair attempts in isolated worktrees, auto-rebases green-but-behind
PRs onto a moving `main`, and hands off to a human when it can't fix one (drafts
and conflicts are left alone). It's off by default and enabled per project. See
[`babysit`]({{ '/docs/commands/babysit/' | relative_url }}).

## Updating & uninstalling

```bash
hive update --dry-run   # print the would-be command for your install channel
hive update             # delegates to the installing channel (brew / yay / install.sh)
hive uninstall          # removes registrations/config/cache, preserves your work
hive uninstall --purge  # non-interactive; still preserves work
```

Project state stays at `<project>/.hive-state/`; install and uninstall never
move completed pipeline work. See [`update`]({{ '/docs/commands/update/' | relative_url }})
and [`uninstall`]({{ '/docs/commands/uninstall/' | relative_url }}).

## Drive Hive from a coding agent

Hive's other primary surface is a coding agent — Claude Code, Codex, Pi, or
anything that can run shell commands and read output. Every workflow verb
supports `--json` and emits a typed envelope, so an agent parses structured
output instead of scraping text:

```text
Run hive status --json and tell me which tasks are waiting for me.
Run hive new your-project "<title>" and report the slug it printed.
Run hive review <slug> --json and summarize the resulting envelope.
```

`hive tui` is intentionally human-only and rejects `--json` — use the CLI verbs
and `hive status --json` for programmatic use.

### OpenClaw `/hive` skill

Hive publishes one OpenClaw skill through ClawHub:

```bash
openclaw skills install hive-cli
```

Public listing: <https://clawhub.ai/ivankuznetsov/hive-cli>. That installs the
`/hive` slash command. Run the guided setup:

```text
/hive setup
```

It installs the Hive CLI through the documented channel, verifies `hive`/`hv`,
runs `hive daemon install`, and optionally initializes the current project.
After setup, pass Hive commands through `/hive …`, e.g. `/hive status --json`,
`/hive new . "build this feature"`, `/hive review <slug>`.
