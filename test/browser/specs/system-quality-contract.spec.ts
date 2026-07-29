import { expect, test, type Page } from "@playwright/test";

type SystemQuality = typeof import("../support/system-quality");
type AxePolicy = typeof import("../support/axe");

async function quality(): Promise<SystemQuality> {
  return import("../support/system-quality");
}

async function axePolicy(): Promise<AxePolicy> {
  return import("../support/axe");
}

const diagnostic = {
  target: "fixture:system-quality",
  selector: "#subject",
  project: "chromium-wide",
};

test.describe("Phase 82 system quality contract", () => {
  test.describe("unrounded contrast and alpha composition", () => {
    const cases = [
      {
        name: "normal text passes at 4.5:1 without rounding",
        foreground: "rgb(118, 118, 118)",
        background: "rgb(255, 255, 255)",
        kind: "normal-text",
        minimum: 4.5,
        passes: true,
      },
      {
        name: "normal text just below 4.5:1 fails without rounding",
        foreground: "rgb(119, 119, 119)",
        background: "rgb(255, 255, 255)",
        kind: "normal-text",
        minimum: 4.5,
        passes: false,
      },
      {
        name: "large text uses the 3:1 threshold",
        foreground: "rgb(148, 148, 148)",
        background: "rgb(255, 255, 255)",
        kind: "large-text",
        minimum: 3,
        passes: true,
      },
      {
        name: "muted text retains the 4.5:1 floor when large",
        foreground: "rgb(148, 148, 148)",
        background: "rgb(255, 255, 255)",
        kind: "muted-text",
        minimum: 4.5,
        passes: false,
      },
      {
        name: "non-text control boundaries use adjacent 3:1",
        foreground: "rgb(148, 148, 148)",
        background: "rgb(255, 255, 255)",
        kind: "non-text",
        minimum: 3,
        passes: true,
      },
      {
        name: "high contrast body text uses 7:1",
        foreground: "rgb(89, 89, 89)",
        background: "rgb(255, 255, 255)",
        kind: "high-contrast-text",
        minimum: 7,
        passes: true,
      },
    ] as const;

    for (const fixture of cases) {
      test(fixture.name, async () => {
        const { evaluateContrast } = await quality();
        const result = evaluateContrast({
          foreground: fixture.foreground,
          background: fixture.background,
          kind: fixture.kind,
          ...diagnostic,
        });

        expect(result.minimum, `${fixture.name}: threshold`).toBe(
          fixture.minimum,
        );
        expect(result.passes, `${fixture.name}: measured=${result.ratio}`).toBe(
          fixture.passes,
        );
      });
    }

    test("alpha foreground composes through translucent ancestors", async () => {
      const { evaluateContrast } = await quality();
      const result = evaluateContrast({
        foreground: "rgba(0, 0, 0, 0.5)",
        background: "rgba(255, 255, 255, 0.5)",
        ancestorBackgrounds: ["rgb(255, 255, 255)"],
        kind: "normal-text",
        ...diagnostic,
      });

      expect(result.resolvedForeground).toBe("rgb(128, 128, 128)");
      expect(result.resolvedBackground).toBe("rgb(255, 255, 255)");
      expect(result.passes, `measured=${result.ratio}; threshold=4.5`).toBe(
        false,
      );
    });

    test("unknown gradients fail closed with selector and mechanism", async () => {
      const { evaluateContrast } = await quality();

      expect(() =>
        evaluateContrast({
          foreground: "rgb(0, 0, 0)",
          background: "linear-gradient(#fff, #eee)",
          kind: "normal-text",
          ...diagnostic,
        }),
      ).toThrow(/#subject.*unknown color.*gradient|gradient.*#subject/i);
    });
  });

  test.describe("normative target geometry and separate comfort policy", () => {
    const base = { target: "fixture:targets", viewport: "wide" };

    test("24 by 24 passes directly", async () => {
      const { evaluateTargetGeometry } = await quality();
      const result = evaluateTargetGeometry({
        targets: [
          { selector: "#subject", x: 10, y: 10, width: 24, height: 24 },
        ],
        exceptions: [],
        comfortSelectors: [],
        ...base,
      });

      expect(result.violations).toEqual([]);
    });

    test("undersized targets pass only when their radius-12 circles are spaced", async () => {
      const { evaluateTargetGeometry } = await quality();
      const result = evaluateTargetGeometry({
        targets: [
          { selector: "#subject", x: 0, y: 0, width: 16, height: 16 },
          { selector: "#neighbor", x: 40, y: 0, width: 16, height: 16 },
        ],
        exceptions: [{ selector: "#subject", kind: "spacing", review: "D-07" }],
        comfortSelectors: [],
        ...base,
      });

      expect(result.violations).toEqual([]);
      expect(result.decisions).toContainEqual(
        expect.objectContaining({ selector: "#subject", exception: "spacing" }),
      );
    });

    test("intersecting undersized target circles fail with measured distance", async () => {
      const { evaluateTargetGeometry } = await quality();
      const result = evaluateTargetGeometry({
        targets: [
          { selector: "#subject", x: 0, y: 0, width: 16, height: 16 },
          { selector: "#neighbor", x: 20, y: 0, width: 16, height: 16 },
        ],
        exceptions: [{ selector: "#subject", kind: "spacing", review: "D-07" }],
        comfortSelectors: [],
        ...base,
      });

      expect(result.violations.join("\n")).toMatch(
        /#subject.*#neighbor.*24.*20|20.*24/i,
      );
    });

    test("undersized target colliding with a large target fails nearest-rect spacing", async () => {
      const { evaluateTargetGeometry } = await quality();
      const result = evaluateTargetGeometry({
        targets: [
          { selector: "#subject", x: 0, y: 0, width: 16, height: 16 },
          { selector: "#large", x: 18, y: 0, width: 44, height: 44 },
        ],
        exceptions: [{ selector: "#subject", kind: "spacing", review: "D-07" }],
        comfortSelectors: [],
        ...base,
      });

      expect(result.violations.join("\n")).toMatch(/#subject.*#large.*12/i);
    });

    test("overlapping hit rectangles fail independently of size", async () => {
      const { evaluateTargetGeometry } = await quality();
      const result = evaluateTargetGeometry({
        targets: [
          { selector: "#subject", x: 0, y: 0, width: 44, height: 44 },
          { selector: "#neighbor", x: 40, y: 0, width: 44, height: 44 },
        ],
        exceptions: [],
        comfortSelectors: [],
        ...base,
      });

      expect(result.violations.join("\n")).toMatch(
        /overlap.*#subject.*#neighbor/i,
      );
    });

    test("inline is accepted only through an exact reviewed exception", async () => {
      const { evaluateTargetGeometry } = await quality();
      const input = {
        targets: [{ selector: "#subject", x: 0, y: 0, width: 12, height: 18 }],
        comfortSelectors: [],
        ...base,
      };
      const accepted = evaluateTargetGeometry({
        ...input,
        exceptions: [{ selector: "#subject", kind: "inline", review: "D-07" }],
      });
      const rejected = evaluateTargetGeometry({ ...input, exceptions: [] });

      expect(accepted.violations).toEqual([]);
      expect(rejected.violations.join("\n")).toMatch(
        /#subject.*24.*exception/i,
      );
    });

    test("unknown and unused exceptions fail closed", async () => {
      const { evaluateTargetGeometry } = await quality();
      const result = evaluateTargetGeometry({
        targets: [{ selector: "#subject", x: 0, y: 0, width: 24, height: 24 }],
        exceptions: [
          { selector: "#subject", kind: "magic", review: "D-07" },
          { selector: "#missing", kind: "essential", review: "D-07" },
        ],
        comfortSelectors: [],
        ...base,
      });

      expect(result.violations.join("\n")).toMatch(/magic.*unknown/i);
      expect(result.violations.join("\n")).toMatch(
        /#missing.*unused|unused.*#missing/i,
      );
    });

    test("named comfort controls require 44px in one axis without weakening 24px", async () => {
      const { evaluateTargetGeometry } = await quality();
      const result = evaluateTargetGeometry({
        targets: [
          { selector: "#comfort", x: 0, y: 0, width: 32, height: 32 },
          { selector: "#normative", x: 80, y: 0, width: 24, height: 24 },
        ],
        exceptions: [],
        comfortSelectors: ["#comfort"],
        ...base,
      });

      expect(result.violations.join("\n")).toMatch(/#comfort.*44.*32/i);
      expect(result.violations.join("\n")).not.toMatch(/#normative/);
    });
  });

  test.describe("focus appearance, visibility, occlusion, and restoration", () => {
    async function setFocusFixture(page: Page, overlay = "") {
      await page.setContent(`
        <style>
          body { margin: 0; min-height: 600px; }
          #subject { margin: 80px; outline: 2px solid rgb(0, 0, 0); }
          ${overlay}
        </style>
        <button id="fallback">Fallback</button>
        <button id="subject">Subject</button>
      `);
      await page.locator("#subject").focus();
    }

    test("connected active focus with 2px and 3:1 indicator passes", async ({
      page,
    }) => {
      const { auditFocusedElement } = await quality();
      await setFocusFixture(page);

      await expect(
        auditFocusedElement(page, {
          ...diagnostic,
          minimumThickness: 2,
          minimumContrast: 3,
        }),
      ).resolves.toMatchObject({ selector: "#subject", visible: true });
    });

    test("detached active target fails and restored fallback is reported", async ({
      page,
    }) => {
      const { auditFocusedElement, restoreFocus } = await quality();
      await setFocusFixture(page);
      await page.locator("#subject").evaluate((element) => element.remove());

      await expect(
        auditFocusedElement(page, {
          ...diagnostic,
          minimumThickness: 2,
          minimumContrast: 3,
        }),
      ).rejects.toThrow(/#subject.*connected|connected.*#subject/i);
      await expect(
        restoreFocus(page, {
          preferred: "#subject",
          fallback: "#fallback",
          ...diagnostic,
        }),
      ).resolves.toMatchObject({
        restored: "#fallback",
        mechanism: "fallback",
      });
    });

    test("one-pixel or low-contrast indicators fail with measurement", async ({
      page,
    }) => {
      const { auditFocusedElement } = await quality();
      await page.setContent(`
        <style>#subject { outline: 1px solid rgb(180, 180, 180); background: white; }</style>
        <button id="subject">Subject</button>
      `);
      await page.locator("#subject").focus();

      await expect(
        auditFocusedElement(page, {
          ...diagnostic,
          minimumThickness: 2,
          minimumContrast: 3,
        }),
      ).rejects.toThrow(/#subject.*(?:1px|1).*2.*contrast|contrast.*3/i);
    });

    test("sticky and top-layer full occlusion fail hit testing", async ({
      page,
    }) => {
      const { auditFocusedElement } = await quality();
      await setFocusFixture(
        page,
        "#cover { position: fixed; inset: 0; background: white; z-index: 10; }",
      );
      await page.locator("body").evaluate((body) => {
        body.insertAdjacentHTML("beforeend", '<div id="cover">Cover</div>');
      });

      await expect(
        auditFocusedElement(page, {
          ...diagnostic,
          minimumThickness: 2,
          minimumContrast: 3,
        }),
      ).rejects.toThrow(/#subject.*#cover.*(?:fixed|occluded|hit-test)/i);
    });

    test("partial visibility with an operable hit-test point passes", async ({
      page,
    }) => {
      const { auditFocusedElement } = await quality();
      await setFocusFixture(
        page,
        "#cover { position: fixed; left: 0; top: 0; width: 90px; height: 120px; background: white; z-index: 10; }",
      );
      await page.locator("body").evaluate((body) => {
        body.insertAdjacentHTML("beforeend", '<div id="cover">Cover</div>');
      });

      await expect(
        auditFocusedElement(page, {
          ...diagnostic,
          minimumThickness: 2,
          minimumContrast: 3,
        }),
      ).resolves.toMatchObject({ visible: true });
    });
  });

  test.describe("reflow, one tree, bounded scrollers, and restored zoom", () => {
    test("root/body/document/page overflow and duplicate trees fail", async ({
      page,
    }) => {
      const { auditReflow } = await quality();
      await page.setContent(`
        <main id="subject" style="width: 500px">
          <div data-obpt-mobile-copy>mobile</div>
          <div data-obpt-desktop-copy>desktop</div>
        </main>
      `);
      await page.setViewportSize({ width: 320, height: 600 });

      await expect(
        auditReflow(page, { ...diagnostic, pageSelector: "#subject" }),
      ).rejects.toThrow(/#subject.*overflow.*(?:320|500)|duplicate.*tree/i);
    });

    test("only labelled focusable bounded machine content may scroll", async ({
      page,
    }) => {
      const { auditReflow } = await quality();
      await page.setContent(`
        <main id="subject">
          <section aria-label="Arguments" tabindex="0" data-obpt-machine-scroller
            style="max-width: 240px; overflow-x: auto">
            <pre style="width: 500px">machine data</pre>
          </section>
        </main>
      `);
      await page.setViewportSize({ width: 320, height: 600 });

      await expect(
        auditReflow(page, {
          ...diagnostic,
          pageSelector: "#subject",
          machineScrollerSelector: "[data-obpt-machine-scroller]",
        }),
      ).resolves.toMatchObject({
        overflowOwners: ["[data-obpt-machine-scroller]"],
      });
    });

    test("unnamed scrollers and scrollers containing ordinary actions fail", async ({
      page,
    }) => {
      const { auditReflow } = await quality();
      await page.setContent(`
        <main id="subject">
          <section tabindex="0" data-obpt-machine-scroller style="width: 200px; overflow-x: auto">
            <div style="width: 500px"><button>Retry</button></div>
          </section>
        </main>
      `);

      await expect(
        auditReflow(page, {
          ...diagnostic,
          pageSelector: "#subject",
          machineScrollerSelector: "[data-obpt-machine-scroller]",
        }),
      ).rejects.toThrow(/machine.*(?:name|label).*button|button.*machine/i);
    });

    test("200 percent zoom restores CDP metrics in finally", async ({
      page,
    }) => {
      const { with200PercentZoom } = await quality();
      await page.setContent('<main id="subject">content</main>');
      const before = page.viewportSize();
      await expect(
        with200PercentZoom(page, { ...diagnostic }, async () => {
          expect(
            await page.evaluate(() => window.devicePixelRatio),
          ).toBeGreaterThan(0);
          throw new Error("fixture assertion");
        }),
      ).rejects.toThrow("fixture assertion");
      expect(page.viewportSize()).toEqual(before);
    });
  });

  test.describe("independent reduced-motion paths", () => {
    async function motionFixture(page: Page) {
      await page.setContent(`
        <style>
          :root { --obpt-motion-duration-instant: 1ms; }
          .obpt-root .spinner { animation: spin 180ms linear infinite; }
          .obpt-root .panel { transition: opacity 180ms ease; }
          @keyframes spin { to { transform: rotate(360deg); } }
          @media (prefers-reduced-motion: reduce) {
            .obpt-root .spinner, .obpt-root .panel {
              animation-duration: 1ms; transition-duration: 1ms; transition-delay: 0ms;
            }
          }
          .obpt-root[data-obpt-motion="reduce"] .spinner,
          .obpt-root[data-obpt-motion="reduce"] .panel {
            animation-duration: 1ms; transition-duration: 1ms; transition-delay: 0ms;
          }
        </style>
        <main class="obpt-root" id="subject">
          <div class="spinner" role="status" aria-label="Loading jobs">Loading jobs</div>
          <button aria-expanded="true">Details</button>
          <section class="panel">Available content</section>
          <progress value="1" max="2">1 of 2</progress>
          <div role="status" aria-live="polite">Updated</div>
        </main>
      `);
    }

    for (const mechanism of ["os", "root"] as const) {
      test(`${mechanism} reduction is independently instant and preserves content`, async ({
        page,
      }) => {
        const { auditReducedMotion } = await quality();
        await motionFixture(page);

        await expect(
          auditReducedMotion(page, {
            ...diagnostic,
            rootSelector: ".obpt-root",
            mechanism,
            maximumDurationMs: 1,
            requiredVisible: [
              '[role="status"][aria-label="Loading jobs"]',
              "button[aria-expanded]",
              ".panel",
              "progress",
              '[aria-live="polite"]',
            ],
          }),
        ).resolves.toMatchObject({
          mechanism,
          hiddenRequired: [],
          delayedActions: [],
        });
      });
    }
  });

  test("system theme computed roles match explicit themes and restore every override", async ({
    page,
  }) => {
    const { auditSystemTheme } = await quality();
    await page.setContent(`
      <style>
        .obpt-root { color: rgb(20,20,20); background: rgb(255,255,255); --role-border: rgb(70,70,70); }
        .obpt-root[data-obpt-theme="dark"] { color: rgb(240,240,240); background: rgb(20,20,20); --role-border: rgb(190,190,190); }
        .obpt-root[data-obpt-theme="high-contrast"] { color: rgb(255,255,255); background: rgb(0,0,0); --role-border: rgb(255,255,0); }
        @media (prefers-color-scheme: dark) {
          .obpt-root[data-obpt-theme="system"] { color: rgb(240,240,240); background: rgb(20,20,20); --role-border: rgb(190,190,190); }
        }
        @media (prefers-contrast: more) {
          .obpt-root[data-obpt-theme="system"] { color: rgb(255,255,255); background: rgb(0,0,0); --role-border: rgb(255,255,0); }
        }
      </style>
      <main class="obpt-root" id="subject" data-obpt-theme="system" data-obpt-motion="reduce">
        <button id="role-control">Control</button>
      </main>
    `);
    const original = await page.locator("#subject").evaluate((element) => ({
      theme: element.getAttribute("data-obpt-theme"),
      motion: element.getAttribute("data-obpt-motion"),
    }));

    const result = await auditSystemTheme(page, {
      ...diagnostic,
      rootSelector: "#subject",
      roles: [
        {
          selector: "#subject",
          properties: ["color", "backgroundColor", "--role-border"],
        },
        { selector: "#role-control", properties: ["color", "backgroundColor"] },
      ],
      matrix: [
        {
          colorScheme: "light",
          contrast: "no-preference",
          expectedTheme: "light",
        },
        {
          colorScheme: "dark",
          contrast: "no-preference",
          expectedTheme: "dark",
        },
        {
          colorScheme: "light",
          contrast: "more",
          expectedTheme: "high-contrast",
        },
        {
          colorScheme: "dark",
          contrast: "more",
          expectedTheme: "high-contrast",
        },
      ],
    });

    expect(result.cases).toHaveLength(4);
    for (const item of result.cases) {
      expect(
        item.actualRoles,
        `mode=${item.colorScheme}/${item.contrast}; expected=${item.expectedTheme}; actual=${JSON.stringify(item.actualRoles)}`,
      ).toEqual(item.expectedRoles);
    }
    await expect(page.locator("#subject")).toHaveAttribute(
      "data-obpt-theme",
      original.theme!,
    );
    await expect(page.locator("#subject")).toHaveAttribute(
      "data-obpt-motion",
      original.motion!,
    );
  });

  test.describe("strict axe impact and exception policy", () => {
    const finding = {
      id: "color-contrast",
      impact: "moderate",
      nodes: [{ target: ["#subject"] }],
    };

    for (const impact of ["critical", "serious", "moderate"] as const) {
      test(`${impact} findings block by default`, async () => {
        const { evaluateAxePolicy } = await axePolicy();
        const result = await evaluateAxePolicy({
          violations: [{ ...finding, impact }],
          scope: { target: "fixture:axe", selector: "#subject" },
          exceptions: [],
          now: "2026-07-29",
        });
        expect(result.blocking).toHaveLength(1);
      });
    }

    test("only exact unexpired used moderate exception with compensation passes", async () => {
      const { evaluateAxePolicy } = await axePolicy();
      const exception = {
        ruleId: "color-contrast",
        scope: { target: "fixture:axe", selector: "#subject" },
        rationaleUrl:
          "https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum",
        owner: "web-quality",
        expires: "2026-08-31",
        compensation: async () => true,
      };
      const accepted = await evaluateAxePolicy({
        violations: [finding],
        scope: exception.scope,
        exceptions: [exception],
        now: "2026-07-29",
      });
      expect(accepted.blocking).toEqual([]);
      expect(accepted.usedExceptions).toEqual([
        "color-contrast:fixture:axe:#subject",
      ]);
    });

    test("expired, broad, unused, or failing compensation exceptions fail", async () => {
      const { evaluateAxePolicy } = await axePolicy();
      const result = await evaluateAxePolicy({
        violations: [finding],
        scope: { target: "fixture:axe", selector: "#subject" },
        exceptions: [
          {
            ruleId: "*",
            scope: { target: "*", selector: "*" },
            rationaleUrl: "https://www.w3.org/WAI/WCAG22/",
            owner: "web-quality",
            expires: "2026-07-01",
            compensation: async () => false,
          },
          {
            ruleId: "aria-input-field-name",
            scope: { target: "missing", selector: "#missing" },
            rationaleUrl: "https://www.w3.org/WAI/WCAG22/",
            owner: "web-quality",
            expires: "2026-08-31",
            compensation: async () => true,
          },
        ],
        now: "2026-07-29",
      });
      expect(result.policyErrors.join("\n")).toMatch(/expired|broad/i);
      expect(result.policyErrors.join("\n")).toMatch(
        /unused.*aria-input-field-name/i,
      );
      expect(result.blocking).toHaveLength(1);
    });
  });
});
