(() => {
  const STORAGE_KEY = "oban_powertools:theme";
  const THEMES = new Set(["system", "light", "dark", "high-contrast"]);
  const ATTR_THEME = "data-obpt-theme";
  const ATTR_EFFECTIVE_THEME = "data-obpt-effective-theme";
  const ATTR_MOTION = "data-obpt-motion";
  const ATTR_TOOLTIP_OPEN = "data-obpt-tooltip-open";
  const ATTR_TOOLTIP_DISMISSED = "data-obpt-tooltip-dismissed";
  const ROOT_SELECTOR = ".obpt-root";
  const TOOLTIP_SELECTOR = "[data-obpt-tooltip]";
  const TOOLTIP_TRIGGER_SELECTOR = "[data-obpt-tooltip-trigger]";

  const colorPreference = window.matchMedia("(prefers-color-scheme: dark)");
  const contrastPreference = window.matchMedia("(prefers-contrast: more)");
  const motionPreference = window.matchMedia("(prefers-reduced-motion: reduce)");

  function normalizeTheme(theme) {
    return THEMES.has(theme) ? theme : "system";
  }

  function storedTheme() {
    try {
      return normalizeTheme(window.localStorage.getItem(STORAGE_KEY));
    } catch (_error) {
      return "system";
    }
  }

  function effectiveTheme(theme) {
    const requestedTheme = normalizeTheme(theme);

    if (requestedTheme !== "system") {
      return requestedTheme;
    }

    if (contrastPreference.matches) {
      return "high-contrast";
    }

    return colorPreference.matches ? "dark" : "light";
  }

  function apply(root, theme = storedTheme()) {
    if (!root || !root.matches || !root.matches(ROOT_SELECTOR)) {
      return;
    }

    const requestedTheme = normalizeTheme(theme);
    root.setAttribute(ATTR_THEME, requestedTheme);
    root.setAttribute(ATTR_EFFECTIVE_THEME, effectiveTheme(requestedTheme));
    root.setAttribute(ATTR_MOTION, motionPreference.matches ? "reduce" : "safe");
  }

  function roots() {
    return Array.from(document.querySelectorAll(ROOT_SELECTOR));
  }

  function setTheme(theme) {
    const requestedTheme = normalizeTheme(theme);

    try {
      window.localStorage.setItem(STORAGE_KEY, requestedTheme);
    } catch (_error) {
      // Browsers can deny storage in private mode; theming remains scoped and usable.
    }

    roots().forEach((root) => apply(root, requestedTheme));
  }

  function applyStoredTheme() {
    const requestedTheme = storedTheme();
    roots().forEach((root) => apply(root, requestedTheme));
  }

  function closestElement(event, selector) {
    const target = event.target;

    if (!target || !target.closest) {
      return null;
    }

    return target.closest(selector);
  }

  function scopedTooltipFor(event, selector = TOOLTIP_SELECTOR) {
    const root = closestElement(event, ROOT_SELECTOR);
    const target = closestElement(event, selector);

    if (!root || !target || !root.contains(target)) {
      return null;
    }

    return target.closest(TOOLTIP_SELECTOR);
  }

  function tooltipTrigger(tooltip) {
    return tooltip ? tooltip.querySelector(TOOLTIP_TRIGGER_SELECTOR) : null;
  }

  function openTooltip(tooltip) {
    if (!tooltip) {
      return;
    }

    tooltip.removeAttribute(ATTR_TOOLTIP_DISMISSED);
    tooltip.setAttribute(ATTR_TOOLTIP_OPEN, "true");
  }

  function closeTooltip(tooltip, dismissed = false) {
    if (!tooltip) {
      return;
    }

    tooltip.removeAttribute(ATTR_TOOLTIP_OPEN);

    if (dismissed) {
      tooltip.setAttribute(ATTR_TOOLTIP_DISMISSED, "true");
    }
  }

  function leavingTooltip(event, tooltip) {
    const nextTarget = event.relatedTarget;
    return !nextTarget || !tooltip.contains(nextTarget);
  }

  const currentRoot =
    document.currentScript && document.currentScript.closest
      ? document.currentScript.closest(ROOT_SELECTOR)
      : null;

  if (currentRoot) {
    apply(currentRoot);
  }

  applyStoredTheme();

  [colorPreference, contrastPreference, motionPreference].forEach((preference) => {
    preference.addEventListener("change", () => {
      roots().forEach((root) => {
        if (root.getAttribute(ATTR_THEME) === "system") {
          apply(root, "system");
        } else if (preference === motionPreference) {
          apply(root, root.getAttribute(ATTR_THEME));
        }
      });
    });
  });

  document.addEventListener("click", (event) => {
    const control = event.target.closest("[data-obpt-theme-choice]");

    if (control) {
      setTheme(control.getAttribute("data-obpt-theme-choice"));
    }
  });

  document.addEventListener("pointerover", (event) => {
    openTooltip(scopedTooltipFor(event, TOOLTIP_TRIGGER_SELECTOR));
  });

  document.addEventListener("pointerout", (event) => {
    const tooltip = scopedTooltipFor(event, TOOLTIP_TRIGGER_SELECTOR);

    if (tooltip && leavingTooltip(event, tooltip)) {
      closeTooltip(tooltip);
    }
  });

  document.addEventListener("focusin", (event) => {
    openTooltip(scopedTooltipFor(event, TOOLTIP_TRIGGER_SELECTOR));
  });

  document.addEventListener("focusout", (event) => {
    const tooltip = scopedTooltipFor(event);

    if (tooltip && leavingTooltip(event, tooltip)) {
      closeTooltip(tooltip);
    }
  });

  document.addEventListener("keydown", (event) => {
    if (event.key !== "Escape") {
      return;
    }

    const tooltip = scopedTooltipFor(event);

    if (!tooltip) {
      return;
    }

    closeTooltip(tooltip, true);

    const trigger = tooltipTrigger(tooltip);

    if (trigger && trigger.focus) {
      trigger.focus();
    }
  });

  window.ObanPowertoolsTheme = {
    apply,
    setTheme,
    storedTheme,
    effectiveTheme
  };
})();
