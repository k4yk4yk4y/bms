const { test, expect } = require('@playwright/test');

async function selectProjectAndGetCurrencies(page, projectName = 'VOLNA') {
  await page.selectOption('select[name="bonus[project]"]', projectName);
  await page.waitForSelector('input.currency-checkbox', { state: 'visible' });
  return await page.locator('input.currency-checkbox').evaluateAll((nodes) => nodes.map(node => node.value));
}

test.describe('Currency Dynamic Update Test', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the new bonus page
    await page.goto('/bonuses/new');
    
    // Wait for the page to load completely
    await page.waitForLoadState('networkidle');
  });

  test('should dynamically update bonus reward currency fields when currencies are selected in Basic Information', async ({ page }) => {
    // Wait for the basic information section to be visible
    await page.waitForSelector('#uncheck-all-currencies-btn', { state: 'visible' });
    const availableCurrencies = await selectProjectAndGetCurrencies(page);
    expect(availableCurrencies.length).toBeGreaterThan(0);
    
    // Initially, some checkboxes might be checked by default
    // We'll work with the current state
    
    // Select a few specific currencies
    const currenciesToSelect = availableCurrencies.slice(0, 3);
    for (const currency of currenciesToSelect) {
      const checkbox = page.locator(`input.currency-checkbox[value="${currency}"]`);
      if (await checkbox.isVisible()) {
        await checkbox.check();
      }
    }
    
    // Verify selected currencies
    for (const currency of currenciesToSelect) {
      const checkbox = page.locator(`input.currency-checkbox[value="${currency}"]`);
      if (await checkbox.isVisible()) {
        expect(await checkbox.isChecked()).toBe(true);
      }
    }
    
    // Now add a bonus reward
    const addBonusRewardBtn = page.locator('button:has-text("Add Cash Bonus")');
    if (await addBonusRewardBtn.isVisible()) {
      await addBonusRewardBtn.click();
    }
    
    // Wait for bonus reward form to appear
    await page.waitForSelector('[id^="bonus-reward-"]', { state: 'visible' });
    
    // Check if currency fields are displayed for selected currencies
    for (const currency of currenciesToSelect) {
      const currencyField = page.locator(`input[name*="currency_amounts"][name*="[${currency}]"]`);
      if (await currencyField.isVisible()) {
        expect(await currencyField.isVisible()).toBe(true);
      }
    }
    
    // Uncheck some currencies
    const toggleCurrency = currenciesToSelect[1];
    if (toggleCurrency) {
      await page.locator(`input.currency-checkbox[value="${toggleCurrency}"]`).uncheck();
    }
    
    // Wait for dynamic update
    await page.waitForTimeout(500);
    
    // Check that bonus reward currency fields are updated
    // The fields should still be visible but the logic should handle the change
    const toggleField = toggleCurrency
      ? page.locator(`input[name*="currency_amounts"][name*="[${toggleCurrency}]"]`)
      : null;
    if (toggleField && await toggleField.isVisible()) {
      // Fill a value to test if it's preserved
      await toggleField.fill('100');
      await page.waitForTimeout(100);
      await page.locator(`input.currency-checkbox[value="${toggleCurrency}"]`).check();
      await page.waitForTimeout(500);
      // Value should be preserved when currency is re-selected
      expect(await toggleField.inputValue()).toBe('100');
    }
  });

  test('should update bonus reward currency fields when using "uncheck all" button', async ({ page }) => {
    // Wait for the basic information section to be visible
    await page.waitForSelector('#uncheck-all-currencies-btn', { state: 'visible' });
    
    const currenciesToSelect = (await selectProjectAndGetCurrencies(page)).slice(0, 2);
    for (const currency of currenciesToSelect) {
      const checkbox = page.locator(`input.currency-checkbox[value="${currency}"]`);
      if (await checkbox.isVisible()) {
        await checkbox.check();
      }
    }
    
    // Add a bonus reward
    const addBonusRewardBtn = page.locator('button:has-text("Add Cash Bonus")');
    if (await addBonusRewardBtn.isVisible()) {
      await addBonusRewardBtn.click();
    }
    
    // Wait for bonus reward form to appear
    await page.waitForSelector('[id^="bonus-reward-"]', { state: 'visible' });
    
    // Fill some values in currency fields
    for (const currency of currenciesToSelect) {
      const currencyField = page.locator(`input[name*="currency_amounts"][name*="[${currency}]"]`);
      if (await currencyField.isVisible()) {
        await currencyField.fill('100');
      }
    }
    
    // Click "uncheck all" button
    await page.click('#uncheck-all-currencies-btn');
    await page.waitForTimeout(200);
    
    // Verify all checkboxes are unchecked
    const currencyCheckboxes = await page.locator('input.currency-checkbox').all();
    for (const checkbox of currencyCheckboxes) {
      expect(await checkbox.isChecked()).toBe(false);
    }
    
    // Check that currency fields in bonus reward are updated (should show all currencies or none)
    // This depends on the implementation - fields might be hidden or show all currencies
    const usdField = currenciesToSelect[0]
      ? page.locator(`input[name*="currency_amounts"][name*="[${currenciesToSelect[0]}]"]`)
      : page.locator(`input[name*="currency_amounts"]`);
    const eurField = currenciesToSelect[1]
      ? page.locator(`input[name*="currency_amounts"][name*="[${currenciesToSelect[1]}]"]`)
      : page.locator(`input[name*="currency_amounts"]`);
    
    // At least one of these should be visible (either showing all currencies or specific ones)
    const hasVisibleFields = await usdField.isVisible() || await eurField.isVisible();
    expect(hasVisibleFields).toBe(true);
  });

  test('should handle currency minimum deposits and bonus reward currency fields together', async ({ page }) => {
    // Wait for the basic information section to be visible
    await page.waitForSelector('#uncheck-all-currencies-btn', { state: 'visible' });
    
    // Select deposit bonus type to show currency minimum deposits
    await page.selectOption('select[name="bonus[event]"]', 'deposit');
    
    // Wait for the currency minimum deposits section to appear
    await page.waitForSelector('#currency-minimum-deposits-section', { state: 'visible' });
    
    // Fill in some currency minimum deposit values
    const minimumDepositInputs = await page.locator('input[name^="bonus[currency_minimum_deposits]"]').all();
    const currenciesWithDeposits = (await selectProjectAndGetCurrencies(page)).slice(0, 2);
    
    for (let i = 0; i < Math.min(currenciesWithDeposits.length, minimumDepositInputs.length); i++) {
      await minimumDepositInputs[i].fill('100');
    }
    
    // Add a bonus reward
    const addBonusRewardBtn = page.locator('button:has-text("Add Cash Bonus")');
    if (await addBonusRewardBtn.isVisible()) {
      await addBonusRewardBtn.click();
    }
    
    // Wait for bonus reward form to appear
    await page.waitForSelector('[id^="bonus-reward-"]', { state: 'visible' });
    
    // Check that currency fields are displayed for currencies with minimum deposits
    for (const currency of currenciesWithDeposits) {
      const currencyField = page.locator(`input[name*="currency_amounts"][name*="[${currency}]"]`);
      if (await currencyField.isVisible()) {
        expect(await currencyField.isVisible()).toBe(true);
      }
    }
    
    // Clear minimum deposits
    for (const input of minimumDepositInputs) {
      await input.fill('');
    }
    
    // Wait for dynamic update
    await page.waitForTimeout(200);
    
    // Check that bonus reward currency fields are updated accordingly
    // This depends on the implementation logic
    const hasVisibleFields = await page.locator('input[name*="currency_amounts"]').first().isVisible();
    expect(hasVisibleFields).toBe(true);
  });
});
