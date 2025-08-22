// Debug test to check why multi-column layout is not working
const { test, expect } = require('@playwright/test');

test.describe('Debug Layout Issues', () => {
  test('should debug why multi-column layout is not working', async ({ page }) => {
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

    // Check if CSS is loaded
    const cssLoaded = await page.evaluate(() => {
      const links = Array.from(document.querySelectorAll('link[rel="stylesheet"]'));
      return links.some(link => link.href.includes('reward_forms'));
    });
    console.log('CSS loaded:', cssLoaded);

    // Check computed styles
    const mainContainer = page.locator('.main-params-container');
    const computedStyle = await mainContainer.evaluate(el => {
      const style = window.getComputedStyle(el);
      return {
        display: style.display,
        gridTemplateColumns: style.gridTemplateColumns,
        gap: style.gap,
        width: style.width,
        height: style.height
      };
    });
    console.log('Main container computed styles:', computedStyle);

    // Check if reward-param-field elements exist
    const paramFields = page.locator('.reward-param-field');
    const fieldCount = await paramFields.count();
    console.log('Number of reward-param-field elements:', fieldCount);

    // Check individual field styles
    if (fieldCount > 0) {
      const firstField = paramFields.first();
      const fieldStyle = await firstField.evaluate(el => {
        const style = window.getComputedStyle(el);
        return {
          display: style.display,
          width: style.width,
          height: style.height,
          margin: style.margin
        };
      });
      console.log('First field computed styles:', fieldStyle);
    }

    // Check if Bootstrap is interfering
    const bootstrapLoaded = await page.evaluate(() => {
      const links = Array.from(document.querySelectorAll('link[rel="stylesheet"]'));
      return links.some(link => link.href.includes('bootstrap'));
    });
    console.log('Bootstrap loaded:', bootstrapLoaded);

    // Check for any conflicting CSS
    const allStyles = await page.evaluate(() => {
      const styleSheets = Array.from(document.styleSheets);
      const cssRules = [];
      
      styleSheets.forEach(sheet => {
        try {
          const rules = Array.from(sheet.cssRules || sheet.rules || []);
          rules.forEach(rule => {
            if (rule.selectorText && rule.selectorText.includes('main-params-container')) {
              cssRules.push({
                selector: rule.selectorText,
                cssText: rule.cssText,
                href: sheet.href || 'inline'
              });
            }
          });
        } catch (e) {
          // Cross-origin stylesheets can't be accessed
        }
      });
      
      return cssRules;
    });
    console.log('All CSS rules for main-params-container:', allStyles);

    // Take a screenshot for visual inspection
    await page.screenshot({
      path: 'test-results/debug-layout.png',
      fullPage: true
    });

    // Check if grid is actually applied
    const isGridApplied = computedStyle.display === 'grid';
    console.log('Grid is applied:', isGridApplied);

    if (!isGridApplied) {
      console.log('❌ Grid layout is NOT applied!');
      console.log('Expected: display: grid');
      console.log('Actual:', computedStyle.display);
    } else {
      console.log('✅ Grid layout is applied');
      console.log('Columns:', computedStyle.gridTemplateColumns);
      console.log('Gap:', computedStyle.gap);
    }

    // Force apply grid layout to see if it works
    await page.evaluate(() => {
      const container = document.querySelector('.main-params-container');
      if (container) {
        container.style.display = 'grid';
        container.style.gridTemplateColumns = 'repeat(3, 1fr)';
        container.style.gap = '1rem';
      }
    });

    // Wait a bit and take another screenshot
    await page.waitForTimeout(1000);
    await page.screenshot({
      path: 'test-results/debug-layout-forced.png',
      fullPage: true
    });

    console.log('🔍 Debug completed. Check screenshots for visual comparison.');
  });
});
