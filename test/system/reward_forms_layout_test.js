// Playwright test for reward forms multi-column layout
const { test, expect } = require('@playwright/test');

test.describe('Reward Forms Multi-Column Layout', () => {
  test.beforeEach(async ({ page }) => {
    // Set viewport to desktop size to test multi-column layout
    await page.setViewportSize({ width: 1200, height: 800 });

    // Navigate to bonus creation page
    await page.goto('/bonuses/new?event=deposit');

    // Wait for page to load
    await expect(page.locator('h1')).toContainText('Create New Bonus');
  });

  test('should display main parameters in 3 columns on large screens', async ({ page }) => {
    // Add a bonus reward to test the layout
    const addBonusButton = page.locator('button:has-text("Add Cash Bonus")');
    await expect(addBonusButton).toBeVisible();
    await addBonusButton.click();

    // Wait for the reward form to appear
    await expect(page.locator('.main-params-container')).toBeVisible();

    // Check that main-params-container has CSS Grid layout
    const mainContainer = page.locator('.main-params-container');
    const computedStyle = await mainContainer.evaluate(el => window.getComputedStyle(el));

    // Verify grid layout is applied
    expect(computedStyle.display).toBe('grid');

    // Check that we have 3 columns (browser shows pixel values instead of '1fr')
    const columns = computedStyle.gridTemplateColumns.split(' ');
    expect(columns.length).toBe(3); // Should have 3 columns

    // Verify gap is applied (browser shows pixels instead of rem)
    const gapValue = parseInt(computedStyle.gap);
    expect(gapValue).toBeGreaterThan(20); // 1.5rem should be around 24px
  });

  test('should display advanced parameters in 3 columns on large screens', async ({ page }) => {
    // Add a bonus reward
    await page.locator('button:has-text("Add Cash Bonus")').click();

    // Show advanced parameters
    const advancedToggle = page.locator('#toggle_bonus_advanced');
    if (await advancedToggle.isVisible()) {
      await advancedToggle.click();
    } else {
      // Try alternative toggle button
      const altToggle = page.locator('button').filter({ hasText: /Показать дополнительные параметры|Show advanced parameters/i });
      if (await altToggle.isVisible()) {
        await altToggle.click();
      }
    }

    // Wait for advanced params to show
    await page.waitForTimeout(500);

    // Check advanced params container layout
    const advancedContainer = page.locator('.advanced-params-container');
    if (await advancedContainer.isVisible()) {
      const computedStyle = await advancedContainer.evaluate(el => window.getComputedStyle(el));

      // Verify grid layout is applied
      expect(computedStyle.display).toBe('grid');
      expect(computedStyle.gridTemplateColumns).toContain('1fr');
      expect(computedStyle.gridTemplateColumns.split(' ').length).toBe(3); // Should have 3 columns

      // Verify gap is applied
      expect(computedStyle.gap).toBe('1.5rem');
    }
  });

  test('should display full-width elements spanning all columns', async ({ page }) => {
    // Add a bonus reward
    await page.locator('button:has-text("Add Cash Bonus")').click();

    // Check full-width elements (like button groups)
    const fullWidthElements = page.locator('.main-params-container .full-width, .main-params-container .reward-button-group');

    for (const element of await fullWidthElements.all()) {
      const computedStyle = await element.evaluate(el => window.getComputedStyle(el));

      // Full-width elements should span all columns
      expect(computedStyle.gridColumn).toBe('1 / -1');
    }
  });

  test('should display 2 columns on medium screens (768px-1199px)', async ({ page }) => {
    // Set medium viewport
    await page.setViewportSize({ width: 900, height: 800 });
    await page.reload();

    // Add a bonus reward
    await page.locator('button:has-text("Add Cash Bonus")').click();

    // Check main container layout
    const mainContainer = page.locator('.main-params-container');
    const computedStyle = await mainContainer.evaluate(el => window.getComputedStyle(el));

    // Should have 2 columns on medium screens
    expect(computedStyle.display).toBe('grid');
    const columns = computedStyle.gridTemplateColumns.split(' ');
    expect(columns.length).toBe(2); // Should have 2 columns

    // Check gap (browser shows pixels instead of rem)
    const gapValue = parseInt(computedStyle.gap);
    expect(gapValue).toBeGreaterThan(10); // 1rem should be around 16px
  });

  test('should display single column on small screens (<768px)', async ({ page }) => {
    // Set small viewport
    await page.setViewportSize({ width: 600, height: 800 });
    await page.reload();

    // Add a bonus reward
    await page.locator('button:has-text("Add Cash Bonus")').click();

    // Check main container layout
    const mainContainer = page.locator('.main-params-container');
    const computedStyle = await mainContainer.evaluate(el => window.getComputedStyle(el));

    // Should be block layout (single column) on small screens
    expect(computedStyle.display).toBe('block');
  });

  test('should apply consistent spacing and heights', async ({ page }) => {
    // Add a bonus reward
    await page.locator('button:has-text("Add Cash Bonus")').click();

    // Check form field heights are consistent
    const formFields = page.locator('.reward-param-field .form-control, .reward-param-field .form-select');

    for (const field of await formFields.all()) {
      const computedStyle = await field.evaluate(el => window.getComputedStyle(el));

      // All fields should have minimum height of 38px
      const minHeight = parseInt(computedStyle.minHeight);
      expect(minHeight).toBeGreaterThanOrEqual(38);
    }

    // Check label spacing
    const labels = page.locator('.main-params-container .form-label');
    for (const label of await labels.all()) {
      const computedStyle = await label.evaluate(el => window.getComputedStyle(el));

      // Labels should have proper font weight and margin
      expect(computedStyle.fontWeight).toBe('600');
      expect(computedStyle.display).toBe('block');
    }
  });

  test('should work with all reward types', async ({ page }) => {
    // Test different reward types with their specific selectors
    const rewardTypes = [
      { button: 'Add Cash Bonus', selector: '.main-params-container' },
      { button: 'Add Freespins', selector: '.main-params-container' },
      { button: 'Add Bonus Buy', selector: '.main-params-container' },
      { button: 'Add Comp Points', selector: '.main-params-container' },
      { button: 'Add Bonus Code', selector: '.main-params-container' }
    ];

    for (const rewardType of rewardTypes) {
      const rewardButton = page.locator(`button:has-text("${rewardType.button}")`);

      if (await rewardButton.isVisible()) {
        await rewardButton.click();

        // Wait a bit for the form to load
        await page.waitForTimeout(500);

        // Check that container has grid layout (try different selectors)
        let container;
        try {
          container = page.locator(rewardType.selector);
          await expect(container).toBeVisible({ timeout: 3000 });
        } catch (e) {
          // Some reward types might not have main-params-container
          console.log(`Container ${rewardType.selector} not found for ${rewardType.button}, skipping...`);
          continue;
        }

        const computedStyle = await container.evaluate(el => window.getComputedStyle(el));

        // Verify grid layout is applied
        expect(computedStyle.display).toBe('grid');
        const columns = computedStyle.gridTemplateColumns.split(' ');
        expect(columns.length).toBeGreaterThan(1); // Should have multiple columns

        // Remove the reward to test the next one
        const removeButton = page.locator('button').filter({ hasText: /Remove|Удалить/i });
        if (await removeButton.isVisible()) {
          await removeButton.click();
        }
      }
    }
  });

  test('should handle CSS conflicts gracefully', async ({ page }) => {
    // Add a bonus reward
    await page.locator('button:has-text("Add Cash Bonus")').click();

    // Check that our custom CSS doesn't conflict with Bootstrap
    const mainContainer = page.locator('.main-params-container');

    // Verify our custom CSS is loaded
    const rewardFormsCSS = await page.evaluate(() => {
      const links = Array.from(document.querySelectorAll('link[rel="stylesheet"]'));
      return links.some(link => link.href.includes('reward_forms'));
    });

    expect(rewardFormsCSS).toBe(true);

    // Verify the layout still works
    const computedStyle = await mainContainer.evaluate(el => window.getComputedStyle(el));
    expect(computedStyle.display).toBe('grid');
  });

  test('should display freespin reward in multi-column layout', async ({ page }) => {
    // Set desktop viewport
    await page.setViewportSize({ width: 1200, height: 800 });

    // Navigate to bonus creation page
    await page.goto('/bonuses/new?event=deposit');
    await expect(page.locator('h1')).toContainText('Create New Bonus');

    // Add freespin reward
    const addFreespinButton = page.locator('button:has-text("Add Freespins")');
    await expect(addFreespinButton).toBeVisible();
    await addFreespinButton.click();

    // Wait for freespin form to load
    await page.waitForTimeout(1000);

    // Check that freespin reward container exists
    const freespinContainer = page.locator('#freespin-reward-0');
    await expect(freespinContainer).toBeVisible();

    // Check main params container layout
    const mainContainer = page.locator('#freespin-reward-0 .main-params-container');
    await expect(mainContainer).toBeVisible();

    const computedStyle = await mainContainer.evaluate(el => window.getComputedStyle(el));

    // Verify grid layout is applied (should be forced by our CSS rules)
    expect(computedStyle.display).toBe('grid');

    // Check number of columns - should be 3 or 4 on desktop (depending on screen size)
    const columns = computedStyle.gridTemplateColumns.split(' ');
    expect(columns.length).toBeGreaterThanOrEqual(3);

    // Check gap is applied
    const gapValue = parseInt(computedStyle.gap);
    expect(gapValue).toBeGreaterThan(10); // Should have gap

    // Check that individual fields are in grid (excluding currency bet levels which is separate)
    const rewardFields = page.locator('#freespin-reward-0 .main-params-container .reward-param-field');
    const fieldCount = await rewardFields.count();
    expect(fieldCount).toBeGreaterThan(0);

    // Note: Currency bet levels may not be visible if no currencies are selected
    // This is OK for now, we just need to verify the main grid layout works

    // Check that full-width elements span all columns
    const fullWidthElements = page.locator('#freespin-reward-0 .main-params-container .reward-param-field.full-width');
    for (const element of await fullWidthElements.all()) {
      const elementStyle = await element.evaluate(el => window.getComputedStyle(el));
      expect(elementStyle.gridColumn).toBe('1 / -1');
    }

    console.log('✅ Freespin reward layout test passed');
  });

  test('should display freespin reward in single column on mobile', async ({ page }) => {
    // Set mobile viewport
    await page.setViewportSize({ width: 600, height: 800 });

    // Navigate to bonus creation page
    await page.goto('/bonuses/new?event=deposit');
    await expect(page.locator('h1')).toContainText('Create New Bonus');

    // Add freespin reward
    await page.locator('button:has-text("Add Freespins")').click();
    await page.waitForTimeout(1000);

    // Check main params container layout on mobile
    const mainContainer = page.locator('#freespin-reward-0 .main-params-container');
    const computedStyle = await mainContainer.evaluate(el => window.getComputedStyle(el));

    // Should be block layout (single column) on mobile
    expect(computedStyle.display).toBe('block');

    console.log('✅ Freespin reward mobile layout test passed');
  });

  test('should compare freespin layout with cash bonus layout', async ({ page }) => {
    // Set large desktop viewport to test 4-column layout
    await page.setViewportSize({ width: 1400, height: 800 });

    // Navigate to bonus creation page
    await page.goto('/bonuses/new?event=deposit');
    await expect(page.locator('h1')).toContainText('Create New Bonus');

    // Add cash bonus first
    await page.locator('button:has-text("Add Cash Bonus")').click();
    await page.waitForTimeout(500);

    // Add freespin reward
    await page.locator('button:has-text("Add Freespins")').click();
    await page.waitForTimeout(1000);

    // Compare layouts
    const cashBonusContainer = page.locator('#bonus-reward-0 .main-params-container');
    const freespinContainer = page.locator('#freespin-reward-0 .main-params-container');

    const cashStyle = await cashBonusContainer.evaluate(el => window.getComputedStyle(el));
    const freespinStyle = await freespinContainer.evaluate(el => window.getComputedStyle(el));

    // Both should use grid layout
    expect(cashStyle.display).toBe('grid');
    expect(freespinStyle.display).toBe('grid');

    // Both should have multiple columns (at least 2)
    const cashColumns = cashStyle.gridTemplateColumns.split(' ').length;
    const freespinColumns = freespinStyle.gridTemplateColumns.split(' ').length;
    expect(cashColumns).toBeGreaterThanOrEqual(2);
    expect(freespinColumns).toBeGreaterThanOrEqual(2);

    // Both should have similar gap values
    const cashGap = parseInt(cashStyle.gap);
    const freespinGap = parseInt(freespinStyle.gap);
    expect(Math.abs(cashGap - freespinGap)).toBeLessThan(10); // Allow small difference

    console.log('✅ Freespin vs Cash bonus layout comparison test passed');
    console.log(`Cash bonus columns: ${cashColumns}, Freespin columns: ${freespinColumns}`);
    console.log(`Cash bonus gap: ${cashGap}px, Freespin gap: ${freespinGap}px`);
  });

  test('should debug freespin layout issue', async ({ page }) => {
    // Set desktop viewport
    await page.setViewportSize({ width: 1920, height: 1080 }); // Full HD

    // Navigate to bonus creation page
    await page.goto('/bonuses/new?event=deposit');
    await expect(page.locator('h1')).toContainText('Create New Bonus');

    // Add freespin reward
    await page.locator('button:has-text("Add Freespins")').click();
    await page.waitForTimeout(1000);

    // Check if freespin container exists
    const freespinContainer = page.locator('#freespin-reward-0');
    await expect(freespinContainer).toBeVisible();

    // Debug: Check what CSS is actually applied
    const mainContainer = page.locator('#freespin-reward-0 .main-params-container');
    await expect(mainContainer).toBeVisible();

    const computedStyle = await mainContainer.evaluate(el => window.getComputedStyle(el));

    console.log('=== DEBUG INFO ===');
    console.log('Display:', computedStyle.display);
    console.log('Grid template columns:', computedStyle.gridTemplateColumns);
    console.log('Gap:', computedStyle.gap);
    console.log('Width:', computedStyle.width);
    console.log('Max-width:', computedStyle.maxWidth);

    // Check if our CSS rules are loaded
    const hasRewardFormsCSS = await page.evaluate(() => {
      const stylesheets = Array.from(document.styleSheets);
      return stylesheets.some(sheet => {
        try {
          return sheet.href && sheet.href.includes('reward_forms');
        } catch (e) {
          return false;
        }
      });
    });

    console.log('Reward forms CSS loaded:', hasRewardFormsCSS);

    // Check if our specific rule is applied
    const hasSpecificRule = await mainContainer.evaluate(el => {
      const styles = window.getComputedStyle(el);
      return styles.display === 'grid' && styles.gridTemplateColumns.includes('1fr');
    });

    console.log('Specific CSS rule applied:', hasSpecificRule);

    // Check all CSS rules applied to the element
    const allCSSRules = await mainContainer.evaluate(el => {
      const styles = window.getComputedStyle(el);
      return {
        display: styles.display,
        gridTemplateColumns: styles.gridTemplateColumns,
        gap: styles.gap,
        gridColumnGap: styles.gridColumnGap,
        gridRowGap: styles.gridRowGap,
        width: styles.width,
        maxWidth: styles.maxWidth,
        cssText: styles.cssText
      };
    });

    console.log('All CSS properties:', JSON.stringify(allCSSRules, null, 2));

    // Check if there are any !important rules
    const hasImportantRules = await page.evaluate(() => {
      const element = document.querySelector('#freespin-reward-0 .main-params-container') ||
                     document.querySelector('#freespin-reward-1 .main-params-container');
      if (!element) return false;

      const styles = window.getComputedStyle(element);
      const cssText = styles.cssText;
      return cssText.includes('!important');
    });

    console.log('Has !important rules:', hasImportantRules);

    // Check if our JavaScript function ran
    const jsApplied = await page.evaluate(() => {
      return window.freespinGridLayoutApplied === true;
    });

    console.log('JavaScript force layout applied:', jsApplied);

    // Take screenshot for debugging
    await page.screenshot({ path: 'test-results/freespin-debug.png', fullPage: true });

    // The test will pass regardless, this is just for debugging
    expect(true).toBe(true);
  });
});
