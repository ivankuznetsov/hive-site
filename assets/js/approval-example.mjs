import { inspectStage, transition } from "./workflow-state.mjs";

// A separate, local illustration of the custom YAML gate. Neither installed
// Honeycomb above declares this human stage; no Hive task is executed here.
const root = document.querySelector("[data-gate-example]");
if (root) {
  const workflow = JSON.parse(document.querySelector("#approval-example").textContent);
  const ready = () => inspectStage(workflow, workflow.stages.length - 1);
  let state = ready();
  const q = (selector) => root.querySelector(selector);
  function render() {
    const waiting = state.status === "waiting";
    const complete = state.status === "complete";
    q("[data-gate-title]").textContent = complete
      ? "Report approved in this example"
      : waiting
        ? state.decisions.length ? "Revised report ready for review" : "Sample report ready for review"
        : "Revision requested → synthesis";
    q("[data-gate-detail]").textContent = complete
      ? "The decision is recorded. Nothing was published or sent."
      : waiting
        ? "Approve report.md, or ask the synthesis stage to make the source limitations clearer."
        : "The same task keeps its research, earlier report, and decision. The reviser must address the source limitations before returning here.";
    q("[data-gate-files]").textContent = `Saved: ${state.saved.join(" · ")}`;
    q("[data-gate-history]").textContent = state.decisions.length
      ? `Decisions: ${state.decisions.join(" → ")}` : "Demo decision · no external action";
    q("[data-gate-approve]").hidden = !waiting;
    q("[data-gate-reject]").hidden = !waiting;
    q("[data-gate-revise]").hidden = waiting || complete;
    q("[data-gate-reset]").hidden = !complete;
    root.dataset.state = state.status;
  }
  for (const action of ["approve", "reject", "revise", "reset"]) {
    q(`[data-gate-${action}]`).addEventListener("click", () => {
      state = action === "reset" ? ready()
        : transition(state, { type: action === "revise" ? "next" : action });
      render();
      q("[data-gate-title]").focus({ preventScroll: true });
    });
  }
  render();
  root.hidden = false;
}
