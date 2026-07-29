import { expect, test, type Locator, type Page } from "@playwright/test";
import { assertAxePolicy, runAxeForTarget } from "../support/axe";
import {
  connectedPageFamilies,
  connectedPages,
} from "../support/connected-pages";
import { manifest, themes } from "../support/manifest";
import {
  auditFocusedElement,
  auditReducedMotion,
  auditReflow,
  auditSystemTheme,
  collectInteractiveTargetGeometry,
  evaluateTargetGeometry,
  with200PercentZoom,
} from "../support/system-quality";

test.describe.configure({ mode: "serial" });
test.setTimeout(240_000);

const copyContract = manifest.copy_contract;
const themeMatrix = [
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
] as const;
const semanticThemeProperties = [
  "--obpt-color-text",
  "--obpt-color-surface",
  "--obpt-color-border-strong",
  "--obpt-color-focus",
];

function exactPhrase(text: string, phrase: string): boolean {
  const escaped = phrase.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  return new RegExp(
    `(^|[^\\p{L}\\p{N}_])${escaped}([^\\p{L}\\p{N}_]|$)`,
    "u",
  ).test(text);
}

async function auditRenderedCopy(
  root: Locator,
  targetLabel: string,
): Promise<number> {
  const text = (await root.innerText()).replace(/\s+/g, " ").trim();
  const actionText = (
    await root
      .locator(
        'button, a[href], input[type="button"], input[type="submit"], [role="button"], [role="link"]',
      )
      .allInnerTexts()
  )
    .join(" ")
    .replace(/\s+/g, " ")
    .trim();
  const receiptText = (
    await root
      .locator('[role="status"], [role="alert"], [data-obpt-receipt]')
      .allInnerTexts()
  )
    .join(" ")
    .replace(/\s+/g, " ")
    .trim();
  const phrases = [
    ...copyContract.forbidden_phrases.map(({ phrase, rule }) => ({
      phrase,
      rule,
    })),
    ...Object.entries(copyContract.canonical_terms).flatMap(
      ([concept, entry]) =>
        entry.forbidden.map((phrase) => ({
          phrase,
          rule: `canonical-term:${concept}`,
        })),
    ),
  ];
  const violations = phrases.filter(({ phrase, rule }) => {
    const policyText =
      rule === "ambiguous-action"
        ? actionText
        : rule === "host-outcome-overclaim"
          ? receiptText
          : text;
    return exactPhrase(policyText, phrase);
  });

  expect(
    violations,
    `${targetLabel} rendered copy violates finite policy: ${violations
      .map(({ phrase, rule }) => `${JSON.stringify(phrase)} (${rule})`)
      .join(", ")}`,
  ).toEqual([]);
  return phrases.length;
}

async function focusAndAuditSkipLink(
  page: Page,
  target: string,
  project: string,
  viewport: string,
): Promise<void> {
  const skipLink = page.locator(".obpt-app-shell__skip");
  await page.evaluate(() => {
    window.scrollTo(0, 0);
    document.body.tabIndex = -1;
    document.body.focus();
  });
  await page.keyboard.press("Tab");
  await page.evaluate(() => document.body.removeAttribute("tabindex"));
  await expect(skipLink).toBeFocused();
  await expect(skipLink).toBeInViewport();
  await auditFocusedElement(page, {
    target,
    selector: ".obpt-app-shell__skip",
    project,
    viewport,
    minimumThickness: 2,
    minimumContrast: 3,
  });
  await skipLink.press("Enter");
  await expect(page.locator("#obpt-main")).toBeFocused();
}

for (const family of connectedPageFamilies) {
  test(`${family} connected production quality`, async ({
    page,
    request,
  }, testInfo) => {
    const session = await connectedPages[family].setup({
      page,
      request,
      project: testInfo.project.name,
    });

    const shell = page.locator(".obpt-root");
    const originalTheme = await shell.getAttribute("data-obpt-theme");

    try {
      for (const theme of themes) {
        const targetLabel = [
          `route=${family}`,
          `theme=${theme}`,
          `project=${testInfo.project.name}`,
          `media=${theme === "system" ? "runtime-matrix" : "explicit"}`,
          "step=base",
        ].join(" ");

        const themeChoice = page.locator(`[data-obpt-theme-choice="${theme}"]`);
        await themeChoice.focus();
        await themeChoice.press("Enter");
        await expect(shell).toHaveAttribute("data-obpt-theme", theme);
        await expect(themeChoice).toHaveAttribute("aria-pressed", "true");

        await session.safeTraversal();
        await focusAndAuditSkipLink(
          page,
          `${targetLabel} step=skip-focus`,
          testInfo.project.name,
          testInfo.project.name,
        );

        await auditReflow(page, {
          target: `${targetLabel} step=reflow`,
          selector: ".obpt-root",
          project: testInfo.project.name,
          viewport: testInfo.project.name,
          pageSelector: ".obpt-root",
          machineScrollerSelector: "[data-obpt-machine-scroller]",
        });
        await auditReducedMotion(page, {
          target: `${targetLabel} step=os-reduced-motion`,
          selector: ".obpt-root",
          project: testInfo.project.name,
          viewport: testInfo.project.name,
          rootSelector: ".obpt-root",
          mechanism: "os",
          maximumDurationMs: 1,
          requiredVisible: [".obpt-root", `#${family}-page`],
        });
        await auditReducedMotion(page, {
          target: `${targetLabel} step=root-reduced-motion`,
          selector: ".obpt-root",
          project: testInfo.project.name,
          viewport: testInfo.project.name,
          rootSelector: ".obpt-root",
          mechanism: "root",
          maximumDurationMs: 1,
          requiredVisible: [".obpt-root", `#${family}-page`],
        });

        const geometry = await collectInteractiveTargetGeometry(
          page,
          ".obpt-root",
        );
        const targetResult = evaluateTargetGeometry({
          target: `${targetLabel} step=targets`,
          viewport: testInfo.project.name,
          targets: geometry,
          exceptions: [],
          comfortSelectors: [],
        });
        expect(
          targetResult.violations,
          `${targetLabel} target geometry: ${targetResult.violations.join("; ")}`,
        ).toEqual([]);

        const copyRulesChecked = await auditRenderedCopy(shell, targetLabel);

        if (theme === "system") {
          const report = await auditSystemTheme(page, {
            target: `${targetLabel} step=system-equivalence`,
            selector: ".obpt-root",
            project: testInfo.project.name,
            viewport: testInfo.project.name,
            rootSelector: ".obpt-root",
            roles: [
              {
                selector: ".obpt-root",
                properties: semanticThemeProperties,
              },
            ],
            matrix: [...themeMatrix],
          });
          for (const matrixCase of report.cases) {
            expect(
              matrixCase.actualRoles,
              `${targetLabel} ${matrixCase.colorScheme}/${matrixCase.contrast} must equal ${matrixCase.expectedTheme}`,
            ).toEqual(matrixCase.expectedRoles);
          }
        }

        if (testInfo.project.name === "chromium-wide") {
          await with200PercentZoom(
            page,
            {
              target: `${targetLabel} step=zoom-200`,
              selector: ".obpt-root",
              project: testInfo.project.name,
              viewport: "wide@200%",
            },
            () =>
              auditReflow(page, {
                target: `${targetLabel} step=zoom-200-reflow`,
                selector: ".obpt-root",
                project: testInfo.project.name,
                viewport: "wide@200%",
                pageSelector: ".obpt-root",
                machineScrollerSelector: "[data-obpt-machine-scroller]",
              }),
          );
        }

        const results = await runAxeForTarget(page, ".obpt-root");
        await assertAxePolicy({
          results,
          scope: {
            target: targetLabel,
            selector: ".obpt-root",
            route: session.path,
          },
        });
        await testInfo.attach(`phase82-${family}-${theme}-connected`, {
          body: Buffer.from(
            JSON.stringify({
              family,
              theme,
              project: testInfo.project.name,
              interactiveTargets: geometry.length,
              copyRulesChecked,
              systemThemeCases: theme === "system" ? themeMatrix.length : 0,
            }),
          ),
          contentType: "application/json",
        });
      }
    } finally {
      const dialog = page.getByRole("dialog");
      if (await dialog.count()) {
        await page.keyboard.press("Escape").catch(() => undefined);
      }
      await shell
        .evaluate((root, theme) => {
          if (theme === null) root.removeAttribute("data-obpt-theme");
          else root.setAttribute("data-obpt-theme", theme);
          root.removeAttribute("data-obpt-motion");
          (document.activeElement as HTMLElement | null)?.blur();
        }, originalTheme)
        .catch(() => undefined);
      await page.emulateMedia({
        colorScheme: "light",
        contrast: "no-preference",
        reducedMotion: "reduce",
      });
    }
  });
}
