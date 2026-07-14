(function () {
  "use strict";

  function initBenchTooltips() {
    var triggers = Array.from(document.querySelectorAll("[data-bench-tooltip]"));
    if (!triggers.length) return;

    var tooltip = document.createElement("div");
    tooltip.className = "bench-tooltip";
    tooltip.id = "bench-tooltip";
    tooltip.setAttribute("role", "tooltip");
    tooltip.hidden = true;
    document.body.appendChild(tooltip);

    var activeTrigger = null;
    var positionFrame = null;

    function positionTooltip(trigger) {
      var gutter = 12;
      var gap = 8;
      var triggerRect = trigger.getBoundingClientRect();
      var tooltipRect = tooltip.getBoundingClientRect();
      var left = triggerRect.left + (triggerRect.width - tooltipRect.width) / 2;
      var top = triggerRect.top - tooltipRect.height - gap;

      left = Math.max(gutter, Math.min(left, window.innerWidth - tooltipRect.width - gutter));
      if (top < gutter) top = triggerRect.bottom + gap;

      tooltip.style.left = Math.round(left) + "px";
      tooltip.style.top = Math.round(top) + "px";
    }

    function showTooltip(trigger) {
      if (activeTrigger === trigger && !tooltip.hidden) return;

      if (activeTrigger && activeTrigger !== trigger) {
        activeTrigger.removeAttribute("aria-describedby");
      }

      activeTrigger = trigger;
      tooltip.textContent = trigger.getAttribute("data-bench-tooltip") || "";
      tooltip.hidden = false;
      trigger.setAttribute("aria-describedby", tooltip.id);
      positionTooltip(trigger);
    }

    function hideTooltip(trigger) {
      if (trigger && trigger !== activeTrigger) return;
      if (activeTrigger) activeTrigger.removeAttribute("aria-describedby");
      activeTrigger = null;
      tooltip.hidden = true;
    }

    function schedulePosition() {
      if (!activeTrigger || positionFrame !== null) return;
      positionFrame = window.requestAnimationFrame(function () {
        positionFrame = null;
        if (activeTrigger) positionTooltip(activeTrigger);
      });
    }

    triggers.forEach(function (trigger) {
      trigger.addEventListener("mouseenter", function () { showTooltip(trigger); });
      trigger.addEventListener("mouseleave", function () {
        if (document.activeElement !== trigger) hideTooltip(trigger);
      });
      trigger.addEventListener("focus", function () { showTooltip(trigger); });
      trigger.addEventListener("blur", function () {
        if (!trigger.matches(":hover")) hideTooltip(trigger);
      });
    });

    document.addEventListener("keydown", function (event) {
      if (event.key === "Escape" && activeTrigger) hideTooltip(activeTrigger);
    });
    window.addEventListener("resize", schedulePosition);
    window.addEventListener("scroll", schedulePosition, true);
  }

  document.addEventListener("DOMContentLoaded", initBenchTooltips);
})();
