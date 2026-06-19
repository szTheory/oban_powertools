import { themes, viewports, type ShowcaseTheme, type ViewportName } from './manifest';

export { themes, viewports };
export type { ShowcaseTheme, ViewportName };

export const deterministicBrowser = {
  colorScheme: 'light',
  locale: 'en-US',
  reducedMotion: 'reduce',
  timezoneId: 'UTC',
  deviceScaleFactor: 1
} as const;

export function viewportNameFromProject(projectName: string): ViewportName {
  const viewportName = projectName.replace(/^chromium-/, '') as ViewportName;

  if (!viewports.some((viewport) => viewport.name === viewportName)) {
    throw new Error(`Unknown Playwright viewport project: ${projectName}`);
  }

  return viewportName;
}

export function assertTheme(theme: string): asserts theme is ShowcaseTheme {
  if (!themes.includes(theme as ShowcaseTheme)) {
    throw new Error(`Unknown showcase theme: ${theme}`);
  }
}
