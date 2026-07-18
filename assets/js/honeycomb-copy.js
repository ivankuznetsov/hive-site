(() => {
  if (!navigator.clipboard || !navigator.clipboard.writeText) return;

  const resetDelay = 1800;

  document.querySelectorAll("[data-honeycomb-copy]").forEach((button) => {
    const source = document.getElementById(button.getAttribute("aria-controls"));
    const status = document.getElementById(button.getAttribute("aria-describedby"));
    if (!source || !status) return;

    const idleLabel = button.textContent;
    button.hidden = false;
    button.addEventListener("click", async () => {
      try {
        await navigator.clipboard.writeText(source.textContent);
        button.textContent = "Copied";
        status.textContent = "Install command copied.";
      } catch (_error) {
        button.textContent = "Select manually";
        status.textContent = "Copy failed. Select the visible command and copy it manually.";
        source.focus();
      }

      window.setTimeout(() => {
        button.textContent = idleLabel;
        status.textContent = "";
      }, resetDelay);
    });
  });
})();
