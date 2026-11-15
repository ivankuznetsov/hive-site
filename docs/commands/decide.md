---
title: decide
layout: doc
parent: Command reference
nav_order: 22
permalink: /docs/commands/decide/
description: Record a human-stage decision, such as approve or reject, for a task waiting at a review gate.
---

# hive decide

Applies one named outcome to a task that is waiting at a human stage of its
workflow, such as an approval gate. Use it when `hive run` or `hive status` shows
such a task. It is the human counterpart of
[`hive approve`]({{ '/docs/commands/approve/' | relative_url }}): approve advances
tasks that finished cleanly, while decide records a person's choice.

Outcome names come from the workflow. The
[Custom workflows]({{ '/docs/custom-workflows/' | relative_url }}) guide explains
how stages declare them.

## Usage

```bash
hive decide <slug> <outcome> --from <stage> --decision-id <id> [--note TEXT] [--project NAME] [--json]
```

## Options

| Flag | What it does |
|------|--------------|
| `TARGET` | Task slug or folder, currently waiting at the human stage. |
| `OUTCOME` | One of the outcomes that stage declares. Unknown names are rejected with the valid list. |
| `--from STAGE` | Required. The human stage, in full or short form such as `approval`. |
| `--decision-id ID` | Required. The 16-character hex identity that `hive run` or `hive status` reports for this waiting visit. |
| `--note TEXT` | Optional audit note saved with the decision. |
| `--project NAME` | Look up the slug in one registered project only. |
| `--json` | Emit the `hive-decide` envelope. |

## How it behaves

- The task must be waiting at that stage with the same decision ID. A stale
  decision fails with a `wrong_stage` error, and so does a repeat of the same
  decision with a different outcome. Neither changes the task.
- Repeating the same decision with the same outcome is a no-op.
- Depending on the outcome, the task completes the stage or returns to the
  stage the outcome names.
- A completing outcome needs its declared artifact, such as `draft.md`, to be a
  non-empty regular file in the task folder. Symlinks are refused.

## Examples

```bash
# Approve the draft waiting at the approval gate
hive decide add-inbox-filter-260603-abcd approve --from approval --decision-id abcdef0123456789

# Reject it with a note for the next pass
hive decide add-inbox-filter-260603-abcd reject --from approval \
  --decision-id abcdef0123456789 --note "revise the conclusion"

# Structured result for a script
hive decide <slug> approve --from approval --decision-id <id> --json
```

Get the decision ID from `hive run --json` or `hive status` while the task is
waiting. To see which tasks are waiting, see
[`hive status`]({{ '/docs/commands/status/' | relative_url }}).
