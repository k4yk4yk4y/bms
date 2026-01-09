// Playwright test for permanent bonus preview section
const { test, expect } = require('@playwright/test');

async function selectProject(page, projectName) {
  await page.goto('/bonuses');
  await page.selectOption('select[name="project_id"]', { label: projectName });
  await page.click('input[type="submit"][value="Filter"]');
}

async function waitForPermanentSection(page) {
  const sectionHeader = page.locator('h5:has-text("Permanent Bonuses for")');
  const emptyAlert = page.locator('text=No permanent bonuses configured');

  await Promise.race([
    sectionHeader.waitFor({ state: 'visible', timeout: 10000 }),
    emptyAlert.waitFor({ state: 'visible', timeout: 10000 })
  ]);

  const hasSection = await sectionHeader.isVisible().catch(() => false);
  const hasEmpty = await emptyAlert.isVisible().catch(() => false);

  return { hasSection, hasEmpty };
}

test.describe('Permanent Bonus Preview Section', () => {
  test('should display section or empty state when project is selected', async ({ page }) => {
    await selectProject(page, 'VOLNA');
    const { hasSection, hasEmpty } = await waitForPermanentSection(page);
    expect(hasSection || hasEmpty).toBe(true);
  });

  test('should display action buttons for bonuses when present', async ({ page }) => {
    await selectProject(page, 'VOLNA');
    const { hasSection } = await waitForPermanentSection(page);
    if (!hasSection) return;

    const permanentCard = page.locator('div.card').filter({
      has: page.locator('h5:has-text("Permanent Bonuses for")')
    });
    const bonusCards = permanentCard.locator('.row.g-3 .card');
    const count = await bonusCards.count();
    if (count === 0) return;

    const firstCard = bonusCards.first();
    await expect(firstCard.locator('a:has-text("View")')).toBeVisible();
  });

  test('should not display permanent bonuses when no project is selected', async ({ page }) => {
    await page.goto('/bonuses');
    await expect(page.locator('h5:has-text("Permanent Bonuses for")')).not.toBeVisible();
    await expect(page.locator('text=No permanent bonuses configured')).not.toBeVisible();
  });

  test('should render on mobile viewport', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await selectProject(page, 'VOLNA');
    const { hasSection, hasEmpty } = await waitForPermanentSection(page);
    expect(hasSection || hasEmpty).toBe(true);
  });
});
