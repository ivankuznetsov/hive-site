---
title: bot
layout: doc
parent: Command reference
nav_order: 11
permalink: /docs/commands/bot/
description: Telegram bot for approving, answering, and capturing ideas from your phone.
---

# hive bot

Runs the Telegram mobile surface for Hive. It long-polls Telegram, shows your
actionable tasks with inline buttons, lets you approve stages and answer
brainstorm questions in chat, and captures new ideas (including photos,
documents, and transcribed voice notes). Reach for it when you want to drive
Hive from your phone while away from a laptop.

The bot is not a second approval engine — it dispatches the same workflow verbs
the [daemon]({{ '/docs/commands/daemon/' | relative_url }}) and CLI already use.
It only responds to chat IDs on your allowlist.

## Usage

```bash
hive bot install [--force]
hive bot start [--foreground] [--dry-run]
hive bot status
hive bot tail
hive bot reload
hive bot stop
```

## Subcommands

| Subcommand | What it does |
|------------|--------------|
| `install` | Installs and enables the autostart service (systemd-user on Linux, launchd on macOS) and starts the bot now. This is the recommended way to run it. `--force` overwrites an existing unit (the previous one is backed up). |
| `start` | Starts the bot manually. Daemonizes by default; `--foreground` stays attached for debugging; `--dry-run` parses Telegram and sends notifications but reports child dispatches instead of running them. |
| `status` | Reports running / not-running plus uptime, PID, log path, and autostart-service state. |
| `tail` | Follows the bot log. |
| `reload` | Reloads `config.yml` at the next loop boundary. Does not re-read the token file — restart after rotating tokens. |
| `stop` | Gracefully stops the bot. Idempotent. |

`stop`, `status`, `reload`, and `install` accept `--json` and emit a typed
envelope.

## Commands in Telegram

Once running, the bot understands these chat commands (also shown in the `/`
quick-actions menu):

| Command | What it does |
|---------|--------------|
| `/status [project]` | Lists actionable tasks as `Title — Stage`, with inline action buttons. Pass `--json` for the raw status envelope. |
| `/queue` | Same actionable view, all projects. |
| `/idea [text]` | Starts a new inbox idea. Works with photos, documents, and captions too. |
| `/answer <slug>` | Answers brainstorm questions for a task, by typed reply or voice note. |
| `/approve <slug>` | Approves and advances a task. |
| `/autofix <slug>` | Runs the recovery sequence for a recoverable failure. |
| `/details <slug>` | Shows diagnostic details for a task. |
| `/done` | Ends the active brainstorm conversation. |
| `/help` | Lists the supported commands. |

You can also tap inline buttons (approve, answer, autofix, details) on status
and notification messages instead of typing commands.

## Configuration

The bot is global, configured under `bot:` in your global `config.yml`:

```yaml
bot:
  enabled: false
  chat_id_allowlist: [123456789]
  poll_interval_sec: 30
  transcription:
    enabled: true
    model: whisper-1
    api_key_env: HIVE_WHISPER_API_KEY
    supported_languages: [en, ru]
```

`HIVE_TELEGRAM_BOT_TOKEN` is the only supported token source — a missing token
or empty allowlist makes `hive bot start` fail. The token and the Whisper API
key can be placed in `~/.config/hive/.env`, which the bot loads at start:

```
HIVE_TELEGRAM_BOT_TOKEN=123456789:AAAAa-BBBb-CCCC
HIVE_WHISPER_API_KEY=sk-...
```

Voice transcription uses an OpenAI-compatible Whisper endpoint (not OpenRouter,
which has no audio endpoint); it is config-overridable to any compatible
deployment.

## Examples

```bash
# Recommended: install once, autostart handles the rest
hive bot install
hive bot status

# Manual / debug run
hive bot start --foreground
```

See [Operating]({{ '/docs/operating/' | relative_url }}) for running the bot as
a service alongside the daemon.
