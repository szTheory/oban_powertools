import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";

const EXPECTED_SCHEMA = 8;
const EXPECTED_TARGET_COUNT = 163;
const EXPECTED_PAGE_COUNT = 99;
const EXPECTED_EXCLUSIONS = [
  "assets/vendor",
  "test/browser/fixtures",
  "priv/static/oban_powertools/oban_powertools.js:generated",
];
const UNSAFE_REPORT_FIELDS =
  /(?:fixture|preview|reason|provider|payload|credential|secret|token|before|after)/i;
const SAFE_REPORT_FIELDS = new Set(["path", "line", "rule", "count", "counts"]);

class QualityPolicyError extends Error {
  constructor(message, diagnostic = {}) {
    super(message);
    this.name = "QualityPolicyError";
    this.diagnostic = diagnostic;
  }
}

function fail(message, diagnostic = {}) {
  throw new QualityPolicyError(message, diagnostic);
}

function record(value, label) {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    fail(`${label} must be an object`, { rule: `${label}.object` });
  }
  return value;
}

function array(value, label) {
  if (!Array.isArray(value)) {
    fail(`${label} must be an array`, { rule: `${label}.array` });
  }
  return value;
}

function string(value, label) {
  if (typeof value !== "string" || value.length === 0) {
    fail(`${label} must be a non-empty string`, { rule: `${label}.string` });
  }
  return value;
}

function duplicates(values) {
  const seen = new Set();
  return values.filter((value) => {
    if (seen.has(value)) return true;
    seen.add(value);
    return false;
  });
}

function sameOrderedValues(actual, expected) {
  return (
    actual.length === expected.length &&
    actual.every((value, index) => value === expected[index])
  );
}

function reportSafe(value, label = "report") {
  if (Array.isArray(value)) {
    value.forEach((item, index) => reportSafe(item, `${label}[${index}]`));
    return;
  }
  if (!value || typeof value !== "object") return;

  for (const [key, child] of Object.entries(value)) {
    if (
      UNSAFE_REPORT_FIELDS.test(key) ||
      (label === "report" && !SAFE_REPORT_FIELDS.has(key))
    ) {
      fail(`${label} field ${key} is not permitted`, {
        rule: "report.unsafe-field",
      });
    }
    reportSafe(child, `${label}.${key}`);
  }
}

export function validateInventoryContract(input) {
  const contract = record(input, "inventory");
  const targets = array(contract.targets, "inventory.targets");
  const pageStories = array(contract.pageStories, "inventory.pageStories");
  const routeFamilies = array(
    contract.routeFamilies,
    "inventory.routeFamilies",
  );

  if (contract.schema !== EXPECTED_SCHEMA) {
    fail(`schema must remain ${EXPECTED_SCHEMA}; got ${contract.schema}`, {
      rule: "inventory.schema",
      count: contract.schema,
    });
  }
  if (contract.inventorySource !== "generated-manifest") {
    fail("inventory must use generated-manifest, never a hand-written list", {
      rule: "inventory.generated-manifest",
    });
  }
  if (targets.length !== EXPECTED_TARGET_COUNT) {
    fail(
      `targets must contain ${EXPECTED_TARGET_COUNT}; got ${targets.length}`,
      { rule: "inventory.targets", count: targets.length },
    );
  }
  if (pageStories.length !== EXPECTED_PAGE_COUNT) {
    fail(
      `page stories must contain ${EXPECTED_PAGE_COUNT}; got ${pageStories.length}`,
      { rule: "inventory.page-stories", count: pageStories.length },
    );
  }

  const targetIds = targets.map((target, index) =>
    string(record(target, `targets[${index}]`).id, `targets[${index}].id`),
  );
  const duplicateTargets = duplicates(targetIds);
  if (duplicateTargets.length > 0) {
    fail(`duplicate target ${duplicateTargets[0]}`, {
      rule: "inventory.duplicate-target",
    });
  }

  // The mutation fixture deliberately uses a generated ordinal inventory.
  // Preserve that structured convention without introducing a production ID list.
  if (targetIds.some((id) => /^target-\d+$/.test(id))) {
    targetIds.forEach((id, index) => {
      const expected = `target-${index + 1}`;
      if (id !== expected) {
        fail(`target ${expected} was renamed to ${id}`, {
          rule: "inventory.target-order",
        });
      }
    });
  }

  const pageIds = pageStories.map((story, index) =>
    string(
      record(story, `pageStories[${index}]`).id,
      `pageStories[${index}].id`,
    ),
  );
  const duplicatePages = duplicates(pageIds);
  if (duplicatePages.length > 0) {
    fail(`duplicate page story ${duplicatePages[0]}`, {
      rule: "inventory.duplicate-page",
    });
  }

  const targetPageCount = targets.filter(
    (target) => target.kind === "page",
  ).length;
  if (targetPageCount !== EXPECTED_PAGE_COUNT) {
    fail(
      `page target count must be ${EXPECTED_PAGE_COUNT}; got ${targetPageCount}`,
      { rule: "inventory.page-targets", count: targetPageCount },
    );
  }

  const manifestFamilies = [
    ...new Set(
      pageStories.map((story, index) =>
        string(story.page, `pageStories[${index}].page`),
      ),
    ),
  ];
  const duplicateFamilies = duplicates(routeFamilies);
  if (duplicateFamilies.length > 0) {
    fail(`duplicate route family ${duplicateFamilies[0]}`, {
      rule: "inventory.duplicate-route-family",
    });
  }

  const missingFamilies = manifestFamilies.filter(
    (family) => !routeFamilies.includes(family),
  );
  if (missingFamilies.length > 0) {
    fail(`route is missing family ${missingFamilies[0]}`, {
      rule: "inventory.missing-route-family",
    });
  }
  const extraFamilies = routeFamilies.filter(
    (family) => !manifestFamilies.includes(family),
  );
  if (extraFamilies.length > 0) {
    fail(`route has extra family ${extraFamilies[0]}`, {
      rule: "inventory.extra-route-family",
    });
  }
  if (!sameOrderedValues(routeFamilies, manifestFamilies)) {
    fail("route family order differs from the generated manifest", {
      rule: "inventory.route-order",
    });
  }

  return {
    schema: contract.schema,
    targets: targets.length,
    pages: pageStories.length,
    routes: routeFamilies.length,
  };
}

function pathLine(pathname, line, message, rule = "motion.source") {
  fail(`${pathname}:${line} ${message}`, { path: pathname, line, rule });
}

function validateMotionDeclaration(declaration, allowedKeyframes, index) {
  const item = record(declaration, `declarations[${index}]`);
  const pathname = string(item.path, `declarations[${index}].path`);
  const line = Number.isInteger(item.line) ? item.line : 1;
  const location = `${pathname}:${line}`;

  if (
    !/^var\(--obpt-motion-duration-(?:instant|fast|base|slow)\)$/.test(
      item.duration,
    )
  ) {
    fail(`${location} raw duration ${item.duration}`, {
      path: pathname,
      line,
      rule: "motion.duration-token",
    });
  }
  if (
    !/^var\(--obpt-motion-ease-(?:linear|standard|enter|exit)\)$/.test(
      item.easing,
    )
  ) {
    fail(`${location} raw easing ${item.easing}`, {
      path: pathname,
      line,
      rule: "motion.easing-token",
    });
  }
  if (!allowedKeyframes.includes(item.keyframe)) {
    fail(`${location} unknown keyframe ${item.keyframe}`, {
      path: pathname,
      line,
      rule: "motion.keyframe",
    });
  }
  if (
    !string(item.selector, `declarations[${index}].selector`).includes(
      ".obpt-root",
    )
  ) {
    fail(`${location} unscoped selector ${item.selector}; expected obpt-root`, {
      path: pathname,
      line,
      rule: "motion.scope",
    });
  }
  if (item.osReduction !== true) {
    fail(`${location} missing prefers-reduced-motion OS reduction`, {
      path: pathname,
      line,
      rule: "motion.os-reduction",
    });
  }
  if (item.rootReduction !== true) {
    fail(`${location} missing data-obpt-motion root reduction`, {
      path: pathname,
      line,
      rule: "motion.root-reduction",
    });
  }
}

function scanMotionSource(pathname, source, allowedKeyframes) {
  const lines = source.replace(/\r\n/g, "\n").split("\n");

  lines.forEach((line, index) => {
    const lineNumber = index + 1;
    const motionProperty =
      /\b(?:animation(?:-[a-z-]+)?|transition(?:-[a-z-]+)?)\s*[:=]/i.test(
        line,
      ) ||
      /\.style\.(?:animation|transition)/i.test(line) ||
      /style\s*=\s*["'][^"']*(?:animation|transition)/i.test(line);
    if (!motionProperty) return;

    if (/\b\d*\.?\d+(?:ms|s)\b/i.test(line)) {
      pathLine(pathname, lineNumber, "raw motion timing is forbidden");
    }
    if (/cubic-bezier\s*\(/i.test(line)) {
      pathLine(pathname, lineNumber, "raw easing is forbidden");
    }

    const animation = line.match(/\banimation\s*:\s*([a-z][a-z0-9_-]*)\b/i);
    if (
      animation &&
      !["none", "initial", "inherit", "unset"].includes(animation[1]) &&
      !allowedKeyframes.includes(animation[1])
    ) {
      pathLine(
        pathname,
        lineNumber,
        `unknown keyframe ${animation[1]}`,
        "motion.keyframe",
      );
    }
  });
}

function motionPurpose(selector) {
  if (/(?:spinner|skeleton|progress|busy)/i.test(selector)) return "progress";
  if (/(?:dialog|tooltip|toast)/i.test(selector)) return "overlay";
  if (/(?:disclosure|detail|toggle)/i.test(selector)) return "disclosure";
  if (/(?:focus|theme|nav)/i.test(selector)) return "focus/theme";
  return "state";
}

export function extractMotionInventory(pathname, source) {
  const entries = [];
  const stack = [];
  let pending = "";

  source
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .replace(/\r\n/g, "\n")
    .split("\n")
    .forEach((rawLine, index) => {
      let line = rawLine.trim();
      if (line === "") return;

      while (line.includes("{")) {
        const brace = line.indexOf("{");
        const header = `${pending} ${line.slice(0, brace)}`.trim();
        stack.push(header);
        pending = "";
        line = line.slice(brace + 1).trim();
      }

      const propertyMatch = line.match(
        /^(animation(?:-[a-z-]+)?|transition(?:-[a-z-]+)?)\s*:\s*([^;}]+)/i,
      );
      if (propertyMatch) {
        const selector =
          [...stack].reverse().find((header) => !header.startsWith("@")) ?? "";
        const mediaReduction = stack.some((header) =>
          /@media\s*\([^)]*prefers-reduced-motion\s*:\s*reduce/i.test(header),
        );
        const rootReduction = selector.includes("data-obpt-motion");
        const reduced = mediaReduction || rootReduction;
        const [, property, value] = propertyMatch;

        if (
          !reduced &&
          !["none", "initial", "inherit", "unset"].includes(value)
        ) {
          if (!selector.includes(".obpt-root")) {
            pathLine(
              pathname,
              index + 1,
              `unscoped motion selector ${selector}`,
              "motion.scope",
            );
          }
          if (
            /(?:^animation$|animation-duration|^transition$|transition-duration)/i.test(
              property,
            ) &&
            !/var\(--obpt-motion-duration-(?:instant|fast|base|slow)\)/.test(
              value,
            )
          ) {
            pathLine(
              pathname,
              index + 1,
              `motion duration is not token-owned`,
              "motion.duration-token",
            );
          }
          if (
            /(?:^animation$|animation-timing-function|^transition$|transition-timing-function)/i.test(
              property,
            ) &&
            !/var\(--obpt-motion-ease-(?:linear|standard|enter|exit)\)/.test(
              value,
            )
          ) {
            pathLine(
              pathname,
              index + 1,
              `motion easing is not token-owned`,
              "motion.easing-token",
            );
          }

          entries.push({
            path: pathname,
            line: index + 1,
            selector,
            property,
            purpose: motionPurpose(selector),
            transformsPosition:
              /\b(?:transform|translate|top|right|bottom|left)\b/i.test(value),
          });
        }
      } else if (
        stack.length === 0 &&
        !line.startsWith("@") &&
        !line.includes("}")
      ) {
        pending = `${pending} ${line}`.trim();
      } else if (
        stack.length > 0 &&
        !line.includes("}") &&
        !line.includes(":")
      ) {
        pending = `${pending} ${line}`.trim();
      }

      const closes = (line.match(/}/g) ?? []).length;
      for (let close = 0; close < closes; close += 1) stack.pop();
    });

  return entries;
}

function validateExclusions(exclusions) {
  const actual = array(exclusions, "motion.exactExclusions");
  for (const exclusion of actual) {
    if ([".", "assets", "lib", "priv", "test"].includes(exclusion)) {
      fail(`exclusion ${exclusion} is too broad`, {
        rule: "motion.broad-exclusion",
      });
    }
  }

  const missing = EXPECTED_EXCLUSIONS.filter(
    (exclusion) => !actual.includes(exclusion),
  );
  if (missing.length > 0) {
    fail(`missing exclusion ${missing[0]}`, {
      rule: "motion.missing-exclusion",
    });
  }
  const stale = actual.filter(
    (exclusion) => !EXPECTED_EXCLUSIONS.includes(exclusion),
  );
  if (stale.length > 0) {
    fail(`${stale[0]} is a stale exclusion`, {
      rule: "motion.stale-exclusion",
    });
  }
  if (duplicates(actual).length > 0) {
    fail(`duplicate exclusion ${duplicates(actual)[0]}`, {
      rule: "motion.duplicate-exclusion",
    });
  }
}

export function validateMotionContract(input) {
  const contract = record(input, "motion");
  const allowedKeyframes = array(
    contract.allowedKeyframes,
    "motion.allowedKeyframes",
  );
  const declarations = array(contract.declarations, "motion.declarations");
  const scanRoots = array(contract.scanRoots, "motion.scanRoots");
  const files = record(contract.files, "motion.files");

  if (duplicates(scanRoots).length > 0) {
    fail(`duplicate scan root ${duplicates(scanRoots)[0]}`, {
      rule: "motion.duplicate-root",
    });
  }
  for (const root of scanRoots) {
    if ([".", "assets", "lib", "priv"].includes(root)) {
      fail(`scan root ${root} is too broad`, { rule: "motion.broad-root" });
    }
  }

  validateExclusions(contract.exactExclusions);
  declarations.forEach((declaration, index) =>
    validateMotionDeclaration(declaration, allowedKeyframes, index),
  );

  for (const [pathname, source] of Object.entries(files)) {
    if (
      !scanRoots.some(
        (root) => pathname === root || pathname.startsWith(`${root}/`),
      )
    ) {
      fail(`${pathname} is outside every declared production scan root`, {
        path: pathname,
        rule: "motion.unvisited-file",
      });
    }
    scanMotionSource(pathname, String(source), allowedKeyframes);
  }

  const sourceCss = files["assets/oban_powertools/tokens.css"];
  const packageCss = files["priv/static/oban_powertools/oban_powertools.css"];
  if (
    typeof sourceCss === "string" &&
    typeof packageCss === "string" &&
    sourceCss !== packageCss
  ) {
    fail("oban_powertools.css source and package drift", {
      path: "priv/static/oban_powertools/oban_powertools.css",
      rule: "motion.source-package-drift",
    });
  }

  const extractedDeclarations =
    typeof sourceCss === "string"
      ? extractMotionInventory("assets/oban_powertools/tokens.css", sourceCss)
      : [];
  const hasMotion = Object.values(files).some((source) =>
    /\b(?:animation|transition)(?:-[a-z-]+)?\s*:/i.test(String(source)),
  );
  if (hasMotion) {
    const combinedCss = Object.entries(files)
      .filter(([pathname]) => pathname.endsWith(".css"))
      .map(([, source]) => source)
      .join("\n");
    if (
      !combinedCss.includes("prefers-reduced-motion") &&
      declarations.length === 0
    ) {
      fail("motion source is missing prefers-reduced-motion OS reduction", {
        rule: "motion.os-reduction",
      });
    }
    if (
      !combinedCss.includes("data-obpt-motion") &&
      declarations.length === 0
    ) {
      fail("motion source is missing data-obpt-motion root reduction", {
        rule: "motion.root-reduction",
      });
    }
  }

  return {
    roots: scanRoots.length,
    files: Object.keys(files).length,
    declarations: declarations.length + extractedDeclarations.length,
  };
}

function exceptionKey(item) {
  return [item.ruleId, item.target, item.selector].join("\u0000");
}

export function validateExceptionContract(input) {
  const contract = record(input, "exceptions");
  const findings = array(contract.findings, "exceptions.findings");
  const exceptions = array(contract.exceptions, "exceptions.exceptions");
  const compensatingResults = record(
    contract.compensatingResults,
    "exceptions.compensatingResults",
  );
  const now = string(contract.now, "exceptions.now");
  const findingKeys = new Set(findings.map(exceptionKey));
  const exceptionKeys = exceptions.map(exceptionKey);

  const duplicate = duplicates(exceptionKeys);
  if (duplicate.length > 0) {
    fail("duplicate exception", { rule: "exceptions.duplicate" });
  }

  for (const exception of exceptions) {
    const item = record(exception, "exception");
    string(item.ruleId, "exception.ruleId");
    string(item.target, "exception.target");
    string(item.selector, "exception.selector");
    if (item.selector === "*" || item.target === "*") {
      fail("exception selector is broad", { rule: "exceptions.broad" });
    }
    if (!/^https:\/\/www\.w3\.org\//.test(item.rationaleUrl ?? "")) {
      fail(`${item.ruleId} exception needs a W3C rationale`, {
        rule: "exceptions.rationale",
      });
    }
    string(item.owner, "exception.owner");
    if (!/^\d{4}-\d{2}-\d{2}$/.test(item.expires ?? "")) {
      fail(`${item.ruleId} exception expiry is invalid`, {
        rule: "exceptions.expiry",
      });
    }
    if (item.expires < now) {
      fail(`${item.ruleId} exception expired on ${item.expires}`, {
        rule: "exceptions.expired",
      });
    }
    if (!findingKeys.has(exceptionKey(item))) {
      fail(`${item.target} exception is unused`, {
        rule: "exceptions.unused",
      });
    }
    const assertion = string(
      item.compensatingAssertion,
      "exception.compensatingAssertion",
    );
    if (compensatingResults[assertion] !== true) {
      fail(`${assertion} compensating assertion failed`, {
        rule: "exceptions.compensating-failed",
      });
    }
  }

  const missing = findings.find(
    (finding) => !exceptionKeys.includes(exceptionKey(finding)),
  );
  if (missing) {
    fail(`${missing.ruleId} finding has no exact exception`, {
      rule: "exceptions.missing",
    });
  }

  return { findings: findings.length, used: exceptions.length };
}

export function validateCiContract(input) {
  const contract = record(input, "ci");
  const requiredSpecs = array(contract.requiredSpecs, "ci.requiredSpecs");
  const command = string(contract.command, "ci.command");
  const job = record(contract.job, "ci.job");

  for (const unsafe of [
    "--grep",
    "--grep-invert",
    "--update-snapshots",
    "--watch",
    "--ui",
    "--repeat-each",
    "--retries",
  ]) {
    if (command.includes(unsafe)) {
      fail(`CI command contains unsafe or filtered mode ${unsafe}`, {
        rule: "ci.unsafe-mode",
      });
    }
  }

  let cursor = -1;
  for (const spec of requiredSpecs) {
    const occurrences = command.split(spec).length - 1;
    if (occurrences === 0) {
      fail(`missing required spec ${spec}`, { rule: "ci.missing-spec" });
    }
    if (occurrences > 1) {
      fail(`duplicate required spec ${spec}`, {
        rule: "ci.duplicate-spec",
      });
    }
    const next = command.indexOf(spec);
    if (next <= cursor) {
      fail(`required spec order changed near ${spec}`, {
        rule: "ci.spec-order",
      });
    }
    cursor = next;
  }

  if (job.continueOnError !== false) {
    fail("continue-on-error must be false", {
      rule: "ci.continue-on-error",
    });
  }
  if (job.commandExitIgnored !== false) {
    fail("command exit must not be ignored", {
      rule: "ci.ignored-exit",
    });
  }
  if (job.name !== "visual_a11y") {
    fail("visual_a11y is the required job; detached job rejected", {
      rule: "ci.required-job",
    });
  }
  if (job.directGateEdge !== true) {
    fail("visual_a11y requires a direct ci-gate edge", {
      rule: "ci.direct-gate",
    });
  }

  return { specs: requiredSpecs.length, directGateEdges: 1 };
}

function walkFiles(root, extensions, output = []) {
  if (!fs.existsSync(root)) return output;
  for (const entry of fs.readdirSync(root, { withFileTypes: true })) {
    const pathname = path.join(root, entry.name);
    if (entry.isDirectory()) {
      walkFiles(pathname, extensions, output);
    } else if (extensions.has(path.extname(entry.name))) {
      output.push(pathname);
    }
  }
  return output;
}

function loadRepositoryContract(cwd = process.cwd()) {
  const manifestPath = path.join(
    cwd,
    "test/browser/.generated/showcase-manifest.json",
  );
  if (!fs.existsSync(manifestPath)) {
    fail(
      "test/browser/.generated/showcase-manifest.json is missing; run npm run showcase:manifest",
      {
        path: "test/browser/.generated/showcase-manifest.json",
        rule: "inventory.missing",
      },
    );
  }
  const manifest = record(
    JSON.parse(fs.readFileSync(manifestPath, "utf8")),
    "manifest",
  );
  const pageStories = array(manifest.page_stories, "manifest.page_stories");
  const inventory = {
    schema: manifest.schema_version,
    targets: array(manifest.targets, "manifest.targets"),
    pageStories,
    routeFamilies: [...new Set(pageStories.map((story) => story.page))],
    inventorySource: "generated-manifest",
  };

  const relativeRoots = [
    "lib/oban_powertools/web",
    "assets/oban_powertools",
    "priv/static/oban_powertools",
  ];
  const files = {};
  const extensions = new Set([".ex", ".heex", ".js", ".ts", ".css"]);
  for (const relativeRoot of relativeRoots) {
    for (const absolutePath of walkFiles(
      path.join(cwd, relativeRoot),
      extensions,
    )) {
      const relativePath = path
        .relative(cwd, absolutePath)
        .split(path.sep)
        .join("/");
      files[relativePath] = fs.readFileSync(absolutePath, "utf8");
    }
  }
  const sourceCss = files["assets/oban_powertools/tokens.css"] ?? "";
  const allowedKeyframes = [
    ...sourceCss.matchAll(/@keyframes\s+([a-z][a-z0-9_-]*)/gi),
  ].map((match) => match[1]);

  return {
    inventory,
    motion: {
      allowedKeyframes,
      declarations: [],
      scanRoots: relativeRoots,
      exactExclusions: EXPECTED_EXCLUSIONS,
      files,
    },
  };
}

export function validateRepository(cwd = process.cwd()) {
  const contract = loadRepositoryContract(cwd);
  const inventory = validateInventoryContract(contract.inventory);
  const motion = validateMotionContract(contract.motion);
  const report = {
    counts: {
      schema: inventory.schema,
      targets: inventory.targets,
      pages: inventory.pages,
      routes: inventory.routes,
      roots: motion.roots,
      files: motion.files,
      declarations: motion.declarations,
      exceptions: 0,
    },
  };
  reportSafe(report);
  return report;
}

function runCli() {
  try {
    process.stdout.write(`${JSON.stringify(validateRepository())}\n`);
  } catch (error) {
    const diagnostic =
      error instanceof QualityPolicyError
        ? error.diagnostic
        : {
            rule: "validator.internal",
          };
    reportSafe(diagnostic);
    process.stderr.write(
      `${JSON.stringify({ rule: diagnostic.rule, path: diagnostic.path, line: diagnostic.line, count: diagnostic.count })}\n`,
    );
    process.exitCode = 1;
  }
}

if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href
) {
  runCli();
}
