// Simple visual test to check reward forms layout
const { test, expect } = require('@playwright/test');

test.describe('Visual Reward Forms Layout Check', () => {
  test('should visually verify multi-column layout', async ({ page }) => {
    // Set viewport to desktop size
    await page.setViewportSize({ width: 1200, height: 800 });

    // Navigate to bonus creation page
    await page.goto('/bonuses/new?event=deposit');

    // Wait for page to load
    await expect(page.locator('h1')).toContainText('Create New Bonus');

    // Add a bonus reward
    const addBonusButton = page.locator('button:has-text("Add Cash Bonus")');
    await expect(addBonusButton).toBeVisible();
    await addBonusButton.click();

    // Wait for the reward form to appear
    await expect(page.locator('.main-params-container')).toBeVisible();

    // Take a screenshot to visually verify the layout
    await page.screenshot({
      path: 'test-results/reward-form-layout.png',
      fullPage: true
    });

    // Check that we have multiple reward param fields
    const paramFields = page.locator('.reward-param-field');
    const fieldCount = await paramFields.count();
    expect(fieldCount).toBeGreaterThan(3); // Should have multiple fields

    // Check that CSS Grid is applied
    const mainContainer = page.locator('.main-params-container');
    const computedStyle = await mainContainer.evaluate(el => window.getComputedStyle(el));
    expect(computedStyle.display).toBe('grid');

    // Log the actual grid layout for verification
    console.log('Grid template columns:', computedStyle.gridTemplateColumns);
    console.log('Number of columns:', computedStyle.gridTemplateColumns.split(' ').length);
    console.log('Gap:', computedStyle.gap);

    // Verify we have at least 2 columns
    const columns = computedStyle.gridTemplateColumns.split(' ');
    expect(columns.length).toBeGreaterThanOrEqual(2);

    // Test on different screen sizes
    console.log('\n=== Testing different screen sizes ===');

    // Medium screen
    await page.setViewportSize({ width: 900, height: 800 });
    await page.reload();
    await page.locator('button:has-text("Add Cash Bonus")').click();
    await page.waitForTimeout(500);

    const mediumStyle = await mainContainer.evaluate(el => window.getComputedStyle(el));
    const mediumColumns = mediumStyle.gridTemplateColumns.split(' ');
    console.log('Medium screen columns:', mediumColumns.length);

    // Small screen
    await page.setViewportSize({ width: 600, height: 800 });
    await page.reload();
    await page.locator('button:has-text("Add Cash Bonus")').click();
    await page.waitForTimeout(500);

    const smallStyle = await mainContainer.evaluate(el => window.getComputedStyle(el));
    console.log('Small screen display:', smallStyle.display);

    // Take final screenshot
    await page.screenshot({
      path: 'test-results/reward-form-responsive.png',
      fullPage: true
    });

    console.log('✅ Multi-column layout test completed successfully!');
  });
});
