// Test to check all reward form types
const { test, expect } = require('@playwright/test');

test.describe('Check All Reward Form Types', () => {
  test('should check all reward form types for multi-column layout', async ({ page }) => {
    // Set viewport to desktop size
    await page.setViewportSize({ width: 1200, height: 800 });

    // Navigate to bonus creation page
    await page.goto('/bonuses/new?event=deposit');

    // Wait for page to load
    await expect(page.locator('h1')).toContainText('Create New Bonus');

    // Test different reward types
    const rewardTypes = [
      'Add Cash Bonus',
      'Add Freespins', 
      'Add Bonus Buy',
      'Add Comp Points',
      'Add Bonus Code'
    ];

    for (const rewardType of rewardTypes) {
      console.log(`\n=== Testing ${rewardType} ===`);
      
      const rewardButton = page.locator(`button:has-text("${rewardType}")`);
      
      if (await rewardButton.isVisible()) {
        await rewardButton.click();
        await page.waitForTimeout(500);

        // Check if main-params-container exists
        const mainContainer = page.locator('.main-params-container');
        const containerExists = await mainContainer.isVisible();
        console.log(`${rewardType} - main-params-container exists:`, containerExists);

        if (containerExists) {
          const computedStyle = await mainContainer.evaluate(el => {
            const style = window.getComputedStyle(el);
            return {
              display: style.display,
              gridTemplateColumns: style.gridTemplateColumns,
              gap: style.gap
            };
          });
          console.log(`${rewardType} - Grid layout:`, computedStyle);

          // Count reward-param-field elements
          const paramFields = page.locator('.reward-param-field');
          const fieldCount = await paramFields.count();
          console.log(`${rewardType} - Number of reward-param-field elements:`, fieldCount);

          // Take screenshot
          await page.screenshot({
            path: `test-results/${rewardType.toLowerCase().replace(/\s+/g, '-')}-form.png`,
            fullPage: false
          });
        } else {
          console.log(`${rewardType} - No main-params-container found`);
          
          // Check what containers exist
          const containers = await page.locator('[class*="container"]').all();
          console.log(`${rewardType} - Available containers:`, containers.length);
          
          for (const container of containers) {
            const className = await container.getAttribute('class');
            console.log(`  - ${className}`);
          }
        }

        // Remove the reward to test the next one
        const removeButton = page.locator('button').filter({ hasText: /Remove|Delete/i });
        if (await removeButton.isVisible()) {
          await removeButton.click();
          await page.waitForTimeout(300);
        }
      } else {
        console.log(`${rewardType} - Button not visible`);
      }
    }

    console.log('\n🔍 All reward form types checked!');
  });
});
