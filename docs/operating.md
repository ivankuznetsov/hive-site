---
title: Operating
layout: doc
nav_order: 5
permalink: /docs/operating/
description: Run the daemon, Telegram bot, and babysitter as services, and drive Hive from OpenClaw.
---

# Operating
{: .no_toc }

Manage the local web UI, daemon, experimental PR babysitter, and Telegram bot.
You can also drive the same workflows from a coding agent or OpenClaw.

1. TOC
{:toc}

## Native setup and local web UI

On supported Linux and macOS installations, `hive setup` provisions Hive-owned
dependencies and the per-user daemon, babysitter, and local web service. It
previews changes and asks for confirmation; non-interactive setup needs
`--yes`. Project enrollment is configured separately with `hive init`.

```bash
hive setup
hive web status       # inspect readiness and open the reported URL
hive tui              # optional terminal interface to the same projects
```

The default web service is loopback-only at `http://127.0.0.1:4567`. Setup does
not publish it to the internet. `hive setup --no-service` skips changes to the
web service; `hive web` runs a foreground web server when you want that mode.
See the [web service reference for v0.8.0](https://github.com/ivankuznetsov/hive/blob/v0.8.0/README.md#hive-web-default-native-experience).

Hivebox is discontinued as of v0.8.0. Existing images receive no new builds;
use native installation (WSL with systemd on Windows). HiveDev is a separate
hosted product, currently [accepting waitlist signups](https://hivedev.ai/).

## The daemon

The daemon advances ready stages for enrolled projects and stops at
human-input or recovery gates. It's installed as a **per-user service** — systemd-user on Linux, launchd on macOS —
and provisioned by `hive setup`. Per-project config only decides whether
**that** project is picked up.

```bash
hive daemon install     # write + enable the per-user service (idempotent; repairs autostart)
hive daemon status      # is it running?
hive daemon start --detach   # start once in the background while troubleshooting
hive daemon tail        # follow the daemon log
hive daemon stop
hive daemon disable my-project   # stop dispatching for one project (or --all)
```

Enroll or unenroll a project by editing its `.hive-state/config.yml`
(`daemon.enabled`) — see [Configuration]({{ '/docs/configuration/' | relative_url }}#daemon-enrollment).
Full reference: [`daemon`]({{ '/docs/commands/daemon/' | relative_url }}).

### Before unattended operation
{: #before-you-go-live-the-dry-run-shakedown }

Hive is token-heavy and acts on real repositories. Use `--dry-run` on a project
before letting the daemon drive it unattended, watch the queue in
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
openclaw skills install @ivankuznetsov/hive-cli
```

Public listing: <https://clawhub.ai/ivankuznetsov/skills/hive-cli>.
That installs the `/hive` slash command. Run the guided setup:

```text
/hive setup
```

Guided setup verifies `hive` or `hv`. If neither is installed, it offers an
install through the documented channel and asks before changing user-global
software. After approval it runs `hive setup --no-init --yes --json`, which
provisions the daemon and the local web service without enrolling a project.
Changes to the managed Claude, Codex, and Pi skills need a separate approval
(`hive setup-agents --yes --json`). Enroll a project yourself with `hive init .`
in your own terminal. After setup, pass Hive commands through `/hive …`, e.g.
`/hive status --operational --json`, `/hive new . "build this feature"`,
`/hive review <slug>`.
