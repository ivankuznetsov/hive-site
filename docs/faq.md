---
title: FAQ
layout: doc
nav_order: 9
permalink: /docs/faq/
description: Answers about Hive's native web UI, built-in and installable workflows, local-first state, and agent support.
---

# FAQ
{: .no_toc }

## Does Hive have a native web UI?

Yes. Run `hive setup` and then `hive web status` to check the managed UI and
find its URL. The default is `http://127.0.0.1:4567`. The UI uses the same
local project registry and workflow state as the TUI and CLI. The
[web command reference]({{ '/docs/commands/web/' | relative_url }}) covers
loopback access, sign-in, and service management.

## Is Hive only for software delivery?

Hive ships `coding`, `content`, and `bench`. You can install reviewed
[Honeycomb workflows]({{ '/honeycombs/' | relative_url }}) or
[write your own workflow]({{ '/docs/custom-workflows/' | relative_url }}).
The [Content sample]({{ '/content/' | relative_url }}) walks through
research, drafting, and critique.

## Which agents can run stages?

Hive provides profiles for Claude Code, Codex, Pi, Grok, and opt-in
OpenCode. Configure an [agent profile]({{ '/docs/configuration/' | relative_url }}#agent-profiles)
for each stage.

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
