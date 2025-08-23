const { test, expect } = require('@playwright/test');

test.describe('Uncheck All Currencies Button Test', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the new bonus page
    await page.goto('/bonuses/new');
    
    // Wait for the page to load completely
    await page.waitForLoadState('networkidle');
  });

  test('should uncheck all currency checkboxes when clicking "Снять все" button', async ({ page }) => {
    // Wait for the basic information section to be visible
    await page.waitForSelector('#uncheck-all-currencies-btn', { state: 'visible' });
    
    // Get all currency checkboxes before clicking the button
    const currencyCheckboxes = await page.locator('input.currency-checkbox').all();
    
    // Check that we have some checkboxes
    expect(currencyCheckboxes.length).toBeGreaterThan(0);
    
    // Check some checkboxes manually to ensure they are checked
    for (let i = 0; i < Math.min(3, currencyCheckboxes.length); i++) {
      await currencyCheckboxes[i].check();
      expect(await currencyCheckboxes[i].isChecked()).toBe(true);
    }
    
    // Click the "Снять все" button
    await page.click('#uncheck-all-currencies-btn');
    
    // Wait a bit for the JavaScript to execute
    await page.waitForTimeout(100);
    
    // Verify that all currency checkboxes are now unchecked
    for (const checkbox of currencyCheckboxes) {
      expect(await checkbox.isChecked()).toBe(false);
    }
    
    // Check that there are no console errors
    const consoleErrors = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        consoleErrors.push(msg.text());
      }
    });
    
    // Click the button again to trigger any potential errors
    await page.click('#uncheck-all-currencies-btn');
    await page.waitForTimeout(100);
    
    // Verify no console errors related to uncheckAllCurrencies
    const uncheckErrors = consoleErrors.filter(error => 
      error.includes('uncheckAllCurrencies') || 
      error.includes('is not defined')
    );
    expect(uncheckErrors).toHaveLength(0);
  });

  test('should handle currency minimum deposits when unchecking all currencies', async ({ page }) => {
    // Wait for the page to load
    await page.waitForSelector('#uncheck-all-currencies-btn', { state: 'visible' });
    
    // Select deposit bonus type to show currency minimum deposits
    await page.selectOption('select[name="bonus[event]"]', 'deposit');
    
    // Wait for the currency minimum deposits section to appear
    await page.waitForSelector('#currency-minimum-deposits-section', { state: 'visible' });
    
    // Fill in some currency minimum deposit values
    const minimumDepositInputs = await page.locator('input[name^="bonus[currency_minimum_deposits]"]').all();
    for (let i = 0; i < Math.min(2, minimumDepositInputs.length); i++) {
      await minimumDepositInputs[i].fill('100');
    }
    
    // Verify some values are filled
    for (let i = 0; i < Math.min(2, minimumDepositInputs.length); i++) {
      expect(await minimumDepositInputs[i].inputValue()).toBe('100');
    }
    
    // Click the "Снять все" button
    await page.click('#uncheck-all-currencies-btn');
    await page.waitForTimeout(100);
    
    // Verify that currency minimum deposit fields are cleared
    for (const input of minimumDepositInputs) {
      expect(await input.inputValue()).toBe('');
    }
  });

  test('should work correctly with different bonus types', async ({ page }) => {
    // Wait for the page to load
    await page.waitForSelector('#uncheck-all-currencies-btn', { state: 'visible' });
    
    // Test with different bonus types
    const bonusTypes = ['deposit', 'input_coupon', 'manual'];
    
    for (const bonusType of bonusTypes) {
      // Select bonus type
      await page.selectOption('select[name="bonus[event]"]', bonusType);
      await page.waitForTimeout(200);
      
      // Check some currency checkboxes
      const currencyCheckboxes = await page.locator('input.currency-checkbox').all();
      for (let i = 0; i < Math.min(2, currencyCheckboxes.length); i++) {
        await currencyCheckboxes[i].check();
      }
      
      // Click "Снять все" button
      await page.click('#uncheck-all-currencies-btn');
      await page.waitForTimeout(100);
      
      // Verify all checkboxes are unchecked
      for (const checkbox of currencyCheckboxes) {
        expect(await checkbox.isChecked()).toBe(false);
      }
    }
  });
});
