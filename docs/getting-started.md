---
title: Getting started
layout: doc
nav_order: 1
permalink: /docs/getting-started/
description: Install Hive, set up the native local web UI, and run your first workflow from the web, TUI, or CLI.
---

# Getting started
{: .no_toc }

Hive is a durable, local-first workflow engine for AI agents. This first run
uses its flagship **`coding`** workflow: a rough idea becomes a reviewed pull
request. The same engine also runs `content`, `bench`, and
[workflows you define]({{ '/docs/custom-workflows/' | relative_url }}).

The daemon advances ready tasks and pauses for questions, decisions, or recovery.
Use the native local web UI, TUI, or CLI to inspect the same saved work.

1. TOC
{:toc}

## Prerequisites

The default coding workflow needs:

- **Ruby 3.4**, **git ≥ 2.40**, and authenticated **`gh`** (GitHub CLI).
- Authenticated **Claude Code ≥ 2.1.118** and **Codex ≥ 0.125.0** for the default
  stage assignments. Other supported profiles include Grok, Pi, and opt-in
  OpenCode; requirements depend on the agents you select.
- **cosign** to verify released artifacts. The Linux installer also checks for
  `curl`, `jq`, `gem`, and a checksum tool.
- **Node.js / npm** for managed QMD installation; a missing QMD indexer is
  reported non-fatally by `hive doctor`.

Hive's software is MIT-licensed; agent usage is billed by your providers or
subscriptions. Multi-agent coding can be token-heavy. Configure budgets and
review the project options before unattended work.

## 1. Install

Hive releases contain the `hive-cli` gem and a managed native web bundle. A
cosign-signed checksum manifest authenticates the release artifacts.

```bash
# macOS arm64
brew install ivankuznetsov/hive/hive

# Arch Linux x86_64 / aarch64
yay -S hive-bin

# Ubuntu 22.04+ / glibc Linux x86_64 / aarch64
tmpdir="$(mktemp -d)" && trap 'rm -rf "$tmpdir"' EXIT \
  && curl -fsSL https://raw.githubusercontent.com/ivankuznetsov/hive/v{{ site.hive_version }}/install.sh \
       -o "$tmpdir/hive-install.sh" \
  && bash "$tmpdir/hive-install.sh"
```

Verify with `hive --version`. If Apache Hive already owns that command name,
use the `hv` shim; the same commands work as `hv …`.

On Windows, use native Hive in WSL with systemd enabled. Hivebox is discontinued
as of v0.8.0; existing images receive no new builds. Read the
[release and upgrade notes](https://github.com/ivankuznetsov/hive/releases/tag/v{{ site.hive_version }})
before updating an older installation.

## 2. Set up local services and a project

```bash
hive setup
cd ~/Dev/your-project
hive init .
hive doctor
```

On supported Linux and macOS hosts, `hive setup` previews changes and asks for
confirmation before provisioning Hive-owned dependencies, managed agent skills,
and the per-user daemon, babysitter, and local web service. Non-interactive
setup needs `--yes`. Use `--no-service` to skip web-service mutations.

`hive init` configures the project's workflow, agents, permission mode, optional
budgets, and daemon/babysitter/patrol enrollment. Review those choices. Claude
stages now run headless as `claude -p`; there is no launch-mode prompt. Follow
stage logs under `.hive-state/logs/<slug>/`.

In v0.8.0, agents receive only the MCP servers granted in Hive config by default.
Use `hive mcp import` and grant the servers your workflow needs. Claude budgets
are opt-in; existing project caps remain effective. See
[Configuration]({{ '/docs/configuration/' | relative_url }}) and the release notes.

## 3. Open the local web UI—or the TUI

```bash
hive web status      # inspect readiness and open the reported URL
hive daemon status
```

The untouched web configuration is loopback-only at `http://127.0.0.1:4567`.
Setup does not expose it publicly. The local UI uses your registered projects
and saved workflow state; a hosted account is not required.

Prefer the terminal? Run `hive tui`. To use a foreground web server instead of
the managed service, run `hive web`. See
[Operating]({{ '/docs/operating/' | relative_url }}) for service management.

## 4. Capture a task and inspect its progress

Create a task from the web UI, or press **`n`** in the TUI and choose the project.
Start with a small, concrete request. You can also use the CLI:

```bash
hive new <project-name> "build a small feature"
hive status
```

The task has a folder and an `idea.md` input. As stages run, they leave artifacts
such as `brainstorm.md`, `plan.md`, and review findings. The daemon advances
ready work; it does not silently answer human questions or approval gates.

When input is needed, open the task in the web UI, or select it and press
**Enter** in the TUI to open the relevant file. Review the question or decision,
provide your response, and watch the next handoff. Recovery may retry a stage
from saved inputs; unresolved or unsafe failures need intervention.

## Where to go next

- **[Concepts]({{ '/docs/concepts/' | relative_url }})** — artifacts, stage state, human decisions, and durability limits.
- **[Custom workflows]({{ '/docs/custom-workflows/' | relative_url }})** — define agent stages and an explicit human gate.
- **[Configuration]({{ '/docs/configuration/' | relative_url }})** — agents, permissions, reviewers, and limits.
- **[Command reference]({{ '/docs/commands/' | relative_url }})** — inspect and drive workflows from the CLI.
- **[Operating]({{ '/docs/operating/' | relative_url }})** — local services and the OpenClaw `/hive` skill.
- **[HiveDev](https://hivedev.ai/)** — the hosted product built on Hive, currently accepting waitlist signups.
