---
title: mcp
layout: doc
parent: Command reference
nav_order: 21
permalink: /docs/commands/mcp/
description: Import personal MCP servers into Hive's catalog and sign agents in to OAuth servers.
---

# hive mcp

Hive-launched agents receive only the MCP servers you grant them. `hive mcp import`
copies servers from your Codex, Claude, OpenCode, Pi, and Grok configs into Hive's
catalog. Credential values are never copied. `hive mcp login` signs an agent in to
an imported OAuth server, so headless stage runs can reuse that login. Reach for
it when a stage needs a server your agents already use.

The catalog is `mcp.servers` in `~/.config/hive/config.yml`. Grant a server to a
project or stage with `mcp: { use: [name] }` in `.hive-state/config.yml`.

## Usage

```bash
hive mcp import [--all | --only NAMES] [--update] [--dry-run] [--yes] [--json]
hive mcp login SERVER --agent codex|claude
```

## Subcommands

| Subcommand | What it does |
|------------|--------------|
| `import` | Lists the servers your agent configs define and writes the ones you select to the catalog. |
| `login SERVER` | Runs the agent's sign-in for an imported HTTP server. Interactive only. |

## Options

| Flag | What it does |
|------|--------------|
| `--all` | Import every new server. Cannot be combined with `--only`. |
| `--only NAMES` | Import a comma-separated list of server names or row ids. |
| `--update` | Also replace catalog entries whose source config changed. |
| `--dry-run` | Show the plan without writing. |
| `--yes` | Write without asking. |
| `--agent AGENT` | For `login`: `codex` or `claude`. |
| `--json` | Emit the `hive-mcp-import` envelope. Not available for `login`. |

## Notes

- Without a terminal, `import` needs `--all` or `--only`, plus `--yes` to write.
- Literal credentials become environment-variable names. `import` prints the
  `export` lines to set before launching agents. Hive stores only the names.
- `login` needs a terminal and a server that is already imported. Stdio servers
  cannot sign in.

## Examples

```bash
# Pick servers from an interactive table
hive mcp import

# Preview a non-interactive import as JSON
hive mcp import --dry-run --json

# Import every new server, or two named ones
hive mcp import --all --yes
hive mcp import --only linear,docs --yes

# Refresh entries whose source config changed
hive mcp import --all --update --yes

# Sign Codex in to an imported OAuth server
hive mcp login linear --agent codex
```

[`hive doctor`]({{ '/docs/commands/doctor/' | relative_url }}) lists servers you
have not imported and missing logins. For the settings these commands read, see
[Configuration]({{ '/docs/configuration/' | relative_url }}).
