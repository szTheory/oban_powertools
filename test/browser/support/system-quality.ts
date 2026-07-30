import type { Page } from "@playwright/test";

const MAX_DIAGNOSTICS = 100;
const MAX_DOM_NODES = 2_000;
const INTERACTIVE_SELECTOR =
  'a[href], button, input, select, textarea, summary, [role="button"], [role="link"]';

type Diagnostic = {
  target: string;
  selector: string;
  project?: string;
  viewport?: string;
};

type ContrastKind =
  | "normal-text"
  | "large-text"
  | "muted-text"
  | "non-text"
  | "high-contrast-text";

type Rgba = { red: number; green: number; blue: number; alpha: number };

export type ContrastResult = {
  ratio: number;
  minimum: number;
  passes: boolean;
  resolvedForeground: string;
  resolvedBackground: string;
};

export function evaluateContrast(
  input: Diagnostic & {
    foreground: string;
    background: string;
    ancestorBackgrounds?: string[];
    kind: ContrastKind;
  },
): ContrastResult {
  const chain = input.ancestorBackgrounds ?? ["rgb(255, 255, 255)"];
  let resolvedBackground = opaqueBase(chain[chain.length - 1], input);

  for (let index = chain.length - 2; index >= 0; index -= 1) {
    resolvedBackground = composite(
      parseColor(chain[index], input),
      resolvedBackground,
    );
  }

  resolvedBackground = composite(
    parseColor(input.background, input),
    resolvedBackground,
  );
  const resolvedForeground = composite(
    parseColor(input.foreground, input),
    resolvedBackground,
  );
  const minimum = contrastMinimum(input.kind);
  const ratio = contrastRatio(resolvedForeground, resolvedBackground);

  return {
    ratio,
    minimum,
    passes: ratio >= minimum,
    resolvedForeground: rgbString(resolvedForeground),
    resolvedBackground: rgbString(resolvedBackground),
  };
}

function contrastMinimum(kind: ContrastKind): number {
  switch (kind) {
    case "large-text":
    case "non-text":
      return 3;
    case "high-contrast-text":
      return 7;
    case "normal-text":
    case "muted-text":
      return 4.5;
  }
}

function parseColor(value: string, diagnostic: Diagnostic): Rgba {
  if (/gradient|url\(|color-mix|var\(/i.test(value)) {
    throw new Error(
      `${diagnostic.target} ${diagnostic.selector}: unknown color adjacency (${value}); gradient/indirect colors fail closed`,
    );
  }

  const match = value
    .trim()
    .match(
      /^rgba?\(\s*([\d.]+)[,\s]+([\d.]+)[,\s]+([\d.]+)(?:\s*[,/]\s*([\d.]+%?))?\s*\)$/i,
    );
  if (!match) {
    throw new Error(
      `${diagnostic.target} ${diagnostic.selector}: unknown color syntax ${JSON.stringify(value)}`,
    );
  }

  const alphaValue = match[4];
  const alpha = alphaValue
    ? alphaValue.endsWith("%")
      ? Number.parseFloat(alphaValue) / 100
      : Number.parseFloat(alphaValue)
    : 1;
  const channels = match.slice(1, 4).map(Number);

  if (
    channels.some(
      (channel) => !Number.isFinite(channel) || channel < 0 || channel > 255,
    ) ||
    !Number.isFinite(alpha) ||
    alpha < 0 ||
    alpha > 1
  ) {
    throw new Error(
      `${diagnostic.target} ${diagnostic.selector}: invalid color channel in ${JSON.stringify(value)}`,
    );
  }

  return { red: channels[0], green: channels[1], blue: channels[2], alpha };
}

function opaqueBase(value: string, diagnostic: Diagnostic): Rgba {
  const parsed = parseColor(value, diagnostic);
  if (parsed.alpha !== 1) {
    throw new Error(
      `${diagnostic.target} ${diagnostic.selector}: ancestor color stack did not resolve to an opaque color`,
    );
  }
  return parsed;
}

function composite(foreground: Rgba, background: Rgba): Rgba {
  const alpha = foreground.alpha + background.alpha * (1 - foreground.alpha);
  if (alpha === 0) {
    return { red: 0, green: 0, blue: 0, alpha: 0 };
  }

  return {
    red:
      (foreground.red * foreground.alpha +
        background.red * background.alpha * (1 - foreground.alpha)) /
      alpha,
    green:
      (foreground.green * foreground.alpha +
        background.green * background.alpha * (1 - foreground.alpha)) /
      alpha,
    blue:
      (foreground.blue * foreground.alpha +
        background.blue * background.alpha * (1 - foreground.alpha)) /
      alpha,
    alpha,
  };
}

function contrastRatio(left: Rgba, right: Rgba): number {
  const leftLuminance = luminance(left);
  const rightLuminance = luminance(right);
  const lighter = Math.max(leftLuminance, rightLuminance);
  const darker = Math.min(leftLuminance, rightLuminance);
  return (lighter + 0.05) / (darker + 0.05);
}

function luminance(color: Rgba): number {
  const linear = [color.red, color.green, color.blue].map((channel) => {
    const normalized = channel / 255;
    return normalized <= 0.04045
      ? normalized / 12.92
      : ((normalized + 0.055) / 1.055) ** 2.4;
  });
  return linear[0] * 0.2126 + linear[1] * 0.7152 + linear[2] * 0.0722;
}

function rgbString(color: Rgba): string {
  return `rgb(${Math.round(color.red)}, ${Math.round(color.green)}, ${Math.round(color.blue)})`;
}

type TargetRect = {
  selector: string;
  x: number;
  y: number;
  width: number;
  height: number;
};

type TargetException = {
  selector: string;
  kind: string;
  review: string;
};

export function evaluateTargetGeometry(input: {
  target: string;
  viewport: string;
  targets: TargetRect[];
  exceptions: TargetException[];
  comfortSelectors: string[];
}): {
  violations: string[];
  decisions: Array<{ selector: string; exception: string }>;
} {
  const violations: string[] = [];
  const decisions: Array<{ selector: string; exception: string }> = [];
  const knownKinds = new Set(["spacing", "inline", "essential"]);
  const targetsBySelector = new Map(
    input.targets.map((target) => [target.selector, target]),
  );
  const exceptionsBySelector = new Map<string, TargetException>();

  for (const exception of input.exceptions) {
    if (!knownKinds.has(exception.kind)) {
      violations.push(
        `${input.target} ${exception.selector}: ${exception.kind} is an unknown target exception`,
      );
      continue;
    }
    if (exceptionsBySelector.has(exception.selector)) {
      violations.push(
        `${input.target} ${exception.selector}: duplicate target exception`,
      );
      continue;
    }
    if (!targetsBySelector.has(exception.selector)) {
      violations.push(
        `${input.target} ${exception.selector}: unused target exception`,
      );
      continue;
    }
    if (!exception.review.trim()) {
      violations.push(
        `${input.target} ${exception.selector}: exception has no review reference`,
      );
      continue;
    }
    exceptionsBySelector.set(exception.selector, exception);
  }

  for (let leftIndex = 0; leftIndex < input.targets.length; leftIndex += 1) {
    const left = input.targets[leftIndex];
    for (
      let rightIndex = leftIndex + 1;
      rightIndex < input.targets.length;
      rightIndex += 1
    ) {
      const right = input.targets[rightIndex];
      if (rectanglesOverlap(left, right)) {
        violations.push(
          `${input.target} ${input.viewport}: overlap between ${left.selector} and ${right.selector}`,
        );
      }
    }
  }

  for (const target of input.targets) {
    const comfort = input.comfortSelectors.includes(target.selector);
    if (comfort && Math.max(target.width, target.height) < 44) {
      violations.push(
        `${input.target} ${target.selector}: comfort target requires 44px in one axis; measured ${target.width}x${target.height}`,
      );
    }

    if (target.width >= 24 && target.height >= 24) {
      continue;
    }

    const exception = exceptionsBySelector.get(target.selector);
    if (!exception) {
      const neighbors = input.targets.filter(
        (candidate) => candidate !== target,
      );
      const hasAutomaticSpacing =
        neighbors.length > 0 &&
        neighbors.every((neighbor) => {
          const centerDistance = Math.hypot(
            target.x + target.width / 2 - (neighbor.x + neighbor.width / 2),
            target.y + target.height / 2 - (neighbor.y + neighbor.height / 2),
          );
          const nearestRectDistance = distancePointToRect(
            { x: target.x + target.width / 2, y: target.y + target.height / 2 },
            neighbor,
          );
          return neighbor.width < 24 || neighbor.height < 24
            ? centerDistance >= 24
            : nearestRectDistance >= 12;
        });
      if (hasAutomaticSpacing) {
        continue;
      }
      violations.push(
        `${input.target} ${target.selector}: measured ${target.width}x${target.height}; requires 24x24 or an exact reviewed exception`,
      );
      continue;
    }

    decisions.push({ selector: target.selector, exception: exception.kind });
    if (exception.kind !== "spacing") {
      continue;
    }

    for (const neighbor of input.targets) {
      if (neighbor === target) continue;
      const center = {
        x: target.x + target.width / 2,
        y: target.y + target.height / 2,
      };
      const neighborCenter = {
        x: neighbor.x + neighbor.width / 2,
        y: neighbor.y + neighbor.height / 2,
      };
      const centerDistance = Math.hypot(
        center.x - neighborCenter.x,
        center.y - neighborCenter.y,
      );
      const nearestRectDistance = distancePointToRect(center, neighbor);

      if (
        (neighbor.width < 24 || neighbor.height < 24) &&
        centerDistance < 24
      ) {
        violations.push(
          `${input.target} ${target.selector} to ${neighbor.selector}: 24px spacing circles intersect; measured center distance ${centerDistance}`,
        );
      } else if (
        neighbor.width >= 24 &&
        neighbor.height >= 24 &&
        nearestRectDistance < 12
      ) {
        violations.push(
          `${input.target} ${target.selector} to ${neighbor.selector}: radius 12px spacing circle intersects target; measured nearest distance ${nearestRectDistance}`,
        );
      }
    }
  }

  return {
    violations: violations.slice(0, MAX_DIAGNOSTICS),
    decisions: decisions.slice(0, MAX_DIAGNOSTICS),
  };
}

function rectanglesOverlap(left: TargetRect, right: TargetRect): boolean {
  return (
    left.x < right.x + right.width &&
    left.x + left.width > right.x &&
    left.y < right.y + right.height &&
    left.y + left.height > right.y
  );
}

function distancePointToRect(
  point: { x: number; y: number },
  rect: TargetRect,
): number {
  const dx = Math.max(rect.x - point.x, 0, point.x - (rect.x + rect.width));
  const dy = Math.max(rect.y - point.y, 0, point.y - (rect.y + rect.height));
  return Math.hypot(dx, dy);
}

export async function auditFocusedElement(
  page: Page,
  options: Diagnostic & { minimumThickness: number; minimumContrast: number },
): Promise<{
  selector: string;
  visible: true;
  thickness: number;
  contrast: number;
}> {
  const measurement = await page.evaluate(
    ({ selector, maxNodes }) => {
      const expected = document.querySelector(selector);
      const active = document.activeElement;
      if (!expected || !active || active !== expected || !active.isConnected) {
        return { error: `${selector} is not the connected activeElement` };
      }

      const element = active as HTMLElement;
      const rect = element.getBoundingClientRect();
      const intersection = {
        left: Math.max(0, rect.left),
        top: Math.max(0, rect.top),
        right: Math.min(window.innerWidth, rect.right),
        bottom: Math.min(window.innerHeight, rect.bottom),
      };
      if (
        intersection.right <= intersection.left ||
        intersection.bottom <= intersection.top
      ) {
        return { error: `${selector} has no viewport intersection` };
      }

      const style = getComputedStyle(element);
      const thickness = Number.parseFloat(style.outlineWidth) || 0;
      const outlineColor = style.outlineColor;
      const backgroundColor = style.backgroundColor;
      const inset = 2;
      const points = [
        [
          (intersection.left + intersection.right) / 2,
          (intersection.top + intersection.bottom) / 2,
        ],
        [intersection.left + inset, intersection.top + inset],
        [intersection.right - inset, intersection.top + inset],
        [intersection.left + inset, intersection.bottom - inset],
        [intersection.right - inset, intersection.bottom - inset],
      ];
      let occluder = "";
      let operable = false;
      for (const [x, y] of points.slice(0, Math.min(points.length, maxNodes))) {
        const hit = document.elementFromPoint(x, y);
        if (hit === element || (hit instanceof Node && element.contains(hit))) {
          operable = true;
          break;
        }
        if (hit instanceof Element) {
          occluder = hit.id ? `#${hit.id}` : hit.tagName.toLowerCase();
        }
      }

      if (!operable) {
        return {
          error: `${selector} is occluded by ${occluder || "unknown overlay"} in fixed/top-layer hit-test`,
        };
      }

      return { thickness, outlineColor, backgroundColor };
    },
    { selector: options.selector, maxNodes: 5 },
  );

  if ("error" in measurement) {
    throw new Error(`${options.target} ${measurement.error}`);
  }

  const contrast = evaluateContrast({
    ...options,
    foreground: measurement.outlineColor,
    background: measurement.backgroundColor,
    kind: "non-text",
  }).ratio;

  if (
    measurement.thickness < options.minimumThickness ||
    contrast < options.minimumContrast
  ) {
    throw new Error(
      `${options.target} ${options.selector}: focus indicator ${measurement.thickness}px requires ${options.minimumThickness}px; contrast ${contrast} requires ${options.minimumContrast}`,
    );
  }

  return {
    selector: options.selector,
    visible: true,
    thickness: measurement.thickness,
    contrast,
  };
}

export async function restoreFocus(
  page: Page,
  options: Diagnostic & { preferred: string; fallback: string },
): Promise<{ restored: string; mechanism: "preferred" | "fallback" }> {
  const result = await page.evaluate(({ preferred, fallback }) => {
    const preferredElement = document.querySelector<HTMLElement>(preferred);
    if (preferredElement?.isConnected) {
      preferredElement.focus();
      return { restored: preferred, mechanism: "preferred" as const };
    }
    const fallbackElement = document.querySelector<HTMLElement>(fallback);
    if (!fallbackElement?.isConnected) {
      throw new Error(`${preferred} and fallback ${fallback} are unavailable`);
    }
    fallbackElement.focus();
    return { restored: fallback, mechanism: "fallback" as const };
  }, options);

  return result;
}

export async function auditReflow(
  page: Page,
  options: Diagnostic & {
    pageSelector: string;
    machineScrollerSelector?: string;
  },
): Promise<{ overflowOwners: string[] }> {
  const result = await page.evaluate(
    ({ pageSelector, machineScrollerSelector, maxNodes }) => {
      const root = document.querySelector<HTMLElement>(pageSelector);
      if (!root) return { errors: [`${pageSelector} is missing`], owners: [] };

      const errors: string[] = [];
      const viewportWidth = document.documentElement.clientWidth;
      for (const [name, element] of [
        ["document", document.documentElement],
        ["body", document.body],
        [pageSelector, root],
      ] as const) {
        if (
          element &&
          element.scrollWidth > Math.max(element.clientWidth, viewportWidth) + 1
        ) {
          errors.push(
            `${pageSelector} overflow at ${name}: scrollWidth=${element.scrollWidth}, viewport=${viewportWidth}`,
          );
        }
      }

      if (
        root.querySelector("[data-obpt-mobile-copy]") &&
        root.querySelector("[data-obpt-desktop-copy]")
      ) {
        errors.push(`${pageSelector} contains a duplicate responsive tree`);
      }

      const owners: string[] = [];
      if (machineScrollerSelector) {
        const candidates = Array.from(
          root.querySelectorAll<HTMLElement>(machineScrollerSelector),
        ).slice(0, maxNodes);
        for (const candidate of candidates) {
          if (candidate.scrollWidth <= candidate.clientWidth + 1) continue;
          const named =
            Boolean(candidate.getAttribute("aria-label")?.trim()) ||
            Boolean(candidate.getAttribute("aria-labelledby")?.trim());
          const focusable = candidate.tabIndex >= 0;
          const action = candidate.querySelector(
            'button, a[href], input, select, textarea, [role="button"], [role="link"]',
          );
          if (!named || !focusable || action) {
            errors.push(
              `${pageSelector} machine scroller must have a name/label, be focusable, and contain no ordinary button/action`,
            );
          } else {
            owners.push(machineScrollerSelector);
          }
        }
      }

      return { errors, owners };
    },
    {
      pageSelector: options.pageSelector,
      machineScrollerSelector: options.machineScrollerSelector,
      maxNodes: MAX_DOM_NODES,
    },
  );

  if (result.errors.length > 0) {
    throw new Error(
      `${options.target} ${result.errors.slice(0, MAX_DIAGNOSTICS).join("; ")}`,
    );
  }
  return { overflowOwners: result.owners };
}

export async function with200PercentZoom<T>(
  page: Page,
  _options: Diagnostic,
  operation: () => Promise<T>,
): Promise<T> {
  const viewport = page.viewportSize();
  const session = await page.context().newCDPSession(page);
  try {
    if (viewport) {
      await session.send("Emulation.setDeviceMetricsOverride", {
        width: Math.max(1, Math.floor(viewport.width / 2)),
        height: Math.max(1, Math.floor(viewport.height / 2)),
        deviceScaleFactor: 1,
        mobile: false,
      });
    }
    return await operation();
  } finally {
    await session
      .send("Emulation.clearDeviceMetricsOverride")
      .catch(() => undefined);
    if (viewport && page.viewportSize() !== viewport) {
      await page.setViewportSize(viewport);
    }
    await session.detach().catch(() => undefined);
  }
}

export async function auditReducedMotion(
  page: Page,
  options: Diagnostic & {
    rootSelector: string;
    auditSelector?: string;
    mechanism: "os" | "root";
    maximumDurationMs: number;
    requiredVisible: string[];
  },
): Promise<{
  mechanism: "os" | "root";
  hiddenRequired: string[];
  delayedActions: string[];
}> {
  const original = await page.evaluate((rootSelector) => {
    const root = document.querySelector(rootSelector);
    return {
      motion: root?.getAttribute("data-obpt-motion") ?? null,
      reducedMotion: matchMedia("(prefers-reduced-motion: reduce)").matches,
    };
  }, options.rootSelector);

  try {
    await page.emulateMedia({
      reducedMotion: options.mechanism === "os" ? "reduce" : "no-preference",
    });
    await page.evaluate(
      () =>
        new Promise<void>((resolve) =>
          requestAnimationFrame(() => requestAnimationFrame(() => resolve())),
        ),
    );
    await page.locator(options.rootSelector).evaluate((root, mechanism) => {
      if (mechanism === "root") root.setAttribute("data-obpt-motion", "reduce");
      else root.removeAttribute("data-obpt-motion");
    }, options.mechanism);

    const report = await page.evaluate(
      ({
        rootSelector,
        auditSelector,
        requiredVisible,
        maximumDurationMs,
        maxNodes,
      }) => {
        const root = document.querySelector<HTMLElement>(
          auditSelector ?? rootSelector,
        );
        if (!root)
          throw new Error(`${auditSelector ?? rootSelector} is missing`);
        const hiddenRequired: string[] = [];
        for (const selector of requiredVisible.slice(0, maxNodes)) {
          const element = document.querySelector<HTMLElement>(selector);
          if (
            !element ||
            !(element === root || root.contains(element)) ||
            element.hidden ||
            getComputedStyle(element).display === "none" ||
            getComputedStyle(element).visibility === "hidden"
          ) {
            hiddenRequired.push(selector);
          }
        }

        const delayedActions: string[] = [];
        for (const element of Array.from(
          root.querySelectorAll<HTMLElement>("*"),
        ).slice(0, maxNodes)) {
          const style = getComputedStyle(element);
          const values = [
            ...style.animationDuration.split(","),
            ...style.animationDelay.split(","),
            ...style.transitionDuration.split(","),
            ...style.transitionDelay.split(","),
          ];
          const longest = Math.max(
            0,
            ...values.map((value) => {
              const trimmed = value.trim();
              return trimmed.endsWith("ms")
                ? Number.parseFloat(trimmed)
                : Number.parseFloat(trimmed) * 1_000;
            }),
          );
          if (longest > maximumDurationMs) {
            const selector = element.id
              ? `#${element.id}`
              : element.classList.length
                ? `.${Array.from(element.classList).join(".")}`
                : element.tagName.toLowerCase();
            delayedActions.push(
              `${selector}: ${longest}ms > ${maximumDurationMs}ms`,
            );
          }
        }
        return { hiddenRequired, delayedActions };
      },
      {
        rootSelector: options.rootSelector,
        auditSelector: options.auditSelector,
        requiredVisible: options.requiredVisible,
        maximumDurationMs: options.maximumDurationMs,
        maxNodes: MAX_DOM_NODES,
      },
    );

    if (report.hiddenRequired.length || report.delayedActions.length) {
      throw new Error(
        `${options.target} ${options.selector} ${options.mechanism} reduced motion failed: hidden=${report.hiddenRequired.join(",")}; delayed=${report.delayedActions.join(",")}`,
      );
    }
    return { mechanism: options.mechanism, ...report };
  } finally {
    await page.emulateMedia({
      reducedMotion: original.reducedMotion ? "reduce" : "no-preference",
    });
    await page.evaluate(
      () =>
        new Promise<void>((resolve) =>
          requestAnimationFrame(() => requestAnimationFrame(() => resolve())),
        ),
    );
    await page.locator(options.rootSelector).evaluate((root, motion) => {
      if (motion === null) root.removeAttribute("data-obpt-motion");
      else root.setAttribute("data-obpt-motion", motion);
    }, original.motion);
  }
}

type ThemeRole = { selector: string; properties: string[] };
type ThemeMatrixCase = {
  colorScheme: "light" | "dark";
  contrast: "no-preference" | "more";
  expectedTheme: "light" | "dark" | "high-contrast";
};

export async function auditSystemTheme(
  page: Page,
  options: Diagnostic & {
    rootSelector: string;
    roles: ThemeRole[];
    matrix: ThemeMatrixCase[];
  },
): Promise<{
  cases: Array<
    ThemeMatrixCase & {
      actualRoles: Array<{
        selector: string;
        properties: Record<string, string>;
      }>;
      expectedRoles: Array<{
        selector: string;
        properties: Record<string, string>;
      }>;
    }
  >;
}> {
  if (options.roles.length > 64 || options.matrix.length > 8) {
    throw new Error(
      `${options.target}: system theme audit exceeds bounded role/matrix limits`,
    );
  }

  const original = await page.evaluate((rootSelector) => {
    const root = document.querySelector(rootSelector);
    if (!root) throw new Error(`${rootSelector} is missing`);
    return {
      theme: root.getAttribute("data-obpt-theme"),
      motion: root.getAttribute("data-obpt-motion"),
      colorScheme: matchMedia("(prefers-color-scheme: dark)").matches
        ? "dark"
        : "light",
      contrast: matchMedia("(prefers-contrast: more)").matches
        ? "more"
        : "no-preference",
    } as const;
  }, options.rootSelector);

  const snapshot = async () =>
    page.evaluate((roles) => {
      return roles.map(({ selector, properties }) => {
        const element = document.querySelector(selector);
        if (!element) throw new Error(`${selector} is missing`);
        const style = getComputedStyle(element);
        return {
          selector,
          properties: Object.fromEntries(
            properties.map((property) => [
              property,
              property.startsWith("--")
                ? style.getPropertyValue(property).trim()
                : (style as unknown as Record<string, string>)[property],
            ]),
          ),
        };
      });
    }, options.roles);

  const cases = [];
  try {
    for (const matrixCase of options.matrix) {
      await page.emulateMedia({
        colorScheme: matrixCase.colorScheme,
        contrast: matrixCase.contrast,
      });
      await page
        .locator(options.rootSelector)
        .evaluate(
          (root, theme) => root.setAttribute("data-obpt-theme", theme),
          matrixCase.expectedTheme,
        );
      const expectedRoles = await snapshot();

      await page
        .locator(options.rootSelector)
        .evaluate((root) => root.setAttribute("data-obpt-theme", "system"));
      const actualRoles = await snapshot();
      cases.push({ ...matrixCase, actualRoles, expectedRoles });
    }
    return { cases };
  } finally {
    await page.locator(options.rootSelector).evaluate((root, state) => {
      if (state.theme === null) root.removeAttribute("data-obpt-theme");
      else root.setAttribute("data-obpt-theme", state.theme);
      if (state.motion === null) root.removeAttribute("data-obpt-motion");
      else root.setAttribute("data-obpt-motion", state.motion);
    }, original);
    await page.emulateMedia({
      colorScheme: original.colorScheme,
      contrast: original.contrast,
    });
  }
}

export async function auditSystemQuality(
  page: Page,
  options: {
    diagnostic: Diagnostic;
    focus?: { minimumThickness: number; minimumContrast: number };
    reflow?: { pageSelector: string; machineScrollerSelector?: string };
    motion?: {
      rootSelector: string;
      maximumDurationMs: number;
      requiredVisible: string[];
    };
  },
): Promise<void> {
  if (options.focus) {
    await auditFocusedElement(page, {
      ...options.diagnostic,
      ...options.focus,
    });
  }
  if (options.reflow) {
    await auditReflow(page, { ...options.diagnostic, ...options.reflow });
  }
  if (options.motion) {
    for (const mechanism of ["os", "root"] as const) {
      await auditReducedMotion(page, {
        ...options.diagnostic,
        ...options.motion,
        mechanism,
      });
    }
  }
}

export async function collectInteractiveTargetGeometry(
  page: Page,
  rootSelector: string,
): Promise<TargetRect[]> {
  return page.evaluate(
    ({ rootSelector, interactiveSelector, maxNodes }) => {
      const root = document.querySelector(rootSelector);
      if (!root) throw new Error(`${rootSelector} is missing`);
      return Array.from(root.querySelectorAll<HTMLElement>(interactiveSelector))
        .slice(0, maxNodes)
        .filter((element) => {
          const style = getComputedStyle(element);
          const closedDetails = element.closest<HTMLDetailsElement>(
            "details:not([open])",
          );
          const visibleClosedSummary =
            closedDetails?.querySelector(":scope > summary") === element;
          return (
            style.display !== "none" &&
            style.visibility !== "hidden" &&
            (!closedDetails || visibleClosedSummary) &&
            element.getClientRects().length > 0
          );
        })
        .map((element, index) => {
          const rect = element.getBoundingClientRect();
          return {
            selector: element.id
              ? `#${element.id}`
              : `${element.tagName.toLowerCase()}:nth-target(${index + 1})`,
            x: rect.x,
            y: rect.y,
            width: rect.width,
            height: rect.height,
          };
        });
    },
    {
      rootSelector,
      interactiveSelector: INTERACTIVE_SELECTOR,
      maxNodes: MAX_DOM_NODES,
    },
  );
}
