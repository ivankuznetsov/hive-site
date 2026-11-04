import {
  initialState,
  transition,
  currentStage,
  visitAt,
  inspectStage,
  LAYOUTS,
  dockAt,
  flight,
  clamp,
} from "./workflow-state.mjs";
import "./approval-example.mjs";

const root = document.querySelector("[data-workflow-app]");
if (root) init(root);
function init(root) {
  const workflows = JSON.parse(
    document.querySelector("#workflow-examples").textContent,
  );
  const q = (selector) => root.querySelector(selector);
  const reduced = matchMedia("(prefers-reduced-motion: reduce)");
  let state = initialState(workflows[0]),
    playing = false,
    overview = true,
    elapsed = 0,
    last = 0,
    raf = 0,
    visible = false;
  const beat = 3.6,
    ns = "http://www.w3.org/2000/svg";
  const svg = (name, attrs = {}) => {
    const el = document.createElementNS(ns, name);
    for (const [key, value] of Object.entries(attrs))
      el.setAttribute(key, value);
    return el;
  };
  const tabs = [...root.querySelectorAll("[data-workflow]")];
  const text = (selector, value) => {
    q(selector).textContent = value;
  };
  const stageIndex = () => visitAt(state.workflow, state.position).stage;
  const announce = (message) => text("[data-announcement]", message);
  const stop = () => {
    playing = false;
    last = 0;
    cancelAnimationFrame(raf);
    raf = 0;
    syncControls();
  };
  function syncControls() {
    const blocked = ["waiting", "interrupted"].includes(state.status);
    q("[data-play]").hidden = reduced.matches;
    q("[data-play]").disabled = blocked;
    q("[data-play]").textContent = playing
      ? "Pause"
      : state.status === "complete"
        ? "Replay example"
        : "Play example";
    q("[data-next]").disabled = blocked || state.status === "complete";
    q("[data-next]").textContent =
      state.position === state.workflow.route.length - 1
        ? "Finish example"
        : "Next step →";
  }
  function buildScene() {
    const points = LAYOUTS[state.workflow.id];
    root.style.setProperty("--stage-count", state.workflow.stages.length);
    q("[data-belts]").replaceChildren();
    q("[data-machines]").replaceChildren();
    q("[data-stations]").replaceChildren();
    points.slice(1).forEach((to, i) => {
      const from = points[i],
        group = svg("g");
      const d = `M${from[0]} ${from[1]}L${to[0]} ${to[1]}`;
      group.append(
        svg("path", { d, class: "belt-bed" }),
        svg("path", { d, class: "belt-rollers" }),
      );
      q("[data-belts]").append(group);
    });
    // Preserve SVG depth ordering when the path turns back across the floor.
    points
      .map((point, i) => ({ point, i }))
      .sort((a, b) => a.point[1] - b.point[1])
      .forEach(({ point: [x, y], i }) => {
        const group = svg("g", {
          class: "factory-machine",
          "data-machine-index": i,
          transform: `translate(${x} ${y - 10})`,
        });
        group.append(
          svg("use", { href: `#machine-${state.workflow.stages[i].machine}` }),
        );
        const number = svg("text", {
          class: "machine-number",
          y: 82,
          "text-anchor": "middle",
        });
        number.textContent = String(i + 1).padStart(2, "0");
        group.append(number);
        q("[data-machines]").append(group);
      });
    state.workflow.stages.forEach((stage, i) => {
      const li = document.createElement("li"),
        button = document.createElement("button"),
        number = document.createElement("span");
      button.type = "button";
      button.setAttribute("aria-controls", "stage-details");
      number.textContent = String(i + 1).padStart(2, "0");
      number.setAttribute("aria-hidden", "true");
      button.append(number, document.createTextNode(stage.name));
      button.addEventListener("click", () => selectStage(i));
      button.addEventListener("keydown", (e) => {
        const n = state.workflow.stages.length,
          delta = { ArrowRight: 1, ArrowDown: 1, ArrowLeft: -1, ArrowUp: -1 }[
            e.key
          ];
        const index =
          e.key === "Home"
            ? 0
            : e.key === "End"
              ? n - 1
              : delta === undefined
                ? null
                : (i + delta + n) % n;
        if (index !== null) {
          e.preventDefault();
          selectStage(index);
          q("[data-stations]").children[index].firstChild.focus();
        }
      });
      li.append(button);
      q("[data-stations]").append(li);
    });
    q("[data-return]").removeAttribute("hidden");
    q("[data-return]").setAttribute(
      "d",
      state.workflow.id === "coding"
        ? "M1050 294 1150 352 1150 472 970 576 780 576 600 472 600 346 690 294"
        : "M1050 294 1160 358 1160 450 1050 514 940 450 940 358 1050 294",
    );
    tabs.forEach((tab) => {
      const active = tab.dataset.workflow === state.workflow.id;
      tab.setAttribute("aria-selected", active);
      tab.tabIndex = active ? 0 : -1;
    });
    q("#workflow-panel").setAttribute(
      "aria-labelledby",
      `tab-${state.workflow.id}`,
    );
  }
  function choose(workflow) {
    stop();
    state = initialState(workflow);
    elapsed = 0;
    overview = true;
    buildScene();
    render();
    announce(`${workflow.label}. ${workflow.summary}`);
  }
  function selectStage(index) {
    stop();
    state = inspectStage(state.workflow, index);
    elapsed = 0;
    overview = false;
    render();
    announce(
      `${currentStage(state).name}. ${state.status === "waiting" ? "Waiting for your demo decision." : "Stage selected."}`,
    );
  }
  function render() {
    const stage = currentStage(state),
      visit = visitAt(state.workflow, state.position),
      index = stageIndex();
    const complete = state.status === "complete",
      waiting = state.status === "waiting",
      interrupted = state.status === "interrupted";
    const artifact = visit.artifact || stage.artifact;
    const source = q("[data-package-source]");
    q("[data-package]").hidden = !state.workflow.install;
    q("[data-install-command]").textContent = state.workflow.install || "";
    source.href = state.workflow.source || "#";
    source.textContent = `${state.workflow.label} ${state.workflow.version || ""} source ↗`;
    text("[data-summary]", state.workflow.summary);
    text("[data-example-note]", state.workflow.note);
    text("[data-task-name]", state.workflow.task);
    text(
      "[data-stage-number]",
      `${String(index + 1).padStart(2, "0")} / ${String(state.workflow.stages.length).padStart(2, "0")} · ${stage.name}`,
    );
    text("[data-stage-role]", visit.actor || stage.actor);
    text(
      "[data-stage-title]",
      interrupted
        ? "Draft interrupted"
        : complete
          ? "Workflow complete"
          : visit.title || stage.title,
    );
    text(
      "[data-stage-body]",
      interrupted
        ? "This attempt did not finish. Retry the draft from its saved brief and research; the completed research stages do not need to start over."
        : complete
          ? `${state.workflow.result}. The task keeps its saved inputs and work history.`
          : visit.body || stage.body,
    );
    text("[data-file]", artifact);
    text(
      "[data-state-label]",
      interrupted
        ? "Attempt interrupted"
        : waiting
          ? "Needs your decision"
          : complete
            ? "Complete"
            : state.attempt > 1
              ? `Attempt ${state.attempt}`
              : visit.phase === "fix"
                ? "Fixing finding"
                : visit.phase === "revise"
                  ? "Council revision"
                  : visit.phase === "recheck" && stage.kind === "council"
                    ? "Review round 2"
                    : visit.phase === "review"
                      ? "Review round 1"
                      : "Stage output",
    );
    text(
      "[data-sample]",
      interrupted
        ? "brief.md             ✓ saved\nrepo-research.md      ✓ saved\nweb-research.md       ✓ saved\nresearch.md          ✓ saved\ndraft.md             · not yet complete"
        : complete
          ? state.workflow.completion || stage.sample
          : visit.sample || stage.sample,
    );
    text(
      "[data-operation]",
      interrupted
        ? "Draft interrupted · evidence preserved"
        : complete
          ? "Workflow complete"
          : visit.phase === "fix"
            ? "Review → execute → recheck"
            : stage.kind === "council"
              ? `${stage.name} · review → revise → recheck`
              : `${stage.name} · ${artifact}`,
    );
    text(
      "[data-context]",
      state.recovered
        ? "The earlier retry used saved task files; it did not replay the agent process."
        : stage.kind === "council" && !complete
          ? "Review, revision, and recheck are rounds within this council stage—not extra workflow stages."
          : "Sample stage output; saved inputs are listed below.",
    );
    text(
      "[data-run-note]",
      interrupted || state.recovered
        ? "Illustrative recovery, not a recorded failure"
        : "Illustration, not a live run",
    );
    q("[data-recovery]").hidden = !interrupted;
    q("[data-saved]").replaceChildren(
      ...(state.saved.length
        ? state.saved
        : ["No completed artifacts yet"]
      ).map((file) => {
        const li = document.createElement("li");
        li.textContent = file;
        return li;
      }),
    );
    [...q("[data-stations]").children].forEach((li, i) => {
      li.firstChild.setAttribute("aria-pressed", i === index);
      li.classList.toggle("is-current", i === index);
    });
    root.querySelectorAll("[data-machine-index]").forEach((machine) => {
      machine.classList.toggle(
        "is-active",
        Number(machine.dataset.machineIndex) === index,
      );
    });
    root.dataset.state = state.status;
    root.dataset.workflow = state.workflow.id;
    syncControls();
    paint(0);
  }
  function paint(progress) {
    const index = stageIndex(),
      stage = currentStage(state),
      from = dockAt(state.workflow, index);
    const next =
      state.position + 1 < state.workflow.route.length
        ? visitAt(state.workflow, state.position + 1).stage
        : index;
    const travel = ["waiting", "interrupted", "complete"].includes(state.status)
      ? 0
      : clamp((progress - 0.65) / 0.35);
    const to = dockAt(state.workflow, next),
      pos = flight(
        from,
        to,
        travel,
        stage.machine === "review",
        state.workflow.stages[next].machine === "review",
      );
    q("[data-packet]").setAttribute(
      "transform",
      `translate(${pos.x} ${pos.y}) scale(${pos.scale})`,
    );
    q("[data-packet]").dataset.moving = String(travel > 0 && travel < 1);
    q("[data-bee]").setAttribute(
      "transform",
      `translate(${pos.x - 35 * pos.scale} ${pos.y - 19 * pos.scale}) scale(1.4)`,
    );
    root.querySelectorAll("[data-form]").forEach((form) => {
      form.toggleAttribute("hidden", form.dataset.form !== (visitAt(state.workflow, state.position).form || stage.form));
    });
    const bounds = q(".factory-viewport").getBoundingClientRect(),
      w = bounds.width,
      h = bounds.height - 44;
    const points = LAYOUTS[state.workflow.id],
      minX = Math.min(...points.map((p) => p[0])) - 120,
      maxX = Math.max(...points.map((p) => p[0])) + 120,
      minY = Math.min(...points.map((p) => p[1])) - 195,
      maxY = Math.max(...points.map((p) => p[1])) + 100;
    const all = overview || state.status === "complete";
    const scale = all
      ? Math.min(w / (maxX - minX), h / (maxY - minY)) * 0.92
      : Math.min(w / (w < 450 ? 360 : 580), h / 380);
    const centre = all
      ? [(minX + maxX) / 2, (minY + maxY) / 2]
      : [pos.x, pos.y - 12];
    q(".factory-svg").setAttribute("viewBox", `0 0 ${w} ${bounds.height}`);
    q(".factory-camera").setAttribute(
      "transform",
      `translate(${w / 2 - centre[0] * scale} ${h / 2 - centre[1] * scale}) scale(${scale})`,
    );
  }
  function frame(now) {
    raf = 0;
    if (!playing || !visible || document.hidden) return;
    if (last) elapsed += Math.min((now - last) / 1000, 0.1);
    last = now;
    if (elapsed >= beat) {
      state = transition(state, { type: "next" });
      elapsed = 0;
      render();
      if (["waiting", "complete"].includes(state.status)) {
        stop();
        announce(
          state.status === "waiting"
            ? `${state.workflow.label} is waiting for a decision.`
            : `${state.workflow.label} example complete.`,
        );
        return;
      }
    }
    paint(elapsed / beat);
    raf = requestAnimationFrame(frame);
  }
  function wake() {
    last = 0;
    cancelAnimationFrame(raf);
    raf = 0;
    if (playing && visible && !document.hidden)
      raf = requestAnimationFrame(frame);
  }
  function play() {
    if (state.status === "complete") {
      state = initialState(state.workflow);
      elapsed = 0;
    }
    if (["waiting", "interrupted"].includes(state.status)) return;
    overview = false;
    playing = true;
    render();
    wake();
  }
  tabs.forEach((tab, i) => {
    tab.addEventListener("click", () => choose(workflows[i]));
    tab.addEventListener("keydown", (e) => {
      const delta = { ArrowRight: 1, ArrowLeft: -1 }[e.key],
        n = tabs.length;
      const to =
        e.key === "Home"
          ? 0
          : e.key === "End"
            ? n - 1
            : delta === undefined
              ? null
              : (i + delta + n) % n;
      if (to !== null) {
        e.preventDefault();
        choose(workflows[to]);
        tabs[to].focus();
      }
    });
  });
  q("[data-play]").addEventListener("click", () => (playing ? stop() : play()));
  q("[data-next]").addEventListener("click", () => {
    stop();
    state = transition(state, { type: "next" });
    elapsed = 0;
    overview = false;
    render();
    announce(
      `${currentStage(state).name}. ${state.status === "waiting" ? "Waiting for your demo decision." : state.status === "complete" ? "Example complete." : "Saved inputs carried forward."}`,
    );
  });
  q("[data-overview]").addEventListener("click", () => {
    stop();
    overview = true;
    paint(0);
    announce("Whole workflow shown. Select a stage to inspect its work.");
  });
  q("[data-retry]").addEventListener("click", () => {
    stop();
    state = transition(state, { type: "retry" });
    elapsed = 0;
    overview = false;
    render();
    q("[data-stage-title]").focus({ preventScroll: true });
    announce(`Attempt ${state.attempt} is ready, using the saved brief and research.`);
  });
  q("[data-interrupt]").addEventListener("click", () => {
    choose(workflows.find((w) => w.id === "writing"));
    state = transition(inspectStage(state.workflow, state.workflow.stages.findIndex((s) => s.id === "draft")), { type: "interrupt" });
    overview = false;
    render();
    q("[data-retry]").focus();
    announce(
      "Writing draft attempt interrupted. The brief and research remain saved. Retry is available in this example.",
    );
  });
  reduced.addEventListener("change", () => {
    stop();
    elapsed = 0;
    render();
  });
  document.addEventListener("visibilitychange", wake);
  new IntersectionObserver(
    (entries) => {
      visible = entries.at(-1).isIntersecting;
      wake();
    },
    { threshold: 0.1 },
  ).observe(q(".factory-viewport"));
  new ResizeObserver(() => paint(playing ? elapsed / beat : 0)).observe(
    q(".factory-viewport"),
  );
  buildScene();
  root.hidden = false;
  document.querySelector("[data-workflow-fallback]").hidden = true;
  render();
}
