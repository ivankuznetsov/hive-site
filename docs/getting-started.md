---
title: Getting started
layout: doc
nav_order: 1
permalink: /docs/getting-started/
description: Install Hive, attach it to a project with hive init, and run your first task in the TUI.
---

# Getting started
{: .no_toc }

This walks you from nothing to watching Hive carry your first idea toward a
pull request. The happy path is **daemon-first**: the daemon advances ready
tasks, and the TUI is where you watch the queue and answer only when Hive needs
you. You do not need to learn the stage commands on day one.

1. TOC
{:toc}

## Prerequisites

Hive is a power-user, token-heavy CLI — see [Is Hive for you?](/#fit) if you
haven't yet. You'll need:

- **Ruby 3.4** — the gem and its runtime deps install against this.
- **git ≥ 2.40** and an authenticated **`gh`** (GitHub CLI).
- An authenticated **`claude`** (≥ 2.1.118), and **`codex`** (≥ 0.125.0) for the
  default execute agent.
- **`tmux` ≥ 3.0** when the project uses the default `claude.mode: tmux`.
- **Node.js / npm** for the managed QMD wiki indexer (optional; `hive doctor`
  reports the gap non-fatally if it's missing).

## 1. Install

Hive ships as the `hive-cli` rubygem attached to each GitHub Release, signed
with cosign keyless attestation. Each channel downloads the same `.gem`,
verifies the signature, and runs `gem install`.

```bash
# macOS (arm64)
brew install ivankuznetsov/hive/hive

# Arch Linux (x86_64 / aarch64)
yay -S hive-bin

# glibc Linux (Ubuntu 22.04+, x86_64 / aarch64) — pin to the release tag
tmpdir="$(mktemp -d)" && trap 'rm -rf "$tmpdir"' EXIT \
  && curl -fsSL https://raw.githubusercontent.com/ivankuznetsov/hive/v{{ site.hive_version }}/install.sh \
       -o "$tmpdir/hive-install.sh" \
  && bash "$tmpdir/hive-install.sh"
```

The `install.sh` channel runs `hive daemon install` for you. Homebrew and AUR
print a one-line reminder to run it once. Either way the per-user daemon service
(systemd-user on Linux, launchd on macOS) ends up enabled by default.

Verify:

```bash
hive --version
```

If Apache Hive already owns the `hive` name on your `PATH`, use the `hv` shim
that the install channels create — every command below works as `hv …` too.

> **Prefer to have an agent do it?** Hive publishes an OpenClaw `/hive` skill
> and a canonical agent-installer prompt. See
> [Operating]({{ '/docs/operating/' | relative_url }}#openclaw-hive-skill).

## 2. Attach Hive to a project

```bash
cd ~/Dev/your-project
hive init .
```

`hive init` asks a few questions:

- **Claude launch mode** — `tmux` (default) runs Claude-backed stages in
  attachable tmux sessions using your logged-in Claude session; `headless` uses
  non-interactive spawns for service-only hosts or CI-style runs.
- **Permission mode** — `bypassPermissions` (recommended) so local runs don't
  pause on file-operation approvals; choose `auto` for Claude Code auto-mode
  rules.
- **Daemon enrollment** — keep the project enabled so the daemon picks it up.

See the [`init`]({{ '/docs/commands/init/' | relative_url }}) command page for
every prompt and flag, and [Configuration]({{ '/docs/configuration/' | relative_url }})
for what it writes.

## 3. Open the dashboard

```bash
hive daemon status   # should say running
hive tui
```

If the daemon isn't running yet, run `hive daemon install` to repair autostart,
or start it once with `hive daemon start --detach` while you troubleshoot. In
the TUI, the left pane is your registered projects; the right pane is the live
queue.

## 4. Capture one rough idea

In the TUI, press **`n`**, choose the project if Hive asks, type the thing you
want built or investigated, and press **Enter**. The new row starts in
`1-inbox`, backed by an `idea.md` file under `.hive-state/`.

Prefer the command line?

```bash
hive new . "a Telegram bot that sends a daily digest of what was shipped"
```

## 5. Watch Hive move it forward

Leave the TUI open. The daemon picks up the new row, turns the idea into
`brainstorm.md`, promotes completed work into `plan.md`, and keeps moving
through the pipeline while each stage is ready. Long stages show as running;
completed stages leave files behind for the next stage and for you.

## 6. Answer only when Hive asks

When a row says it needs input, highlight it and press **Enter**. Hive opens the
right markdown file in your editor. Fill in the answer blocks, save, and close
the editor. The daemon sees the edit, waits for the file to settle, and
continues the task automatically.

That's the whole loop: a rough idea becomes durable stage files, then Hive keeps
advancing the same task toward code, a pull request, review, and archive.

## Where to go next

- **[Concepts]({{ '/docs/concepts/' | relative_url }})** — why it's shaped this way: folder-as-agent, the nine stages, the marker protocol.
- **[Configuration]({{ '/docs/configuration/' | relative_url }})** — patrol, reviewers, agent profiles, budgets, and the daemon.
- **[Command reference]({{ '/docs/commands/' | relative_url }})** — drive any stage by hand, or script Hive from an agent.
- **[Operating]({{ '/docs/operating/' | relative_url }})** — run the daemon, Telegram bot, and babysitter as services.
- **[Custom workflows]({{ '/docs/custom-workflows/' | relative_url }})** — the pipeline isn't just for code. Author your own per-project workflow — writing, research, triage, anything — in a few lines of YAML.
