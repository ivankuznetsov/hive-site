---
title: FAQ
layout: doc
nav_order: 7
permalink: /docs/faq/
description: Answers about Hive's native web UI, built-in and installable workflows, local-first state, and agent support.
---

# FAQ
{: .no_toc }

## Does Hive have a native web UI?

Yes. Run `hive setup`, then `hive web` to serve the native Rails UI at
`http://127.0.0.1:4567`. It reads and operates the same local project registry
and workflow state as the TUI and CLI; it is not a separate hosted state store.
The [Hive web reference](https://github.com/ivankuznetsov/hive/blob/main/wiki/commands/web.md)
documents loopback access, GitHub login, service installation, and the separate
Hivebox container mode.

## Is Hive only for software delivery?

No. The flagship `coding` workflow is Hive's strongest public proof, not its
boundary. Hive also ships `content` and `bench`, installs reviewed
[Honeycomb workflows]({{ '/honeycombs/' | relative_url }}), and runs workflows
you author for research, writing, audits, triage, and operations. The
[workflow source documentation](https://github.com/ivankuznetsov/hive/blob/main/docs/workflows.md)
is the authoritative contract.

## Which agents can run stages?

Hive has built-in profiles for Claude, Codex, Pi, and Grok. Projects and
workflow descriptors can choose profiles per stage. See the
[agent-profile reference](https://github.com/ivankuznetsov/hive/blob/main/wiki/modules/agent_profile.md)
for the current invocation and authentication contracts.

## Why folders instead of a database?

Hive keeps workflow state local and inspectable. A task's folder location is
its stage, and markdown artifacts preserve the inputs, decisions, reviews, and
outputs needed to resume. Read [Concepts]({{ '/docs/concepts/' | relative_url }})
for the state model.

## Can OpenClaw operate Hive?

Yes. Install the published ClawHub package with
`openclaw skills install @ivankuznetsov/hive-cli`; it provides the `/hive`
command. The [public listing](https://clawhub.ai/ivankuznetsov/skills/hive-cli)
and [Hive source](https://github.com/ivankuznetsov/hive/tree/main/openclaw)
are the evidence for the current integration.
