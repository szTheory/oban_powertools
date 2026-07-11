import { expect, test, type Locator, type Page } from '@playwright/test';
import { formStories, themes, type ShowcaseFormStory } from '../support/manifest';
import { viewportNameFromProject } from '../support/deterministic';
import { prepareShowcase, targetLocator } from '../support/showcase';

function formStory(id: string): ShowcaseFormStory {
  const story = formStories.find((candidate) => candidate.id === id);

  if (!story) {
    throw new Error(`Missing form story in generated manifest: ${id}`);
  }

  return story;
}

async function prepareFormStory(
  page: Page,
  projectName: string,
  story: ShowcaseFormStory,
  theme = 'light'
): Promise<Locator> {
  await prepareShowcase(page, {
    theme,
    viewportName: viewportNameFromProject(projectName)
  });

  const locator = targetLocator(page, story);
  await expect(locator).toBeVisible();
  return locator;
}

async function expectVisibleOutline(locator: Locator, label: string): Promise<void> {
  const outline = await locator.evaluate((element) => {
    const style = window.getComputedStyle(element);
    return {
      color: style.outlineColor,
      style: style.outlineStyle,
      width: Number.parseFloat(style.outlineWidth)
    };
  });

  expect(outline.style, `${label} should use a visible outline style`).not.toBe('none');
  expect(outline.width, `${label} should use a non-zero outline width`).toBeGreaterThan(0);
  expect(outline.color, `${label} should use a visible outline color`).not.toBe(
    'rgba(0, 0, 0, 0)'
  );
}

test.describe('form behavior contracts', () => {
  test('labels focus and toggle their native controls with exact identity wiring', async ({
    page
  }, testInfo) => {
    const inputs = await prepareFormStory(
      page,
      testInfo.project.name,
      formStory('form-input-states')
    );
    const input = inputs.locator('#form-input-required');
    const inputLabel = inputs.getByText('Worker name Required', { exact: true });

    await expect(inputLabel).toHaveAttribute('for', await input.getAttribute('id'));
    await inputLabel.click();
    await expect(input).toBeFocused();

    const choices = targetLocator(page, formStory('form-checkbox-modes'));
    const checkbox = choices.getByRole('checkbox', { name: 'Include scheduled jobs' });
    const checkboxLabel = choices.getByText('Include scheduled jobs', { exact: true }).locator('..');
    await expect(checkboxLabel).toHaveAttribute('for', await checkbox.getAttribute('id'));
    await expect(checkbox).toBeChecked();
    await checkboxLabel.click();
    await expect(checkbox).not.toBeChecked();
  });

  test('fieldset legend names the native radio group and arrow keys move selection', async ({
    page
  }, testInfo) => {
    const story = await prepareFormStory(
      page,
      testInfo.project.name,
      formStory('form-radio-group')
    );
    const group = story.getByRole('group', { name: 'Job state' });
    const retryable = group.getByRole('radio', { name: 'Retryable' });
    const discarded = group.getByRole('radio', { name: 'Discarded' });

    await expect(group.locator('legend')).toHaveText('Job state');
    await expect(retryable).toBeChecked();
    await retryable.focus();
    await page.keyboard.press('ArrowDown');
    await expect(discarded).toBeFocused();
    await expect(discarded).toBeChecked();
  });

  test('descriptions and visible errors have ordered unique associations and honest invalid state', async ({
    page
  }, testInfo) => {
    const story = await prepareFormStory(
      page,
      testInfo.project.name,
      formStory('form-validation-wiring')
    );
    const input = story.getByRole('textbox', { name: 'Worker name' });
    const ids = await story.locator('[id]').evaluateAll((elements) =>
      elements.map((element) => element.id).filter((id) => id.length > 0)
    );
    const duplicateIds = ids.filter((id, index) => ids.indexOf(id) !== index);
    const errors = story.locator('.obpt-error');
    const errorIds = await errors.evaluateAll((elements) =>
      elements.map((element) => element.id).filter((id) => id.length > 0)
    );
    const describedBy = (await input.getAttribute('aria-describedby'))?.split(/\s+/) ?? [];

    expect(duplicateIds).toEqual([]);
    await expect(errors).toHaveCount(2);
    expect(errorIds).toHaveLength(2);
    expect(new Set(errorIds).size).toBe(2);
    expect(describedBy).toHaveLength(4);
    expect(new Set(describedBy).size).toBe(4);
    expect(describedBy[0]).toBe('form-validation-context');
    expect(describedBy[1]).toBe(`${await input.getAttribute('id')}-hint`);
    expect(describedBy[2]).toBe(`${await input.getAttribute('id')}-error-1`);
    expect(describedBy[3]).toBe(`${await input.getAttribute('id')}-error-2`);
    for (const errorId of errorIds) {
      expect(describedBy).toContain(errorId);
    }
    await expect(input).toHaveAttribute('aria-invalid', 'true');
    await expect(story.locator(`#${describedBy[1]}`)).toBeVisible();
    await expect(story.locator(`#${describedBy[2]}`)).toContainText('Enter a worker name.');
    await expect(story.locator(`#${describedBy[3]}`)).toContainText('Reason must be at least 10 characters.');

    const validStory = targetLocator(page, formStory('form-input-states'));
    const validInput = validStory.locator('#form-input-required');
    await expect(validInput).not.toHaveAttribute('aria-invalid', /.+/);
    await expect(validInput.locator('xpath=..').locator('.obpt-error')).toHaveCount(0);
  });

  test('boolean submission and event selection keep distinct hidden-value contracts', async ({
    page
  }, testInfo) => {
    const story = await prepareFormStory(
      page,
      testInfo.project.name,
      formStory('form-checkbox-modes')
    );
    const named = story.getByRole('checkbox', { name: 'Include scheduled jobs' });
    const eventSelection = story.getByRole('checkbox', { name: 'Select job 01JZ8M5P' });
    const namedKey = await named.getAttribute('name');
    expect(namedKey).toBeTruthy();
    const formDataFromStory = async (): Promise<Record<string, string[]>> =>
      story.evaluate((element) => {
        const form = document.createElement('form');
        const clone = element.cloneNode(true);
        form.append(clone);
        document.body.append(form);
        try {
          const data: Record<string, string[]> = {};
          for (const [key, value] of new FormData(form).entries()) {
            data[key] ??= [];
            data[key].push(String(value));
          }
          return data;
        } finally {
          form.remove();
        }
      });

    await expect(
      story.locator(`input[type="hidden"][name="${await named.getAttribute('name')}"][value="false"]`)
    ).toHaveCount(1);
    await expect(
      eventSelection.locator('xpath=../..').locator('input[type="hidden"]')
    ).toHaveCount(0);
    await expect(eventSelection).not.toHaveAttribute('name', /.+/);

    expect(await formDataFromStory()).toEqual({ [namedKey as string]: ['false', 'true'] });

    await named.focus();
    const before = await named.isChecked();
    await page.keyboard.press('Space');
    await expect(named).toBeChecked({ checked: !before });
    expect(await formDataFromStory()).toEqual({ [namedKey as string]: ['false'] });
  });

  test('switch visible state follows native Space and click behavior while pending ownership stays explicit', async ({
    page
  }, testInfo) => {
    const story = await prepareFormStory(
      page,
      testInfo.project.name,
      formStory('form-switch-states')
    );
    const active = story.locator('#form-switch-off');
    const activeShell = active.locator('xpath=ancestor::label[contains(@class, "obpt-switch")]');
    const offState = activeShell.locator('.obpt-switch__state-label--off');
    const onState = activeShell.locator('.obpt-switch__state-label--on');
    const pending = story.locator('#form-switch-pending');

    await expect(active).not.toBeChecked();
    await expect(offState).toBeVisible();
    await expect(onState).toBeHidden();
    await active.focus();
    await page.keyboard.press('Space');
    await expect(active).toBeChecked();
    await expect(onState).toBeVisible();
    await expect(offState).toBeHidden();
    await activeShell.click();
    await expect(active).not.toBeChecked();
    await expect(offState).toBeVisible();
    await expect(onState).toBeHidden();
    await expect(pending).toBeDisabled();
    await expect(pending).toHaveAccessibleName(/Pause queue processing/);
    await expect(story).toHaveAttribute('data-obpt-state', /pending/);
    await expect(story.getByText('Updating queue setting.', { exact: true })).toBeVisible();
    await expect(story.locator('[aria-busy="true"]')).toHaveCount(0);

    await expect(
      story.locator(
        `input[type="hidden"][name="${await pending.getAttribute('name')}"][value="false"][disabled]`
      )
    ).toHaveCount(1);
  });

  test('disabled controls cannot focus or change while readonly content remains selectable', async ({
    page
  }, testInfo) => {
    const story = await prepareFormStory(
      page,
      testInfo.project.name,
      formStory('form-disabled-readonly')
    );
    const disabled = story.getByRole('combobox', { name: 'Queue' });
    const readonly = story.getByRole('textbox', { name: 'Job ID' });
    const disabledValue = await disabled.inputValue();
    const readonlyValue = await readonly.inputValue();

    await disabled.focus();
    await expect(disabled).not.toBeFocused();
    await expect(disabled).toHaveValue(disabledValue);

    await readonly.focus();
    await expect(readonly).toBeFocused();
    await expect(readonly).toHaveAttribute('readonly', '');
    await readonly.selectText();
    expect(await readonly.evaluate((element) => (element as HTMLInputElement).selectionEnd)).toBe(
      readonlyValue.length
    );
    await page.keyboard.type('changed');
    await expect(readonly).toHaveValue(readonlyValue);
  });

  test('filter-ready fields remain native controls without popup ARIA', async ({ page }, testInfo) => {
    const story = await prepareFormStory(
      page,
      testInfo.project.name,
      formStory('form-filter-ready')
    );
    const search = story.getByRole('searchbox', { name: 'Search jobs' });
    const select = story.getByRole('combobox', { name: 'Job state' });

    await expect(search).not.toHaveAttribute('role', /.+/);
    await expect(select).not.toHaveAttribute('role', /.+/);
    for (const control of [search, select]) {
      await expect(control).not.toHaveAttribute('aria-expanded', /.+/);
      await expect(control).not.toHaveAttribute('aria-controls', /.+/);
      await expect(control).not.toHaveAttribute('aria-activedescendant', /.+/);
    }
  });

  for (const theme of themes) {
    test(`form controls expose visible keyboard focus in ${theme}`, async ({ page }, testInfo) => {
      const story = await prepareFormStory(
        page,
        testInfo.project.name,
        formStory('form-input-states'),
        theme
      );
      const input = story.locator('#form-input-required');

      await input.focus();
      await expect(input).toBeFocused();
      await expectVisibleOutline(input, `required input in ${theme}`);
    });
  }

  test('reduced motion collapses transitions without hiding switch state', async ({ page }, testInfo) => {
    const story = await prepareFormStory(
      page,
      testInfo.project.name,
      formStory('form-switch-states')
    );
    const root = page.locator('.obpt-root');
    const active = story.getByRole('checkbox', { name: 'Pause queue processing' }).first();
    const track = active.locator('xpath=following-sibling::*[contains(@class, "obpt-switch__track")]');

    await expect(root).toHaveAttribute('data-obpt-motion', 'reduce');
    await expect(
      story
        .locator('#form-switch-off')
        .locator('xpath=ancestor::label[contains(@class, "obpt-switch")]')
        .locator('.obpt-switch__state-label--off')
    ).toBeVisible();
    expect(
      Number.parseFloat(
        await track.evaluate((element) => getComputedStyle(element).transitionDuration)
      )
    ).toBeLessThanOrEqual(0.001);
  });

  test('form stories and page do not overflow horizontally at 320px', async ({ page }, testInfo) => {
    await prepareFormStory(page, testInfo.project.name, formStory('form-long-content'));
    const overflow = await page.evaluate(() => ({
      body: document.body.scrollWidth - document.body.clientWidth,
      document: document.documentElement.scrollWidth - document.documentElement.clientWidth,
      stories: Array.from(document.querySelectorAll('[data-obpt-form-story]')).map(
        (element) => element.scrollWidth - element.clientWidth
      )
    }));

    expect(overflow.document).toBeLessThanOrEqual(1);
    expect(overflow.body).toBeLessThanOrEqual(1);
    expect(Math.max(...overflow.stories)).toBeLessThanOrEqual(1);
  });
});
