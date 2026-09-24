import { expect, test } from "@playwright/test";
import { manifest, targets, themes } from "../support/manifest";
import { viewportNameFromProject } from "../support/deterministic";
import {
  assertAxePolicy,
  runAxeForTarget,
  writeAxeResult,
} from "../support/axe";
import { activateTarget, prepareShowcase } from "../support/showcase";
import {
  auditReducedMotion,
  auditSystemQuality,
  auditSystemTheme,
  collectInteractiveTargetGeometry,
  evaluateTargetGeometry,
  with200PercentZoom,
} from "../support/system-quality";

const pageQualityTargets =
  process.env.PAGE_QUALITY_ONLY === "1"
    ? targets.filter((target) => target.kind === "page")
    : targets;
const runtimeSlice = process.env.PHASE82_RUNTIME_SLICE;
const copyContract = manifest.copy_contract;

if (runtimeSlice !== undefined && runtimeSlice !== "manifest-first-per-kind") {
  throw new Error(
    `PHASE82_RUNTIME_SLICE must be "manifest-first-per-kind", received ${JSON.stringify(runtimeSlice)}`,
  );
}

const a11yTargets =
  runtimeSlice === "manifest-first-per-kind"
    ? pageQualityTargets.filter(
        (target, index, allTargets) =>
          allTargets.findIndex(
            (candidate) => candidate.kind === target.kind,
          ) === index,
      )
    : pageQualityTargets;

if (
  a11yTargets.length === 0 ||
  new Set(a11yTargets.map((target) => target.id)).size !== a11yTargets.length ||
  (runtimeSlice === "manifest-first-per-kind" &&
    new Set(a11yTargets.map((target) => target.kind)).size !==
      a11yTargets.length)
) {
  throw new Error(
    "Phase 82 runtime selection must be non-empty, unique, and manifest-derived",
  );
}

const themeRoles = [
  {
    properties: [
      "--obpt-color-text",
      "--obpt-color-surface",
      "--obpt-color-border-strong",
      "--obpt-color-focus",
    ],
  },
] as const;
const themeMatrix = [
  { colorScheme: "light", contrast: "no-preference", expectedTheme: "light" },
  { colorScheme: "dark", contrast: "no-preference", expectedTheme: "dark" },
  { colorScheme: "light", contrast: "more", expectedTheme: "high-contrast" },
  { colorScheme: "dark", contrast: "more", expectedTheme: "high-contrast" },
] as const;

function exactPhrase(text: string, phrase: string): boolean {
  const escaped = phrase.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  return new RegExp(
    `(^|[^\\p{L}\\p{N}_])${escaped}([^\\p{L}\\p{N}_]|$)`,
    "u",
  ).test(text);
}

async function auditRenderedCopy(
  story: Awaited<ReturnType<typeof activateTarget>>,
  targetLabel: string,
): Promise<number> {
  const text = (await story.innerText()).replace(/\s+/g, " ").trim();
  const actionText = (
    await story
      .locator(
        'button, a[href], input[type="button"], input[type="submit"], [role="button"], [role="link"]',
      )
      .allInnerTexts()
  )
    .join(" ")
    .replace(/\s+/g, " ")
    .trim();
  const receiptText = (
    await story
      .locator('[role="status"], [role="alert"], [data-obpt-receipt]')
      .allInnerTexts()
  )
    .join(" ")
    .replace(/\s+/g, " ")
    .trim();
  const policyPhrases = [
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
  const violations = policyPhrases.filter(({ phrase, rule }) => {
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
  return policyPhrases.length;
}

for (const theme of themes) {
  test.describe(`showcase axe ${theme}`, () => {
    for (const target of a11yTargets) {
      test(`${target.kind} ${target.id}`, async ({ page }, testInfo) => {
        const viewportName = viewportNameFromProject(testInfo.project.name);
        const resultName = `${theme}-${target.kind}-${target.id}`;

        await prepareShowcase(page, { theme, viewportName });
        const story = await activateTarget(page, target);
        await expect(story).toBeVisible();

        const targetLabel = [
          `kind=${target.kind}`,
          `id=${target.id}`,
          `theme=${theme}`,
          `project=${testInfo.project.name}`,
          `media=${theme === "system" ? "runtime-matrix" : "explicit"}`,
        ].join(" ");
        const diagnostic = {
          target: targetLabel,
          selector: target.a11y,
          project: testInfo.project.name,
          viewport: viewportName,
        };

        await auditSystemQuality(page, {
          diagnostic,
          reflow: {
            pageSelector: target.a11y,
            machineScrollerSelector: "[data-obpt-machine-scroller]",
          },
        });
        await auditReducedMotion(page, {
          ...diagnostic,
          rootSelector: ".obpt-root",
          auditSelector: target.a11y,
          mechanism: "os",
          maximumDurationMs: 1,
          requiredVisible: [target.a11y],
        });
        if (theme === "system") {
          await auditReducedMotion(page, {
            ...diagnostic,
            rootSelector: ".obpt-root",
            auditSelector: target.a11y,
            mechanism: "root",
            maximumDurationMs: 1,
            requiredVisible: [target.a11y],
          });
        }
        if (theme === "system" && testInfo.project.name === "chromium-wide") {
          await with200PercentZoom(page, diagnostic, () =>
            auditSystemQuality(page, {
              diagnostic: { ...diagnostic, viewport: `${viewportName}@200%` },
              reflow: {
                pageSelector: target.a11y,
                machineScrollerSelector: "[data-obpt-machine-scroller]",
              },
            }),
          );
        }

        const geometry = await collectInteractiveTargetGeometry(
          page,
          target.a11y,
        );
        const targetResult = evaluateTargetGeometry({
          target: targetLabel,
          viewport: viewportName,
          targets: geometry,
          exceptions: [],
          comfortSelectors: [],
        });
        expect(
          targetResult.violations,
          `${targetLabel} target geometry: ${targetResult.violations.join("; ")}`,
        ).toEqual([]);

        const copyRulesChecked = await auditRenderedCopy(story, targetLabel);

        if (theme === "system") {
          const themeReport = await auditSystemTheme(page, {
            ...diagnostic,
            rootSelector: ".obpt-root",
            roles: themeRoles.map((role) => ({
              selector: target.a11y,
              properties: [...role.properties],
            })),
            matrix: [...themeMatrix],
          });
          for (const matrixCase of themeReport.cases) {
            expect(
              matrixCase.actualRoles,
              `${targetLabel} ${matrixCase.colorScheme}/${matrixCase.contrast} must equal ${matrixCase.expectedTheme}`,
            ).toEqual(matrixCase.expectedRoles);
          }
        }

        const results = await runAxeForTarget(page, target.a11y);
        const contrastSamples = [
          ...results.passes,
          ...results.violations,
          ...results.incomplete,
        ]
          .filter((result) => result.id === "color-contrast")
          .reduce((count, result) => count + result.nodes.length, 0);
        await writeAxeResult(testInfo, resultName, results);
        await assertAxePolicy({
          results,
          scope: {
            target: targetLabel,
            selector: target.a11y,
            story: target.id,
          },
        });
        await testInfo.attach(`phase82-${resultName}`, {
          body: Buffer.from(
            JSON.stringify({
              kind: target.kind,
              id: target.id,
              theme,
              project: testInfo.project.name,
              viewport: viewportName,
              interactiveTargets: geometry.length,
              copyRulesChecked,
              contrastSamples,
              systemThemeCases: theme === "system" ? themeMatrix.length : 0,
            }),
          ),
          contentType: "application/json",
        });
      });
    }
  });
}
