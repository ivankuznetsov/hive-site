---
title: First run — Build or Content
layout: doc
nav_order: 1.5
permalink: /docs/first-run/
description: Choose Hive's Build or Content sample, read every native state, inspect the first artifact, and recover safely.
---

# First run — Build or Content
{: .no_toc }

Choose one outcome after you have [installed Hive]({{ '/docs/getting-started/' | relative_url }}).
Both routes use the same local daemon, native web UI, durable task files, and
guarded approval/recovery controls.

1. TOC
{:toc}

## Pick a path

- [Build]({{ '/build/' | relative_url }}) is the software flagship: one bounded
  `/healthz` change becomes an inspectable brainstorm, plan, patch, review, and
  handoff.
- [Content]({{ '/content/' | relative_url }}) is the non-coding flagship: one
  public brief becomes research, outline, draft, critique, and a reviewable
  article that is not automatically published.

## Prepare

Run `hive setup --no-init` and review the service setup plan. This leaves
workflow selection to the sample's `hive init` command. Check the daemon with
`hive daemon status`. If it is stopped, run `hive daemon start --detach`.
Use `hive web status` to find the local UI URL. If the web service is stopped,
start it with `hive web start --detach`.

Use a fresh, local Git repository with an initial commit and no remote. For
Build, create `hive-build-sample` as shown below. For Content, use
`hive-content-sample` in both commands.

```bash
mkdir hive-build-sample
cd hive-build-sample
git init -b main
git commit --allow-empty -m "Start Hive sample"
```

Run the `hive init` command from your chosen path and review its project
settings. Then paste the sample into **Add idea** in Hive web or use the
`hive new` command on the path page.

## Read the state before acting

| If Hive shows | Meaning | Safe response |
|---|---|---|
| **Queued for the daemon** | Dispatch is pending. | Wait for the authoritative snapshot. |
| **Agent running** | A stage owns the live task. | Open the task and inspect progress/logs. |
| **Needs your input** | A question or approval blocks progress. | Read the current artifact, then answer or approve. |
| **Waiting on provider / scheduler** | Capacity or a provider hold blocks dispatch. | Preserve the task and wait. |
| **Needs recovery** | Hive has a bounded recovery path. | Inspect the diagnostic and use **Retry stage**. |
| **Error** | No safe automatic continuation exists. | Diagnose and repair the cause first. |
| **Archived** | The workflow is terminal. | Inspect the full artifact chain and choose the next external action. |

The task page's current action label plus **Approve** or **Run stage** is the
source of truth. Do not infer success from a stopped process.

## Understand the evidence boundary

The checked-in Build and Content outputs are clearly labeled deterministic
fixtures. They make the sample inspectable without spending provider capacity,
but they are not live completion or timing evidence.

The five-minute acceptance target is visible progress plus the first artifact;
it is not yet verified by a clean launch replay. First-artifact time and full
reviewed-completion time must be measured and reported separately.

On 2026-07-21, two live Content tasks initially hit an installed Hive 0.6.4
durable-approve binding failure before research. Exact supported approvals
recovered them to running research stages. A reviewed terminal article and
accepted timing evidence were still unavailable. This historical failure is a
recovery fact, not a claim that the tasks completed.

## Choose the next action

- Build: replay the fixture in a clean throwaway repository and verify the real
  request test before any pull request.
- Content: review every source and critique, then ask for explicit publication
  approval; `article.md` is only a candidate artifact.
- Either path: if reality differs from the fixture, keep the live artifact and
  record the discrepancy instead of rewriting the example as success.

The public fixture and label contract live in the
[Hive source walkthrough](https://github.com/ivankuznetsov/hive/blob/354ff1c3a6eb636aaa345a8347806b540f1f9983/docs/launch-paths.md).
