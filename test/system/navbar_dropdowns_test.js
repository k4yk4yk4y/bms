const { test, expect } = require('@playwright/test');

const pages = [
  { name: 'Bonuses', path: '/bonuses', navText: 'Bonuses' },
  { name: 'Heatmap', path: '/heatmap', navText: 'Heatmap' },
  { name: 'Marketing', path: '/marketing', navText: 'Marketing' },
  { name: 'Retention', path: '/retention', navText: 'Retention' },
];

async function navigateToPage(page, pageInfo, useNav) {
  if (useNav) {
    const navLink = page.locator('nav .nav-link', { hasText: pageInfo.navText });
    if (await navLink.count()) {
      const urlPattern = new RegExp(pageInfo.path.replace(/\//g, '\\/'));
      await Promise.all([
        page.waitForURL(urlPattern),
        navLink.first().click(),
      ]);
      return;
    }
  }

  await page.goto(pageInfo.path);
}

async function assertProjectsDropdown(page) {
  const projectsToggle = page.locator('#projectsDropdown');
  const projectsMenu = page.locator('[aria-labelledby="projectsDropdown"]');

  await expect(projectsToggle).toBeVisible();
  await projectsToggle.click();
  await expect(projectsMenu).toHaveClass(/show/);
  await expect(projectsMenu).toBeVisible();
  await expect(projectsMenu.locator('a', { hasText: 'All Projects' })).toBeVisible();
}

async function assertUserDropdown(page) {
  const userToggle = page.locator('#userDropdown');
  const userMenu = page.locator('[aria-labelledby="userDropdown"]');

  await expect(userToggle).toBeVisible();
  await userToggle.click();
  await expect(userMenu).toHaveClass(/show/);
  await expect(userMenu).toBeVisible();
  await expect(userMenu.locator('a[href^="/users/"]')).toBeVisible();
  await expect(userMenu.locator('form[action*="sign_out"]')).toBeVisible();
}

test.describe('Navbar dropdowns', () => {
  test('Projects and profile dropdowns open after navigation', async ({ page }) => {
    await page.goto(pages[0].path);
    await expect(page.locator('nav')).toBeVisible();

    for (let index = 0; index < pages.length; index += 1) {
      const pageInfo = pages[index];
      const useNav = index > 0;
      await navigateToPage(page, pageInfo, useNav);
      await expect(page.locator('nav')).toBeVisible();

      await assertProjectsDropdown(page);
      await assertUserDropdown(page);
    }
  });
});
