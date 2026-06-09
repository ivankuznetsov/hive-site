---
title: update
layout: default
parent: Command reference
nav_order: 14
permalink: /docs/commands/update/
description: Update Hive using the same channel that installed it — Homebrew, the AUR helper, or the install script.
---

# hive update

Updates your Hive install by delegating to whichever channel originally put it
there — Homebrew, an AUR helper (`yay`/`paru`), or the `install.sh` script. It
never swaps its own binary directly and never guesses across channels.

## Usage

```bash
hive update [--dry-run]
```

## Options

| Flag | What it does |
|------|--------------|
| `--dry-run` | Print the selected channel and the exact command it would run, without executing it. |

## How it picks a channel

Hive records how it was installed and uses that marker to choose the right
update command:

| Install channel | What `hive update` runs |
|-----------------|-------------------------|
| Homebrew | `brew upgrade ivankuznetsov/hive/hive` |
| AUR | `yay -Syu hive-bin` (falls back to `paru`) |
| Install script | Re-downloads and runs `install.sh`, preserving your original prefix |
| Dev / git checkout | Prints `git pull && bundle install` guidance |

If a required tool (`brew`, `curl`, `yay`, or `paru`) is missing, the command
tells you which one to install.

## Examples

```bash
# See what would run, without changing anything
hive update --dry-run

# Actually update via the detected channel
hive update
```

For the bigger picture on keeping Hive current, see
[Operating]({{ '/docs/operating/' | relative_url }}#updating--uninstalling).
