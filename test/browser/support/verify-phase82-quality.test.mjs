import assert from "node:assert/strict";
import { describe, test } from "node:test";

let quality;

function changed(name, original, mutated) {
  assert.notDeepEqual(
    mutated,
    original,
    `${name}: mutation must change structured input`,
  );
  return mutated;
}

function rejects(name, validator, original, mutate, diagnostic) {
  test(name, async () => {
    quality = await import("./verify-phase82-quality.mjs");
    const mutated = changed(name, original, mutate(structuredClone(original)));
    assert.throws(
      () => validator(mutated),
      (error) => {
        assert.match(String(error.message), diagnostic);
        return true;
      },
      `${name}: validator must reject the mutation`,
    );
  });
}

const manifestContract = {
  schema: 8,
  targets: Array.from({ length: 163 }, (_, index) => ({
    id: `target-${index + 1}`,
    kind: index < 64 ? "component" : "page",
  })),
  pageStories: Array.from({ length: 99 }, (_, index) => ({
    id: `page-${index + 1}`,
    page: [
      "overview",
      "cron",
      "limiters",
      "audit",
      "jobs",
      "forensics",
      "batches",
      "workflows",
      "lifeline",
    ][index % 9],
  })),
  routeFamilies: [
    "overview",
    "cron",
    "limiters",
    "audit",
    "jobs",
    "forensics",
    "batches",
    "workflows",
    "lifeline",
  ],
  inventorySource: "generated-manifest",
};

describe("generated inventory and route equality", () => {
  rejects(
    "missing target",
    (input) => quality.validateInventoryContract(input),
    manifestContract,
    (input) => {
      input.targets.pop();
      return input;
    },
    /targets.*163|missing.*target/i,
  );
  rejects(
    "extra target",
    (input) => quality.validateInventoryContract(input),
    manifestContract,
    (input) => {
      input.targets.push({ id: "target-extra", kind: "component" });
      return input;
    },
    /targets.*163|extra.*target/i,
  );
  rejects(
    "duplicate target",
    (input) => quality.validateInventoryContract(input),
    manifestContract,
    (input) => {
      input.targets[1].id = input.targets[0].id;
      return input;
    },
    /duplicate.*target-1/i,
  );
  rejects(
    "renamed target",
    (input) => quality.validateInventoryContract(input),
    manifestContract,
    (input) => {
      input.targets[0].id = "renamed-target";
      return input;
    },
    /renamed-target|target-1/i,
  );
  rejects(
    "missing page story",
    (input) => quality.validateInventoryContract(input),
    manifestContract,
    (input) => {
      input.pageStories.pop();
      return input;
    },
    /page.*99|missing.*page/i,
  );
  rejects(
    "missing route family",
    (input) => quality.validateInventoryContract(input),
    manifestContract,
    (input) => {
      input.routeFamilies.pop();
      return input;
    },
    /route.*lifeline|missing.*family/i,
  );
  rejects(
    "extra route family",
    (input) => quality.validateInventoryContract(input),
    manifestContract,
    (input) => {
      input.routeFamilies.push("handwritten");
      return input;
    },
    /route.*handwritten|extra.*family/i,
  );
  rejects(
    "hard-coded browser inventory",
    (input) => quality.validateInventoryContract(input),
    manifestContract,
    (input) => {
      input.inventorySource = "typescript-array";
      return input;
    },
    /inventory.*generated-manifest|hand.?written/i,
  );
  rejects(
    "schema drift",
    (input) => quality.validateInventoryContract(input),
    manifestContract,
    (input) => {
      input.schema = 9;
      return input;
    },
    /schema.*8/i,
  );
});

const motionContract = {
  allowedKeyframes: ["obpt-spin", "obpt-fade-in"],
  declarations: [
    {
      path: "assets/oban_powertools/tokens.css",
      line: 200,
      selector: ".obpt-root .obpt-spinner",
      property: "animation",
      duration: "var(--obpt-motion-duration-slow)",
      easing: "var(--obpt-motion-ease-linear)",
      keyframe: "obpt-spin",
      purpose: "progress",
      osReduction: true,
      rootReduction: true,
    },
  ],
  scanRoots: [
    "lib/oban_powertools/web/components",
    "lib/oban_powertools/web/live",
    "assets/oban_powertools",
    "priv/static/oban_powertools",
  ],
  exactExclusions: [
    "assets/vendor",
    "test/browser/fixtures",
    "priv/static/oban_powertools/oban_powertools.js:generated",
  ],
  files: {
    "lib/oban_powertools/web/components/fixture.ex": "def render, do: :ok\n",
    "lib/oban_powertools/web/live/fixture.ex": "def render, do: :ok\n",
    "assets/oban_powertools/fixture.js": "export const fixture = true;\n",
    "assets/oban_powertools/tokens.css":
      ".obpt-root { transition-duration: var(--obpt-motion-duration-fast); }\n",
    "priv/static/oban_powertools/oban_powertools.css":
      ".obpt-root { transition-duration: var(--obpt-motion-duration-fast); }\n",
  },
};

describe("static motion policy", () => {
  rejects(
    "raw duration",
    (input) => quality.validateMotionContract(input),
    motionContract,
    (input) => {
      input.declarations[0].duration = "180ms";
      return input;
    },
    /tokens\.css:200.*180ms|180ms.*tokens\.css:200/i,
  );
  rejects(
    "raw easing",
    (input) => quality.validateMotionContract(input),
    motionContract,
    (input) => {
      input.declarations[0].easing = "cubic-bezier(0.2, 0, 0, 1)";
      return input;
    },
    /tokens\.css:200.*cubic-bezier|cubic-bezier.*tokens\.css:200/i,
  );
  rejects(
    "unknown keyframe",
    (input) => quality.validateMotionContract(input),
    motionContract,
    (input) => {
      input.declarations[0].keyframe = "unknown-pulse";
      return input;
    },
    /tokens\.css:200.*unknown-pulse|unknown-pulse.*tokens\.css:200/i,
  );
  rejects(
    "unscoped selector",
    (input) => quality.validateMotionContract(input),
    motionContract,
    (input) => {
      input.declarations[0].selector = "body .obpt-spinner";
      return input;
    },
    /tokens\.css:200.*body.*obpt-root|unscoped/i,
  );
  rejects(
    "missing OS reduction",
    (input) => quality.validateMotionContract(input),
    motionContract,
    (input) => {
      input.declarations[0].osReduction = false;
      return input;
    },
    /tokens\.css:200.*prefers-reduced-motion|OS reduction/i,
  );
  rejects(
    "missing root reduction",
    (input) => quality.validateMotionContract(input),
    motionContract,
    (input) => {
      input.declarations[0].rootReduction = false;
      return input;
    },
    /tokens\.css:200.*data-obpt-motion|root reduction/i,
  );
  rejects(
    "source and package CSS drift",
    (input) => quality.validateMotionContract(input),
    motionContract,
    (input) => {
      input.files["priv/static/oban_powertools/oban_powertools.css"] +=
        "/* drift */\n";
      return input;
    },
    /oban_powertools\.css.*drift|source.*package/i,
  );

  const rootMutations = [
    {
      name: "production HEEx or Elixir component declaration",
      path: "lib/oban_powertools/web/components/fixture.ex",
      line: 2,
      text: '~H"""<div style="transition: opacity 2s">bad</div>"""\n',
    },
    {
      name: "production LiveView declaration",
      path: "lib/oban_powertools/web/live/fixture.ex",
      line: 2,
      text: '~H"""<div style="animation: pulse 2s">bad</div>"""\n',
    },
    {
      name: "client JavaScript declaration",
      path: "assets/oban_powertools/fixture.js",
      line: 2,
      text: 'node.style.transition = "opacity 2s";\n',
    },
    {
      name: "source CSS declaration",
      path: "assets/oban_powertools/tokens.css",
      line: 2,
      text: ".obpt-root .bad { transition: opacity 2s ease; }\n",
    },
    {
      name: "packaged CSS declaration",
      path: "priv/static/oban_powertools/oban_powertools.css",
      line: 2,
      text: ".obpt-root .bad { animation: pulse 2s infinite; }\n",
    },
  ];

  for (const fixture of rootMutations) {
    rejects(
      fixture.name,
      (input) => quality.validateMotionContract(input),
      motionContract,
      (input) => {
        assert.ok(
          input.scanRoots.some((root) => fixture.path.startsWith(root)),
          `${fixture.name}: mutation path must be in a declared production scan root`,
        );
        input.files[fixture.path] += fixture.text;
        assert.ok(
          input.files[fixture.path].includes(fixture.text),
          `${fixture.name}: mutation must land in ${fixture.path}`,
        );
        return input;
      },
      new RegExp(`${fixture.path.replaceAll("/", "\\/")}:${fixture.line}`),
    );
  }

  rejects(
    "broad exclusion",
    (input) => quality.validateMotionContract(input),
    motionContract,
    (input) => {
      input.exactExclusions[0] = "assets";
      return input;
    },
    /exclusion.*assets.*broad|broad.*assets/i,
  );
  rejects(
    "missing declared exclusion",
    (input) => quality.validateMotionContract(input),
    motionContract,
    (input) => {
      input.exactExclusions.pop();
      return input;
    },
    /exclusion.*generated|missing.*exclusion/i,
  );
  rejects(
    "stale exclusion",
    (input) => quality.validateMotionContract(input),
    motionContract,
    (input) => {
      input.exactExclusions.push("vendor/removed-file.js");
      return input;
    },
    /vendor\/removed-file\.js.*stale|stale.*vendor\/removed-file\.js/i,
  );
});

const exceptionContract = {
  now: "2026-07-29",
  findings: [
    {
      ruleId: "color-contrast",
      target: "page-overview-default",
      selector: "#subject",
      impact: "moderate",
    },
  ],
  exceptions: [
    {
      ruleId: "color-contrast",
      target: "page-overview-default",
      selector: "#subject",
      rationaleUrl:
        "https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum",
      owner: "web-quality",
      expires: "2026-08-31",
      compensatingAssertion: "semantic-boundary-visible",
    },
  ],
  compensatingResults: { "semantic-boundary-visible": true },
};

describe("exact expiring exception policy", () => {
  rejects(
    "expired exception",
    (input) => quality.validateExceptionContract(input),
    exceptionContract,
    (input) => {
      input.exceptions[0].expires = "2026-07-01";
      return input;
    },
    /color-contrast.*expired|expired.*color-contrast/i,
  );
  rejects(
    "unused exception",
    (input) => quality.validateExceptionContract(input),
    exceptionContract,
    (input) => {
      input.exceptions[0].target = "page-missing";
      return input;
    },
    /page-missing.*unused|unused.*page-missing/i,
  );
  rejects(
    "broad exception",
    (input) => quality.validateExceptionContract(input),
    exceptionContract,
    (input) => {
      input.exceptions[0].selector = "*";
      return input;
    },
    /selector.*broad|broad.*selector/i,
  );
  rejects(
    "failed compensating assertion",
    (input) => quality.validateExceptionContract(input),
    exceptionContract,
    (input) => {
      input.compensatingResults["semantic-boundary-visible"] = false;
      return input;
    },
    /semantic-boundary-visible.*failed|compensat.*failed/i,
  );
});

const ciContract = {
  requiredSpecs: [
    "test/browser/specs/system-quality-contract.spec.ts",
    "test/browser/specs/system-quality.spec.ts",
    "test/browser/specs/page.acceptance.spec.ts",
    "test/browser/specs/showcase.a11y.spec.ts",
    "test/browser/specs/showcase.vrt.spec.ts",
  ],
  command: [
    "npx playwright test",
    "test/browser/specs/system-quality-contract.spec.ts",
    "test/browser/specs/system-quality.spec.ts",
    "test/browser/specs/page.acceptance.spec.ts",
    "test/browser/specs/showcase.a11y.spec.ts",
    "test/browser/specs/showcase.vrt.spec.ts",
  ].join(" "),
  job: {
    name: "visual_a11y",
    continueOnError: false,
    commandExitIgnored: false,
    directGateEdge: true,
  },
};

describe("required CI graph bypass mutations", () => {
  rejects(
    "omitted spec",
    (input) => quality.validateCiContract(input),
    ciContract,
    (input) => {
      input.command = input.command.replace(
        " test/browser/specs/system-quality.spec.ts",
        "",
      );
      return input;
    },
    /missing.*system-quality\.spec\.ts|system-quality\.spec\.ts.*missing/i,
  );
  rejects(
    "reordered spec",
    (input) => quality.validateCiContract(input),
    ciContract,
    (input) => {
      const [first, second] = input.requiredSpecs;
      input.command = input.command
        .replace(first, "__swap__")
        .replace(second, first)
        .replace("__swap__", second);
      return input;
    },
    /order.*system-quality|system-quality.*order/i,
  );
  rejects(
    "filtered command",
    (input) => quality.validateCiContract(input),
    ciContract,
    (input) => {
      input.command += " --grep @phase82";
      return input;
    },
    /--grep|filtered/i,
  );
  rejects(
    "duplicated spec",
    (input) => quality.validateCiContract(input),
    ciContract,
    (input) => {
      input.command += ` ${input.requiredSpecs[0]}`;
      return input;
    },
    /duplicate.*system-quality-contract|system-quality-contract.*duplicate/i,
  );

  for (const unsafe of ["--update-snapshots", "--watch", "--ui"]) {
    rejects(
      `${unsafe} evidence mode`,
      (input) => quality.validateCiContract(input),
      ciContract,
      (input) => {
        input.command += ` ${unsafe}`;
        return input;
      },
      new RegExp(unsafe.replaceAll("-", "\\-")),
    );
  }

  rejects(
    "ignored job failure",
    (input) => quality.validateCiContract(input),
    ciContract,
    (input) => {
      input.job.continueOnError = true;
      return input;
    },
    /continue.?on.?error|ignored.*failure/i,
  );
  rejects(
    "ignored command failure",
    (input) => quality.validateCiContract(input),
    ciContract,
    (input) => {
      input.job.commandExitIgnored = true;
      return input;
    },
    /command.*ignored|ignored.*exit/i,
  );
  rejects(
    "detached required job",
    (input) => quality.validateCiContract(input),
    ciContract,
    (input) => {
      input.job.name = "nightly_visual_a11y";
      return input;
    },
    /visual_a11y.*required|detached/i,
  );
  rejects(
    "missing direct gate edge",
    (input) => quality.validateCiContract(input),
    ciContract,
    (input) => {
      input.job.directGateEdge = false;
      return input;
    },
    /ci-gate|direct.*gate/i,
  );
});
