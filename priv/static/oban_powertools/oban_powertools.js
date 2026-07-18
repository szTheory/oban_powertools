(() => {
  const STORAGE_KEY = "oban_powertools:theme";
  const THEMES = new Set(["system", "light", "dark", "high-contrast"]);
  const ATTR_THEME = "data-obpt-theme";
  const ATTR_EFFECTIVE_THEME = "data-obpt-effective-theme";
  const ATTR_MOTION = "data-obpt-motion";
  const ATTR_TOOLTIP_OPEN = "data-obpt-tooltip-open";
  const ATTR_TOOLTIP_DISMISSED = "data-obpt-tooltip-dismissed";
  const ATTR_NAV_STATE = "data-obpt-nav-state";
  const ATTR_FILTER_STATE = "data-obpt-filter-state";
  const ROOT_SELECTOR = ".obpt-root";
  const THEME_CHOICE_SELECTOR = "[data-obpt-theme-choice]";
  const TOOLTIP_SELECTOR = "[data-obpt-tooltip]";
  const TOOLTIP_TRIGGER_SELECTOR = "[data-obpt-tooltip-trigger]";
  const APP_SHELL_SELECTOR = "[data-obpt-app-shell]";
  const NAV_TOGGLE_SELECTOR = "[data-obpt-nav-toggle]";
  const PRIMARY_NAV_SELECTOR = "[data-obpt-primary-nav]";
  const FILTER_BAR_SELECTOR = "[data-obpt-filter-bar]";
  const FILTER_TOGGLE_SELECTOR = "[data-obpt-filter-toggle]";
  const FILTER_FIELDS_SELECTOR = "[data-obpt-filter-fields]";
  const DETAIL_SURFACE_SELECTOR = "[data-obpt-detail-surface]";
  const DETAIL_CLOSE_SELECTOR = "[data-obpt-detail-close]";
  const FOCUS_OWNER_SELECTOR = "[data-obpt-focus-fallback]";
  const CONTROLLED_TRIGGER_SELECTOR = "[aria-controls]";

  const colorPreference = window.matchMedia("(prefers-color-scheme: dark)");
  const contrastPreference = window.matchMedia("(prefers-contrast: more)");
  const motionPreference = window.matchMedia("(prefers-reduced-motion: reduce)");
  const narrowFilterPresentation = window.matchMedia("(max-width: 47.999rem)");
  const DETAIL_WIDE_QUERY = window.matchMedia("(min-width: 64rem)");
  const pendingControlledInvokers = new WeakMap();
  const ownedInvokers = new WeakMap();
  const ownerRoots = new WeakMap();
  const preparedDetailSurfaces = new WeakSet();
  const programmaticDetailClosures = new WeakSet();

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
    syncThemeControls(root, requestedTheme);
    syncNavDisclosures(root);
    syncFilterDisclosures(root);
    syncOwnedInvokers(root);
    syncDetailSurfaces(root);
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

  function rootForElement(element) {
    if (!element || !element.closest) {
      return null;
    }

    return element.closest(ROOT_SELECTOR);
  }

  function shellForElement(element) {
    if (!element || !element.closest) {
      return null;
    }

    const root = rootForElement(element);
    const shell = element.closest(APP_SHELL_SELECTOR);

    if (!root || !shell || !root.contains(shell)) {
      return null;
    }

    return shell;
  }

  function navToggle(shell) {
    return shell ? shell.querySelector(NAV_TOGGLE_SELECTOR) : null;
  }

  function primaryNav(shell) {
    return shell ? shell.querySelector(PRIMARY_NAV_SELECTOR) : null;
  }

  function normalizeNavState(state) {
    return state === "open" ? "open" : "closed";
  }

  function setNavState(shell, state) {
    if (!shell) {
      return;
    }

    const nextState = normalizeNavState(state);
    const expanded = nextState === "open";
    const toggle = navToggle(shell);

    shell.setAttribute(ATTR_NAV_STATE, nextState);

    if (toggle) {
      toggle.setAttribute("aria-expanded", expanded ? "true" : "false");
    }
  }

  function toggleNav(shell) {
    const currentState = shell ? shell.getAttribute(ATTR_NAV_STATE) : "closed";
    setNavState(shell, currentState === "open" ? "closed" : "open");
  }

  function syncNavDisclosures(root) {
    Array.from(root.querySelectorAll(APP_SHELL_SELECTOR)).forEach((shell) => {
      setNavState(shell, shell.getAttribute(ATTR_NAV_STATE));
    });
  }

  function focusInsideNavDisclosure(shell, target) {
    const toggle = navToggle(shell);
    const nav = primaryNav(shell);

    return Boolean((toggle && toggle.contains(target)) || (nav && nav.contains(target)));
  }

  function filterBarForElement(element) {
    if (!element || !element.closest) {
      return null;
    }

    const root = rootForElement(element);
    const filterBar = element.closest(FILTER_BAR_SELECTOR);

    if (!root || !filterBar || !root.contains(filterBar)) {
      return null;
    }

    return filterBar;
  }

  function filterToggle(filterBar) {
    return filterBar ? filterBar.querySelector(FILTER_TOGGLE_SELECTOR) : null;
  }

  function filterFields(filterBar) {
    return filterBar ? filterBar.querySelector(FILTER_FIELDS_SELECTOR) : null;
  }

  function normalizeFilterState(state) {
    return state === "open" ? "open" : "closed";
  }

  function setFilterState(filterBar, state) {
    const root = rootForElement(filterBar);

    if (
      !root ||
      !filterBar ||
      !filterBar.matches ||
      !filterBar.matches(FILTER_BAR_SELECTOR) ||
      !root.contains(filterBar)
    ) {
      return;
    }

    const nextState = normalizeFilterState(state);
    const expanded = nextState === "open";
    const collapsedAtNarrowWidth = narrowFilterPresentation.matches && !expanded;
    const toggle = filterToggle(filterBar);
    const fields = filterFields(filterBar);

    filterBar.setAttribute(ATTR_FILTER_STATE, nextState);

    if (toggle) {
      toggle.setAttribute("aria-expanded", expanded ? "true" : "false");
    }

    if (fields) {
      fields.toggleAttribute("hidden", collapsedAtNarrowWidth);
      fields.toggleAttribute("inert", collapsedAtNarrowWidth);
    }
  }

  function toggleFilterState(filterBar) {
    const currentState = filterBar ? filterBar.getAttribute(ATTR_FILTER_STATE) : "closed";
    setFilterState(filterBar, currentState === "open" ? "closed" : "open");
  }

  function syncFilterDisclosures(root) {
    if (!root || !root.matches || !root.matches(ROOT_SELECTOR)) {
      return;
    }

    Array.from(root.querySelectorAll(FILTER_BAR_SELECTOR)).forEach((filterBar) => {
      setFilterState(filterBar, filterBar.getAttribute(ATTR_FILTER_STATE));
    });
  }

  function ownedElementWithId(root, id) {
    if (!root || !id) {
      return null;
    }

    return (
      Array.from(root.querySelectorAll(FOCUS_OWNER_SELECTOR)).find(
        (owner) => owner.id === id
      ) || null
    );
  }

  function elementWithId(root, id) {
    if (!root || !id) {
      return null;
    }

    if (root.id === id) {
      return root;
    }

    return Array.from(root.querySelectorAll("[id]")).find((element) => element.id === id) || null;
  }

  function focusableInRoot(element, root) {
    return Boolean(
      element &&
        root &&
        element.isConnected &&
        root.contains(element) &&
        typeof element.focus === "function" &&
        !element.hasAttribute("disabled") &&
        !element.closest("[hidden], [inert]")
    );
  }

  function rememberControlledInvoker(control) {
    const root = rootForElement(control);
    const controlledId = control ? control.getAttribute("aria-controls") : null;

    if (
      !root ||
      !controlledId ||
      control.matches(FILTER_TOGGLE_SELECTOR) ||
      control.matches(NAV_TOGGLE_SELECTOR)
    ) {
      return;
    }

    const owner = ownedElementWithId(root, controlledId);

    if (owner) {
      ownedInvokers.set(owner, control);
      ownerRoots.set(owner, root);
      pendingControlledInvokers.delete(root);
    } else {
      pendingControlledInvokers.set(root, { controlledId, invoker: control });
    }
  }

  function syncOwnedInvokers(root) {
    if (!root || !root.matches || !root.matches(ROOT_SELECTOR)) {
      return;
    }

    const pending = pendingControlledInvokers.get(root);

    Array.from(root.querySelectorAll(FOCUS_OWNER_SELECTOR)).forEach((owner) => {
      ownerRoots.set(owner, root);

      if (pending && pending.controlledId === owner.id) {
        ownedInvokers.set(owner, pending.invoker);
        pendingControlledInvokers.delete(root);
      }
    });
  }

  function restoreOwnedFocus(owner) {
    if (!owner) {
      return;
    }

    const root = ownerRoots.get(owner) || rootForElement(owner);
    const invoker = ownedInvokers.get(owner);
    const fallbackId = owner.getAttribute("data-obpt-focus-fallback");
    const fallback = elementWithId(root, fallbackId);

    ownedInvokers.delete(owner);
    ownerRoots.delete(owner);

    if (root && owner.id) {
      const pending = pendingControlledInvokers.get(root);

      if (pending && pending.controlledId === owner.id) {
        pendingControlledInvokers.delete(root);
      }
    }

    if (focusableInRoot(invoker, root)) {
      invoker.focus({ preventScroll: true });
    } else if (focusableInRoot(fallback, root)) {
      fallback.focus({ preventScroll: true });
    }
  }

  function transferOrRestoreRemovedOwner(owner) {
    const root = ownerRoots.get(owner) || rootForElement(owner);
    const replacement = root && ownedElementWithId(root, owner.id);

    if (replacement && replacement !== owner) {
      const invoker = ownedInvokers.get(owner);

      if (invoker) {
        ownedInvokers.set(replacement, invoker);
      }

      ownerRoots.set(replacement, root);
      ownedInvokers.delete(owner);
      ownerRoots.delete(owner);
    } else {
      restoreOwnedFocus(owner);
    }
  }

  function restoreRemovedOwners(mutations) {
    const removedOwners = new Set();

    mutations.forEach((mutation) => {
      mutation.removedNodes.forEach((node) => {
        if (!node || node.nodeType !== 1) {
          return;
        }

        if (node.matches(FOCUS_OWNER_SELECTOR)) {
          removedOwners.add(node);
        }

        Array.from(node.querySelectorAll(FOCUS_OWNER_SELECTOR)).forEach((owner) =>
          removedOwners.add(owner)
        );
      });
    });

    removedOwners.forEach((owner) => transferOrRestoreRemovedOwner(owner));
  }

  function effectiveDetailMode(surface) {
    const variant = surface ? surface.getAttribute("data-obpt-detail-variant") : "adaptive";

    if (variant === "inline" || variant === "drawer") {
      return variant;
    }

    return DETAIL_WIDE_QUERY.matches ? "inline" : "drawer";
  }

  function detailIsModal(surface) {
    if (!surface || !surface.open || !surface.matches) {
      return false;
    }

    try {
      return surface.matches(":modal");
    } catch (_error) {
      return surface.getAttribute("aria-modal") === "true";
    }
  }

  function closeDetailSurface(surface) {
    if (surface && surface.open && typeof surface.close === "function") {
      programmaticDetailClosures.add(surface);
      surface.close();
    }
  }

  function requestParentDetailClose(surface) {
    const root = rootForElement(surface);
    const closeControl = surface ? surface.querySelector(DETAIL_CLOSE_SELECTOR) : null;

    if (root && closeControl && root.contains(closeControl) && typeof closeControl.click === "function") {
      closeControl.click();
    }
  }

  function prepareDetailSurface(surface) {
    if (preparedDetailSurfaces.has(surface)) {
      return;
    }

    preparedDetailSurfaces.add(surface);

    surface.addEventListener("cancel", (event) => {
      event.preventDefault();
      requestParentDetailClose(surface);
    });

    surface.addEventListener("close", () => {
      if (programmaticDetailClosures.has(surface)) {
        programmaticDetailClosures.delete(surface);
        return;
      }

      if (surface.getAttribute("data-obpt-detail-requested") === "open") {
        requestParentDetailClose(surface);
      }

      restoreOwnedFocus(surface);
    });
  }

  function syncDetailSurface(surface) {
    const root = rootForElement(surface);

    if (
      !root ||
      !surface ||
      !surface.matches ||
      !surface.matches(DETAIL_SURFACE_SELECTOR) ||
      surface.tagName !== "DIALOG" ||
      !root.contains(surface)
    ) {
      return;
    }

    ownerRoots.set(surface, root);
    prepareDetailSurface(surface);

    const requestedOpen = surface.getAttribute("data-obpt-detail-requested") === "open";
    const previousMode = surface.getAttribute("data-obpt-detail-mode");
    const nextMode = effectiveDetailMode(surface);
    const shouldBeModal = nextMode === "drawer";
    const activeElement = root.ownerDocument ? root.ownerDocument.activeElement : null;
    const retainedFocus = surface.contains(activeElement) ? activeElement : null;
    const nativeModeMismatch =
      surface.open && (detailIsModal(surface) ? "drawer" : "inline") !== nextMode;

    if (!requestedOpen) {
      closeDetailSurface(surface);
      surface.setAttribute("data-obpt-detail-mode", nextMode);
      surface.removeAttribute("aria-modal");
      restoreOwnedFocus(surface);
      return;
    }

    if (surface.open && (previousMode !== nextMode || nativeModeMismatch)) {
      closeDetailSurface(surface);
    }

    surface.setAttribute("data-obpt-detail-mode", nextMode);

    if (shouldBeModal) {
      surface.setAttribute("aria-modal", "true");

      if (!surface.open && typeof surface.showModal === "function") {
        surface.showModal();
      }
    } else {
      surface.removeAttribute("aria-modal");

      if (!surface.open && typeof surface.show === "function") {
        surface.show();
      }
    }

    if (retainedFocus && focusableInRoot(retainedFocus, root) && surface.contains(retainedFocus)) {
      retainedFocus.focus({ preventScroll: true });
    }
  }

  function syncDetailSurfaces(root) {
    if (!root || !root.matches || !root.matches(ROOT_SELECTOR)) {
      return;
    }

    syncOwnedInvokers(root);
    Array.from(root.querySelectorAll(DETAIL_SURFACE_SELECTOR)).forEach(syncDetailSurface);
  }

  function syncThemeControls(root, requestedTheme) {
    Array.from(root.querySelectorAll(THEME_CHOICE_SELECTOR)).forEach((control) => {
      const selected = control.getAttribute("data-obpt-theme-choice") === requestedTheme;
      control.setAttribute("aria-pressed", selected ? "true" : "false");
    });
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

  function rootsFromMutations(mutations) {
    const changedRoots = new Set();

    mutations.forEach((mutation) => {
      const targetRoot = rootForElement(mutation.target);

      if (targetRoot) {
        changedRoots.add(targetRoot);
      }

      mutation.addedNodes.forEach((node) => {
        if (!node || node.nodeType !== 1) {
          return;
        }

        if (node.matches(ROOT_SELECTOR)) {
          changedRoots.add(node);
        }

        const containingRoot = node.closest(ROOT_SELECTOR);

        if (containingRoot) {
          changedRoots.add(containingRoot);
        }

        Array.from(node.querySelectorAll(ROOT_SELECTOR)).forEach((root) => changedRoots.add(root));
      });
    });

    return changedRoots;
  }

  function observeScopedPatches() {
    if (!document.body || typeof window.MutationObserver !== "function") {
      return;
    }

    const observer = new window.MutationObserver((mutations) => {
      restoreRemovedOwners(mutations);

      rootsFromMutations(mutations).forEach((root) => {
        apply(root, root.getAttribute(ATTR_THEME) || storedTheme());
      });
    });

    observer.observe(document.body, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: [
        "aria-controls",
        "data-obpt-detail-requested",
        "data-obpt-detail-variant",
        "data-obpt-focus-fallback"
      ]
    });
  }

  const currentRoot =
    document.currentScript && document.currentScript.closest
      ? document.currentScript.closest(ROOT_SELECTOR)
      : null;

  if (currentRoot) {
    apply(currentRoot);
  }

  applyStoredTheme();

  if (document.readyState === "loading") {
    document.addEventListener(
      "DOMContentLoaded",
      () => {
        applyStoredTheme();
        observeScopedPatches();
      },
      { once: true }
    );
  } else {
    observeScopedPatches();
  }

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

  narrowFilterPresentation.addEventListener("change", () => {
    roots().forEach((root) => syncFilterDisclosures(root));
  });

  DETAIL_WIDE_QUERY.addEventListener("change", () => {
    roots().forEach((root) => syncDetailSurfaces(root));
  });

  document.addEventListener("click", (event) => {
    const controlledTrigger = closestElement(event, CONTROLLED_TRIGGER_SELECTOR);

    if (controlledTrigger) {
      rememberControlledInvoker(controlledTrigger);
    }

    const detailCloseControl = closestElement(event, DETAIL_CLOSE_SELECTOR);

    if (detailCloseControl) {
      const detailSurface = detailCloseControl.closest(DETAIL_SURFACE_SELECTOR);
      const root = rootForElement(detailCloseControl);

      if (detailSurface && root && root.contains(detailSurface)) {
        return;
      }
    }

    const filterControl = closestElement(event, FILTER_TOGGLE_SELECTOR);

    if (filterControl) {
      const filterBar = filterBarForElement(filterControl);

      if (filterBar) {
        event.preventDefault();
        toggleFilterState(filterBar);
        return;
      }
    }

    const navControl = closestElement(event, NAV_TOGGLE_SELECTOR);

    if (navControl) {
      const shell = shellForElement(navControl);

      if (shell) {
        event.preventDefault();
        toggleNav(shell);
        return;
      }
    }

    const control = closestElement(event, THEME_CHOICE_SELECTOR);

    if (control && rootForElement(control)) {
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

    const shell = shellForElement(event.target);

    if (
      shell &&
      shell.getAttribute(ATTR_NAV_STATE) === "open" &&
      focusInsideNavDisclosure(shell, event.target)
    ) {
      event.preventDefault();
      setNavState(shell, "closed");

      const toggle = navToggle(shell);

      if (toggle && toggle.focus) {
        toggle.focus();
      }

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
    effectiveTheme,
    setFilterState,
    syncFilterDisclosures,
    effectiveDetailMode,
    syncDetailSurface,
    syncDetailSurfaces,
    restoreOwnedFocus
  };
})();
