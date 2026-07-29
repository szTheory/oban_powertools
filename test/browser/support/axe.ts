import fs from "node:fs/promises";
import path from "node:path";
import { AxeBuilder } from "@axe-core/playwright";
import type { AxeResults, Result } from "axe-core";
import type { Page, TestInfo } from "@playwright/test";

const axeTags = [
  "wcag2a",
  "wcag2aa",
  "wcag21a",
  "wcag21aa",
  "wcag22aa",
] as const;
const resultTypes = [
  "violations",
  "passes",
  "incomplete",
  "inapplicable",
] as const;
const blockingImpacts = new Set(["critical", "serious", "moderate"]);
const MAX_DIAGNOSTIC_BYTES = 128_000;
const MAX_FINDINGS = 200;

export type AxeScope = {
  target: string;
  selector: string;
  route?: string;
  story?: string;
};

export type AxeException = {
  ruleId: string;
  scope: AxeScope;
  rationaleUrl: string;
  owner: string;
  expires: string;
  compensation: () => boolean | Promise<boolean>;
};

type AxeFinding = Pick<Result, "id" | "impact" | "nodes">;

export async function runAxeForTarget(
  page: Page,
  target: string | { selector?: string; route?: string },
): Promise<AxeResults> {
  const selector = typeof target === "string" ? target : target.selector;
  const builder = new AxeBuilder({ page }).options({
    runOnly: {
      type: "tag",
      values: [...axeTags],
    },
    rules: {
      "target-size": { enabled: true },
    },
    resultTypes: [...resultTypes],
  });

  if (selector) builder.include(selector);
  return builder.analyze();
}

export async function writeAxeResult(
  testInfo: TestInfo,
  name: string,
  results: AxeResults,
): Promise<void> {
  const fileName = `${safeSegment(testInfo.project.name)}-${safeSegment(name)}.json`;
  const outputPath = path.join(process.cwd(), "test-results/axe", fileName);

  await fs.mkdir(path.dirname(outputPath), { recursive: true });
  const redacted = redactAxeResults(results);
  const serialized = `${JSON.stringify(redacted, null, 2)}\n`;
  if (Buffer.byteLength(serialized, "utf8") > MAX_DIAGNOSTIC_BYTES) {
    throw new Error(
      `${name}: redacted axe artifact exceeds ${MAX_DIAGNOSTIC_BYTES} bytes`,
    );
  }
  await fs.writeFile(outputPath, serialized, "utf8");
  await testInfo.attach(`axe-${name}`, {
    path: outputPath,
    contentType: "application/json",
  });
}

export function assertNoCriticalOrSerious(
  results: AxeResults,
  name: string,
): void {
  const blockingViolations = results.violations.filter((violation) =>
    blockingImpacts.has(violation.impact ?? ""),
  );

  if (blockingViolations.length === 0) {
    return;
  }

  const summary = blockingViolations.map(formatViolation).join("\n\n");
  throw new Error(
    `${name} has critical/serious/moderate axe violations:\n\n${summary}`,
  );
}

function formatViolation(violation: Result): string {
  const targets = violation.nodes.flatMap((node) => node.target).join(", ");

  return [
    `${violation.id} (${violation.impact ?? "unknown"}): ${violation.help}`,
    `Targets: ${targets || "none"}`,
  ].join("\n");
}

export async function evaluateAxePolicy(input: {
  violations: AxeFinding[];
  scope: AxeScope;
  exceptions: AxeException[];
  now: string;
}): Promise<{
  blocking: Array<{ ruleId: string; impact: string; selectors: string[] }>;
  minor: Array<{ ruleId: string; selectors: string[] }>;
  usedExceptions: string[];
  policyErrors: string[];
}> {
  const policyErrors: string[] = [];
  const blocking: Array<{
    ruleId: string;
    impact: string;
    selectors: string[];
  }> = [];
  const minor: Array<{ ruleId: string; selectors: string[] }> = [];
  const used = new Set<number>();
  const signatures = new Set<string>();
  const now = parseIsoDate(input.now, "policy now", policyErrors);

  if (input.violations.length > MAX_FINDINGS) {
    policyErrors.push(
      `axe findings exceed bounded maximum ${MAX_FINDINGS}: ${input.violations.length}`,
    );
  }

  input.exceptions.forEach((exception, index) => {
    const signature = exceptionKey(exception.ruleId, exception.scope);
    if (signatures.has(signature))
      policyErrors.push(`duplicate axe exception ${signature}`);
    signatures.add(signature);
    if (
      !exception.ruleId ||
      exception.ruleId === "*" ||
      !exactScope(exception.scope) ||
      Object.values(exception.scope).some((value) => value === "*")
    ) {
      policyErrors.push(`broad axe exception ${signature} is forbidden`);
    }
    if (
      !/^https:\/\/(?:www\.)?(?:w3\.org|dequeuniversity\.com)\//.test(
        exception.rationaleUrl,
      )
    ) {
      policyErrors.push(`${signature} requires a standards rationale URL`);
    }
    if (!exception.owner.trim())
      policyErrors.push(`${signature} requires an owner`);
    const expiry = parseIsoDate(
      exception.expires,
      `${signature} expiry`,
      policyErrors,
    );
    if (now && expiry && expiry < now)
      policyErrors.push(`expired axe exception ${signature}`);
    if (typeof exception.compensation !== "function") {
      policyErrors.push(
        `${signature} requires an executable compensating assertion`,
      );
    }
    void index;
  });

  for (const finding of input.violations.slice(0, MAX_FINDINGS)) {
    const impact = finding.impact ?? "unknown";
    const selectors = finding.nodes
      .flatMap((node) => node.target)
      .map((target) => String(target))
      .slice(0, MAX_DIAGNOSTIC_BYTES / 64);

    if (impact === "minor") {
      minor.push({ ruleId: finding.id, selectors });
      continue;
    }

    if (
      impact === "critical" ||
      impact === "serious" ||
      impact !== "moderate"
    ) {
      blocking.push({ ruleId: finding.id, impact, selectors });
      continue;
    }

    let findingBlocked = false;
    for (const selector of selectors) {
      const matchingIndex = input.exceptions.findIndex(
        (exception) =>
          exception.ruleId === finding.id &&
          exactScopeEqual(exception.scope, { ...input.scope, selector }),
      );
      if (matchingIndex < 0) {
        findingBlocked = true;
        continue;
      }

      const exception = input.exceptions[matchingIndex];
      const signature = exceptionKey(exception.ruleId, exception.scope);
      const expiry = Date.parse(`${exception.expires}T00:00:00Z`);
      const valid =
        Number.isFinite(expiry) &&
        Boolean(now) &&
        expiry >= now!.getTime() &&
        !policyErrors.some((error) => error.includes(signature));
      let compensated = false;
      if (valid) {
        try {
          compensated = await exception.compensation();
        } catch {
          policyErrors.push(`${signature} compensating assertion threw`);
        }
      }
      if (!compensated) {
        policyErrors.push(`${signature} compensating assertion failed`);
        findingBlocked = true;
      } else {
        used.add(matchingIndex);
      }
    }

    if (findingBlocked || selectors.length === 0) {
      blocking.push({ ruleId: finding.id, impact, selectors });
    }
  }

  input.exceptions.forEach((exception, index) => {
    if (!used.has(index)) {
      policyErrors.push(
        `unused axe exception ${exceptionKey(exception.ruleId, exception.scope)}`,
      );
    }
  });

  return {
    blocking,
    minor,
    usedExceptions: [...used].map((index) =>
      exceptionKey(
        input.exceptions[index].ruleId,
        input.exceptions[index].scope,
      ),
    ),
    policyErrors: [...new Set(policyErrors)].slice(0, MAX_FINDINGS),
  };
}

export async function assertAxePolicy(input: {
  results: AxeResults;
  scope: AxeScope;
  exceptions?: AxeException[];
  now?: string;
}): Promise<void> {
  const report = await evaluateAxePolicy({
    violations: input.results.violations,
    scope: input.scope,
    exceptions: input.exceptions ?? [],
    now: input.now ?? new Date().toISOString().slice(0, 10),
  });

  if (report.blocking.length || report.policyErrors.length) {
    const diagnostic = JSON.stringify(
      {
        scope: input.scope,
        blocking: report.blocking,
        policyErrors: report.policyErrors,
      },
      null,
      2,
    );
    if (Buffer.byteLength(diagnostic, "utf8") > MAX_DIAGNOSTIC_BYTES) {
      throw new Error(
        `${input.scope.target}: axe policy diagnostics exceeded bounded size`,
      );
    }
    throw new Error(`${input.scope.target}: axe policy failed\n${diagnostic}`);
  }
}

function exactScope(scope: AxeScope): boolean {
  return Boolean(scope.target?.trim() && scope.selector?.trim());
}

function exactScopeEqual(left: AxeScope, right: AxeScope): boolean {
  return (
    left.target === right.target &&
    left.selector === right.selector &&
    (left.route ?? "") === (right.route ?? "") &&
    (left.story ?? "") === (right.story ?? "")
  );
}

function exceptionKey(ruleId: string, scope: AxeScope): string {
  return [ruleId, scope.target, scope.selector, scope.route, scope.story]
    .filter(Boolean)
    .join(":");
}

function parseIsoDate(
  value: string,
  label: string,
  errors: string[],
): Date | undefined {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    errors.push(`${label} must be an ISO date`);
    return undefined;
  }
  const date = new Date(`${value}T00:00:00Z`);
  if (!Number.isFinite(date.getTime())) {
    errors.push(`${label} is invalid`);
    return undefined;
  }
  return date;
}

function redactAxeResults(results: AxeResults): object {
  const redact = (result: Result) => ({
    id: result.id,
    impact: result.impact,
    tags: result.tags,
    help: result.help,
    helpUrl: result.helpUrl,
    nodes: result.nodes.map((node) => ({
      impact: node.impact,
      target: node.target,
    })),
  });
  return {
    testEngine: {
      name: results.testEngine.name,
      version: results.testEngine.version,
    },
    testEnvironment: {
      orientationAngle: results.testEnvironment.orientationAngle,
      orientationType: results.testEnvironment.orientationType,
    },
    timestamp: results.timestamp,
    url: redactedUrl(results.url),
    violations: results.violations.map(redact),
    passes: results.passes.map(redact),
    incomplete: results.incomplete.map(redact),
    inapplicable: results.inapplicable.map(redact),
  };
}

function redactedUrl(value: string): string {
  try {
    const url = new URL(value);
    return `${url.origin}${url.pathname}`;
  } catch {
    return "[redacted-invalid-url]";
  }
}

function safeSegment(value: string): string {
  return value.replace(/[^a-zA-Z0-9._-]+/g, "-").replace(/^-+|-+$/g, "");
}
