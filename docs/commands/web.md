---
title: web
layout: doc
parent: Command reference
nav_order: 3
permalink: /docs/commands/web/
description: Run native Hive web in the foreground or inspect, install, and repair its per-user managed service.
---

# hive web

Runs or manages Hive's native browser UI. It presents the same registered
projects and workflow state as the CLI and TUI; it does not add a second task
database or pipeline engine.

Bare `hive web` is a blocking foreground server. The normal managed-service
path is installed by [`hive setup`]({{ '/docs/commands/setup/' | relative_url }}).

## Usage

```bash
hive web                         # blocking foreground server
hive web status                  # read-only service and readiness state
hive web status --json           # hive-web-status.v1
hive web install                 # install/start the per-user service
hive web install --force         # explicitly replace a drifted service unit
hive web start --detach          # start through the service manager
```

The foreground command accepts `--bind`, `--port`, and `--no-bootstrap`.
Non-loopback binding requires an explicit owner gate or the intentionally loud
`--unsafe` override. The default is the verified loopback-only URL
`http://127.0.0.1:4567`.

## Status is read-only

`hive web status` never installs, enables, starts, stops, repairs, or refreshes
the service. It reports the configured effective URL and keeps these facts
distinct:

- service manager availability;
- installed and enabled state;
- running state; and
- bounded local readiness.

`--json` emits exactly one `hive-web-status.v1` document on success or failure.
It includes `mode: "managed_service"`, the effective URL, migration warnings,
and the lifecycle fields above.

## Install and explicit repair

`hive web install` bootstraps the authenticated managed app when needed, writes
the per-user `hive-web` unit, enables and starts it, then resamples lifecycle
state and probes readiness. Success requires installed, enabled, running, and
ready state. `--force` is the explicit authorization to overwrite a drifted or
customized unit; ordinary `hive setup` will not do that silently.

`--json` emits exactly one `hive-web-install.v1` document. Bootstrap and
service-manager failures retain that versioned envelope, including the observed
service state, so callers do not have to parse human stderr.

## Managed bundle and environment

Released Hive web archives resolve against the installed `hive-cli` package
root. Before extraction, Hive authenticates the release's cosign-signed checksum
manifest and verifies the archive digest. A custom remote
`HIVE_WEB_BUNDLE_URL` is rejected unless `HIVE_WEB_BUNDLE_SHA256` supplies its
exact digest.

The canonical shared-app variables are `HIVE_WEB_APP_DIR`, `HIVE_WEB_ORIGIN`,
`HIVE_WEB_STORAGE_DIR`, `HIVE_WEB_LOCAL_LOOPBACK`,
`HIVE_WEB_DIFF_TIMEOUT_SEC`, and `HIVE_WEB_CLONE_TIMEOUT_SEC`. Their six
native-web `HIVEBOX_*` aliases remain accepted with migration warnings through
the next major release; canonical values win. Container-only Hivebox variables
remain canonical and quiet. See
[Configuration]({{ '/docs/configuration/' | relative_url }}) for the mapping.

## Native web or Hivebox?

Use native Hive web for the ordinary local Linux/macOS experience. Choose
[Hivebox]({{ '/box/' | relative_url }}) for container isolation, multiple local
instances, containment of untrusted agents, or reproducible server/NAS
deployment. Windows users can run native Hive web under WSL with systemd, or
Hivebox through Docker Desktop.
