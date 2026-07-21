---
title: Getting started
layout: doc
nav_order: 1
permalink: /docs/getting-started/
description: Install Hive, run native setup, open the local web UI, and capture your first task.
---

# Getting started
{: .no_toc }

This walks you from nothing to watching Hive carry your first idea toward a
pull request, using Hive's default **`coding`** workflow. (It's one of several —
Hive also ships `content` and lets you author your own
[custom workflows]({{ '/docs/custom-workflows/' | relative_url }}) — but `coding`
is the best first run.) The happy path is **native-web and daemon first**: the
daemon advances ready tasks, and the local browser UI shows the queue and the
questions that need you. The TUI and direct CLI remain available, but you do
not need to learn the stage commands on day one.

1. TOC
{:toc}

## Prerequisites

Hive is a local-first, token-heavy workflow engine — see
[Is Hive for you?](/#fit) if you haven't yet. You'll need:

- **Ruby 3.4** — the gem and its runtime deps install against this.
- **git ≥ 2.40** and an authenticated **`gh`** (GitHub CLI).
- An authenticated **`claude`** (≥ 2.1.118), and **`codex`** (≥ 0.125.0) for the
  default execute agent.
- **`tmux` ≥ 3.0** when the project uses the default `claude.mode: tmux`.
- **Node.js / npm** for the managed QMD wiki indexer (optional; `hive doctor`
  reports the gap non-fatally if it's missing).
- **cosign** for released native installs to authenticate the managed Hive web
  bundle before extraction.

## 1. Install

Hive ships as the `hive-cli` rubygem and a matching managed web bundle attached
to each GitHub Release. Each channel verifies the cosign-signed checksum
manifest before installing the gem. Setup uses the installed package root and
authenticates the web bundle through the same release manifest before extraction.

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

All channels install the CLI; the next `hive setup` step owns per-user service
provisioning so it behaves consistently across package managers.

Verify:

```bash
hive --version
```

If Apache Hive already owns the `hive` name on your `PATH`, use the `hv` shim
that the install channels create — every command below works as `hv …` too.

> **Prefer to have an agent do it?** Hive publishes an OpenClaw `/hive` skill
> and a canonical agent-installer prompt. See
> [Operating]({{ '/docs/operating/' | relative_url }}#openclaw-hive-skill).

## 2. Run native setup in your project

```bash
cd ~/Dev/your-project
hive setup
```

On supported Linux and macOS hosts, `hive setup` previews its host mutations,
asks once for host-mutation consent, then:

- checks dependencies and installs Hive's managed agent skills;
- bootstraps the authenticated Hive web bundle;
- installs and starts the per-user daemon;
- initializes or enrolls the current project; and
- installs, enables, starts, and probes the per-user Hive web service.

The result reports the effective URL plus distinct **installed**, **enabled**,
**running**, and **ready** state. With untouched configuration, open
`http://127.0.0.1:4567`. Setup never creates LAN/public binding or Tailscale
exposure; it only observes a non-loopback choice you explicitly configured and
gated beforehand.

Useful alternatives:

```bash
hive setup --no-service     # perform setup but do not mutate the web service
hive web                    # run the blocking foreground server instead
hive setup --no-bootstrap   # diagnose only; provision nothing
hive web status --json      # read-only structured service/readiness state
```

On Windows, use WSL with systemd enabled for native Hive web, or choose
[Hivebox]({{ '/box/' | relative_url }}) through Docker Desktop. Hivebox is also
the better fit for container isolation, multiple local instances, containment
of untrusted agents, or reproducible server/NAS deployment.

If you chose `--no-init`, attach the project separately with `hive init .`.
Interactive initialization asks about:

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

## 3. Open Hive web

```bash
hive web status            # should report running and ready
# open the URL printed by setup/status
```

The browser status page shows every registered project and live task. Prefer a
terminal dashboard? Run `hive tui`. If you deliberately opted out of the
managed web service, run bare `hive web`; it stays in the foreground until you
stop it.

## 4. Capture one rough idea

Use the composer at the top of Hive web, choose the project, type the thing you
want built or investigated, and submit it. The new row starts in `1-inbox`,
backed by an `idea.md` file under `.hive-state/`.

Prefer the TUI or command line? Press **`n`** in `hive tui`, or run:

```bash
hive new . "a Telegram bot that sends a daily digest of what was shipped"
```

## 5. Watch Hive move it forward

Leave Hive web open. The daemon picks up the new row, turns the idea into
`brainstorm.md`, promotes completed work into `plan.md`, and keeps moving
through the pipeline while each stage is ready. Long stages show as running;
completed stages leave files behind for the next stage and for you.

## 6. Answer only when Hive asks

When a row says it needs input, open it. Answer the questions in Hive web, or
use the TUI/editor flow if you prefer durable markdown directly. The daemon sees
the answer and continues the task automatically.

That's the whole loop: a rough idea becomes durable stage files, then Hive keeps
advancing the same task toward code, a pull request, review, and archive.

## Where to go next

- **[Concepts]({{ '/docs/concepts/' | relative_url }})** — why it's shaped this way: folder-as-agent, the nine stages, the marker protocol.
- **[`hive setup`]({{ '/docs/commands/setup/' | relative_url }}) and [`hive web`]({{ '/docs/commands/web/' | relative_url }})** — first-run modes, service state, JSON contracts, and repair.
- **[Configuration]({{ '/docs/configuration/' | relative_url }})** — native web, patrol, reviewers, agent profiles, budgets, and the daemon.
- **[Command reference]({{ '/docs/commands/' | relative_url }})** — drive any stage by hand, or script Hive from an agent.
- **[Operating]({{ '/docs/operating/' | relative_url }})** — run Hive web, the daemon, Telegram bot, and babysitter as services.
- **[Custom workflows]({{ '/docs/custom-workflows/' | relative_url }})** — the pipeline isn't just for code. Author your own per-project workflow — writing, research, triage, anything — in a few lines of YAML.
