import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import {
  initialState,
  transition,
  currentStage,
  inspectStage,
  visitAt,
  dockAt,
  flight,
} from "../assets/js/workflow-state.mjs";
const workflows = JSON.parse(
  await readFile(
    new URL("../_data/workflow_examples.json", import.meta.url),
    "utf8",
  ),
);
const [coding, content, research] = workflows;
test("built-ins have distinct real stage paths and result types", () => {
  assert.deepEqual(
    coding.stages.map((s) => s.id),
    [
      "inbox",
      "brainstorm",
      "plan",
      "execute",
      "open-pr",
      "review",
      "artifacts",
      "finalize",
      "done",
    ],
  );
  assert.deepEqual(
    content.stages.map((s) => s.id),
    ["inbox", "research", "outline", "draft", "critique", "done"],
  );
  assert.equal(content.stages.at(-1).artifact, "article.md");
  assert.ok(content.stages.every((s) => s.form !== "pr" && s.form !== "code"));
  assert.equal(research.badge, "Custom example");
});
test("coding rechecks its repair before evidence, and finishes without losing saved artifacts", () => {
  let state = initialState(coding),
    sawFix = false,
    sawRecheck = false;
  for (let count = 0; state.status !== "complete"; count++) {
    assert.ok(count < 15, "finite example");
    const visit = visitAt(coding, state.position);
    if (visit.phase === "fix") sawFix = true;
    if (visit.phase === "recheck") {
      assert.ok(sawFix);
      sawRecheck = true;
    }
    if (currentStage(state).id === "artifacts") assert.ok(sawRecheck);
    const before = state.saved;
    state = transition(state, { type: "next" });
    assert.ok(before.every((file) => state.saved.includes(file)));
  }
  assert.ok(state.saved.includes("plan.md"));
  assert.ok(state.saved.includes("summary.md"));
  assert.equal(transition(state, { type: "next" }), state);
});
test("an interrupted draft cannot advance; retry preserves saved inputs and increments its attempt", () => {
  const original = inspectStage(content, 3);
  assert.deepEqual(original.saved, ["idea.md", "research.md", "outline.md"]);
  const stopped = transition(original, { type: "interrupt" });
  assert.equal(stopped.status, "interrupted");
  assert.equal(transition(stopped, { type: "next" }), stopped);
  const retry = transition(stopped, { type: "retry" });
  assert.equal(retry.attempt, 2);
  assert.equal(currentStage(retry).id, "draft");
  assert.deepEqual(retry.saved, original.saved);
  const next = transition(retry, { type: "next" });
  assert.ok(next.saved.includes("draft.md"));
  assert.equal(currentStage(next).id, "critique");
});
test("a human gate cannot be bypassed by playback or retry, and approval is explicit", () => {
  const gate = inspectStage(research, 2);
  assert.equal(gate.status, "waiting");
  assert.deepEqual(gate.saved, ["research.md", "report.md"]);
  for (const type of ["next", "retry", "interrupt"])
    assert.equal(transition(gate, { type }), gate);
  const approved = transition(gate, { type: "approve" });
  assert.equal(approved.status, "complete");
  assert.deepEqual(approved.decisions, ["approved"]);
  assert.ok(approved.saved.includes("approval.md"));
  assert.equal(
    transition(initialState(research), { type: "approve" }).status,
    "ready",
  );
});
test("rejection returns the same task to synthesis without discarding evidence or its decision", () => {
  const gate = inspectStage(research, 2),
    revision = transition(gate, { type: "reject" });
  assert.equal(revision.workflow, gate.workflow);
  assert.equal(currentStage(revision).id, "synthesis");
  assert.ok(gate.saved.every((f) => revision.saved.includes(f)));
  const again = transition(revision, { type: "next" });
  assert.equal(again.status, "waiting");
  const result = transition(again, { type: "approve" });
  assert.deepEqual(result.decisions, ["revision requested", "approved"]);
});
test("carrier handoffs start and end at machine surfaces, including the open side of a review gate", () => {
  for (const flow of workflows) {
    for (let i = 0; i < flow.stages.length - 1; i++) {
      const from = dockAt(flow, i),
        to = dockAt(flow, i + 1),
        fg = flow.stages[i].machine === "review",
        tg = flow.stages[i + 1].machine === "review";
      assert.deepEqual(flight(from, to, 0, fg, tg), from);
      assert.deepEqual(flight(from, to, 1, fg, tg), to);
      assert.ok(flight(from, to, 0.5, fg, tg).y < Math.min(from.y, to.y));
    }
  }
});
