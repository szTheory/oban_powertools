import fs from 'node:fs/promises';
import path from 'node:path';
import { AxeBuilder } from '@axe-core/playwright';
import type { AxeResults, Result } from 'axe-core';
import type { Page, TestInfo } from '@playwright/test';

const axeTags = ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'] as const;
const resultTypes = ['violations', 'passes', 'incomplete', 'inapplicable'] as const;
const blockingImpacts = new Set(['critical', 'serious']);

export async function runAxeForTarget(page: Page, selector: string): Promise<AxeResults> {
  return new AxeBuilder({ page })
    .include(selector)
    .options({
      runOnly: {
        type: 'tag',
        values: [...axeTags]
      },
      rules: {
        'target-size': { enabled: true }
      },
      resultTypes: [...resultTypes]
    })
    .analyze();
}

export async function writeAxeResult(
  testInfo: TestInfo,
  name: string,
  results: AxeResults
): Promise<void> {
  const fileName = `${safeSegment(testInfo.project.name)}-${safeSegment(name)}.json`;
  const outputPath = path.join(process.cwd(), 'test-results/axe', fileName);

  await fs.mkdir(path.dirname(outputPath), { recursive: true });
  await fs.writeFile(outputPath, `${JSON.stringify(results, null, 2)}\n`, 'utf8');
  await testInfo.attach(`axe-${name}`, {
    path: outputPath,
    contentType: 'application/json'
  });
}

export function assertNoCriticalOrSerious(results: AxeResults, name: string): void {
  const blockingViolations = results.violations.filter((violation) =>
    blockingImpacts.has(violation.impact ?? '')
  );

  if (blockingViolations.length === 0) {
    return;
  }

  const summary = blockingViolations.map(formatViolation).join('\n\n');
  throw new Error(`${name} has critical/serious axe violations:\n\n${summary}`);
}

function formatViolation(violation: Result): string {
  const targets = violation.nodes
    .flatMap((node) => node.target)
    .slice(0, 5)
    .join(', ');

  return [
    `${violation.id} (${violation.impact ?? 'unknown'}): ${violation.help}`,
    `Targets: ${targets || 'none'}`
  ].join('\n');
}

function safeSegment(value: string): string {
  return value.replace(/[^a-zA-Z0-9._-]+/g, '-').replace(/^-+|-+$/g, '');
}
