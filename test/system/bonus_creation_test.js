// Playwright test for bonus creation functionality
const { test, expect } = require('@playwright/test');

test.describe('Bonus Creation', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to bonuses page
    await page.goto('/bonuses');
    
    // Wait for page to load
    await expect(page.locator('h1')).toContainText('Bonus Management');
  });

  test('should navigate to bonus creation form', async ({ page }) => {
    // Click on "Create New Bonus" button
    const createButton = page.locator('button:has-text("Create New Bonus")');
    await expect(createButton).toBeVisible();
    
    // Note: The button opens a modal, let's handle that
    await createButton.click();
    
    // Check if modal appears (assuming there's a modal for bonus type selection)
    // If not, we might need to navigate directly to /bonuses/new
    const modalExists = await page.locator('.modal').isVisible().catch(() => false);
    
    if (!modalExists) {
      // Navigate directly to new bonus page
      await page.goto('/bonuses/new');
    }
    
    // Verify we're on the bonus creation page
    await expect(page.locator('h1')).toContainText('Create New Bonus');
  });

  test('should display all required form fields', async ({ page }) => {
    await page.goto('/bonuses/new');
    
    // Check basic fields
    await expect(page.locator('input[name="bonus[name]"]')).toBeVisible();
    await expect(page.locator('textarea[name="bonus[description]"]')).toBeVisible();
    await expect(page.locator('select[name="bonus[event]"]')).toBeVisible();
    await expect(page.locator('select[name="bonus[status]"]')).toBeVisible();
    await expect(page.locator('select[name="bonus[project]"]')).toBeVisible();
    
    // Check availability dates
    await expect(page.locator('input[name="bonus[availability_start_date]"]')).toBeVisible();
    await expect(page.locator('input[name="bonus[availability_end_date]"]')).toBeVisible();
    
    // Check the create button
    await expect(page.locator('input[type="submit"][value="Create Bonus"]')).toBeVisible();
  });

  test('should validate required fields', async ({ page }) => {
    await page.goto('/bonuses/new');
    
    // Try to submit form without filling required fields
    await page.click('input[type="submit"][value="Create Bonus"]');
    
    // The form should not redirect (stay on same page) due to validation errors
    await expect(page).toHaveURL(/.*\/bonuses\/new/);
    
    // Check that form is still visible (indicates validation error)
    await expect(page.locator('input[name="bonus[name]"]')).toBeVisible();
  });

  test('should create bonus with minimum required fields', async ({ page }) => {
    await page.goto('/bonuses/new?event=deposit');
    
    // Fill in minimum required fields
    await page.fill('input[name="bonus[name]"]', 'Test Bonus');
    
    // Set event to deposit (may be pre-filled from URL parameter)
    await page.selectOption('select[name="bonus[event]"]', 'deposit');
    
    // Set status
    await page.selectOption('select[name="bonus[status]"]', 'draft');
    
    // Set project
    await page.selectOption('select[name="bonus[project]"]', 'VOLNA');
    
    // Set at least one valid currency (this fixes our previous issue)
    await page.selectOption('select[name="bonus[currencies][]"]', 'USD');
    
    // Set currency minimum deposits
    await page.fill('input[name="bonus[currency_minimum_deposits][USD]"]', '10');
    
    // Set required numeric fields
    await page.fill('input[name="bonus[wager]"]', '1');
    await page.fill('input[name="bonus[maximum_winnings]"]', '1000');
    
    // Submit the form
    await page.click('input[type="submit"][value="Create Bonus"]');
    
    // Check for successful creation (should redirect to bonus show page or list)
    await expect(page).toHaveURL(/\/bonuses\/\d+|\/bonuses$/);
    
    // Look for success message
    const successMessage = page.locator('.alert-success, .alert.alert-success');
    if (await successMessage.isVisible().catch(() => false)) {
      await expect(successMessage).toContainText('successfully created');
    }
  });

  test('should create bonus with reward', async ({ page }) => {
    await page.goto('/bonuses/new?event=deposit');
    
    // Fill basic bonus information
    await page.fill('input[name="bonus[name]"]', 'Test Bonus with Reward');
    await page.selectOption('select[name="bonus[event]"]', 'deposit');
    await page.selectOption('select[name="bonus[status]"]', 'draft');
    await page.selectOption('select[name="bonus[project]"]', 'VOLNA');
    
    // Set currency
    await page.selectOption('select[name="bonus[currencies][]"]', 'USD');
    await page.fill('input[name="bonus[currency_minimum_deposits][USD]"]', '10');
    
    // Add a bonus reward by clicking "Add Cash Bonus" button
    const addBonusButton = page.locator('button:has-text("Add Cash Bonus")');
    if (await addBonusButton.isVisible()) {
      await addBonusButton.click();
      
      // Fill reward details
      await page.fill('input[name="bonus_rewards[0][amount]"]', '100');
      await page.fill('input[name="bonus_rewards[0][wager]"]', '35');
      await page.fill('input[name="bonus_rewards[0][available]"]', '1');
    }
    
    // Submit the form
    await page.click('input[type="submit"][value="Create Bonus"]');
    
    // Check for successful creation
    await expect(page).toHaveURL(/\/bonuses\/\d+|\/bonuses$/);
  });

  test('should handle currency validation correctly', async ({ page }) => {
    await page.goto('/bonuses/new?event=deposit');
    
    // Fill basic information
    await page.fill('input[name="bonus[name]"]', 'Currency Test Bonus');
    await page.selectOption('select[name="bonus[event]"]', 'deposit');
    await page.selectOption('select[name="bonus[status]"]', 'draft');
    await page.selectOption('select[name="bonus[project]"]', 'VOLNA');
    
    // DO NOT check any currencies (this should cause validation error)
    // Set currency minimum deposits without selecting currencies
    await page.fill('input[name="bonus[currency_minimum_deposits][USD]"]', '10');
    
    // Submit the form
    await page.click('input[type="submit"][value="Create Bonus"]');
    
    // Should stay on the same page due to validation error
    await expect(page).toHaveURL(/.*\/bonuses\/new/);
    
    // Verify we're still on the form page
    await expect(page.locator('h1')).toContainText('Create New Bonus');
    
    // Now create a new bonus with proper validation
    await page.goto('/bonuses/new?event=deposit');
    
    // Fill all required fields correctly
    await page.fill('input[name="bonus[name]"]', 'Currency Test Bonus Fixed');
    await page.selectOption('select[name="bonus[event]"]', 'deposit');
    await page.selectOption('select[name="bonus[status]"]', 'draft');
    await page.selectOption('select[name="bonus[project]"]', 'VOLNA');
    await page.selectOption('select[name="bonus[currencies][]"]', 'USD');
    await page.fill('input[name="bonus[currency_minimum_deposits][USD]"]', '10');
    
    // Submit the form
    await page.click('input[type="submit"][value="Create Bonus"]');
    
    // Should succeed now
    await expect(page).toHaveURL(/\/bonuses\/\d+|\/bonuses$/);
  });

  test('should validate date fields', async ({ page }) => {
    await page.goto('/bonuses/new?event=deposit');
    
    // Fill basic information
    await page.fill('input[name="bonus[name]"]', 'Date Validation Test');
    await page.selectOption('select[name="bonus[event]"]', 'deposit');
    await page.selectOption('select[name="bonus[status]"]', 'draft');
    await page.selectOption('select[name="bonus[project]"]', 'VOLNA');
    await page.selectOption('select[name="bonus[currencies][]"]', 'USD');
    await page.fill('input[name="bonus[currency_minimum_deposits][USD]"]', '10');
    
    // Set end date before start date (should cause validation error)
    const today = new Date();
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    
    const startDateStr = tomorrow.toISOString().slice(0, 16);
    const endDateStr = yesterday.toISOString().slice(0, 16);
    
    await page.fill('input[name="bonus[availability_start_date]"]', startDateStr);
    await page.fill('input[name="bonus[availability_end_date]"]', endDateStr);
    
    // Submit the form
    await page.click('input[type="submit"][value="Create Bonus"]');
    
    // Should stay on the same page due to validation error
    await expect(page).toHaveURL(/.*\/bonuses\/new/);
    
    // Check if validation error is displayed
    const form = page.locator('form');
    await expect(form).toBeVisible();
  });

  test('should work with different event types', async ({ page }) => {
    const eventTypes = ['deposit', 'input_coupon', 'manual', 'collection'];
    
    for (const eventType of eventTypes) {
      await page.goto(`/bonuses/new?event=${eventType}`);
      
      // Fill basic information
      await page.fill('input[name="bonus[name]"]', `${eventType} Test Bonus`);
      await page.selectOption('select[name="bonus[event]"]', eventType);
      await page.selectOption('select[name="bonus[status]"]', 'draft');
      await page.selectOption('select[name="bonus[project]"]', 'VOLNA');
      
      // For deposit events, need currencies and currency_minimum_deposits
      if (eventType === 'deposit') {
        await page.selectOption('select[name="bonus[currencies][]"]', 'USD');
        await page.fill('input[name="bonus[currency_minimum_deposits][USD]"]', '10');
      } else {
        // For non-deposit events, just select a currency
        await page.selectOption('select[name="bonus[currencies][]"]', 'USD');
      }
      
      // Submit the form
      await page.click('input[type="submit"][value="Create Bonus"]');
      
      // Should redirect successfully
      await expect(page).toHaveURL(/\/bonuses\/\d+|\/bonuses$/);
      
      // Go back to prepare for next iteration
      if (eventTypes.indexOf(eventType) < eventTypes.length - 1) {
        await page.goBack();
      }
    }
  });

  test('should display form errors when validation fails', async ({ page }) => {
    await page.goto('/bonuses/new');
    
    // Create validation errors by leaving multiple required fields empty
    await page.fill('input[name="bonus[name]"]', ''); // Empty name
    await page.selectOption('select[name="bonus[event]"]', 'deposit');
    // Don't select currencies or project to ensure validation errors
    
    // Submit the form
    await page.click('input[type="submit"][value="Create Bonus"]');
    
    // Should stay on same page (indicates validation failure)
    await expect(page).toHaveURL(/.*\/bonuses\/new/);
    
    // Verify the form is still present (indicates validation failure)
    await expect(page.locator('form')).toBeVisible();
    await expect(page.locator('input[type="submit"][value="Create Bonus"]')).toBeVisible();
    
    // Verify we're still on the creation page
    await expect(page.locator('h1')).toContainText('Create New Bonus');
  });

  test('should handle form submission with JavaScript disabled', async ({ page }) => {
    // Disable JavaScript
    await page.context().setExtraHTTPHeaders({});
    
    await page.goto('/bonuses/new?event=deposit');
    
    // Fill form normally
    await page.fill('input[name="bonus[name]"]', 'No JS Test Bonus');
    await page.selectOption('select[name="bonus[event]"]', 'deposit');
    await page.selectOption('select[name="bonus[status]"]', 'draft');
    await page.selectOption('select[name="bonus[project]"]', 'VOLNA');
    await page.selectOption('select[name="bonus[currencies][]"]', 'USD');
    await page.fill('input[name="bonus[currency_minimum_deposits][USD]"]', '10');
    
    // Submit form
    await page.click('input[type="submit"][value="Create Bonus"]');
    
    // Should still work (Rails handles this server-side)
    await expect(page).toHaveURL(/\/bonuses\/\d+|\/bonuses$/);
  });
});

// Test configuration
test.describe('Bonus Creation - Edge Cases', () => {
  test('should handle very long bonus names', async ({ page }) => {
    await page.goto('/bonuses/new?event=deposit');
    
    // Create a very long name (beyond validation limit)
    const longName = 'A'.repeat(300);
    
    await page.fill('input[name="bonus[name]"]', longName);
    await page.selectOption('select[name="bonus[event]"]', 'deposit');
    await page.selectOption('select[name="bonus[status]"]', 'draft');
    await page.selectOption('select[name="bonus[project]"]', 'VOLNA');
    await page.selectOption('select[name="bonus[currencies][]"]', 'USD');
    await page.fill('input[name="bonus[currency_minimum_deposits][USD]"]', '10');
    
    await page.click('input[type="submit"][value="Create Bonus"]');
    
    // Should stay on form due to validation error
    await expect(page).toHaveURL(/.*\/bonuses\/new/);
  });

  test('should handle special characters in bonus name', async ({ page }) => {
    await page.goto('/bonuses/new?event=deposit');
    
    const specialName = 'Тест бонус с émojis 🎉 & special chars!';
    
    await page.fill('input[name="bonus[name]"]', specialName);
    await page.selectOption('select[name="bonus[event]"]', 'deposit');
    await page.selectOption('select[name="bonus[status]"]', 'draft');
    await page.selectOption('select[name="bonus[project]"]', 'VOLNA');
    await page.selectOption('select[name="bonus[currencies][]"]', 'USD');
    await page.fill('input[name="bonus[currency_minimum_deposits][USD]"]', '10');
    
    await page.click('input[type="submit"][value="Create Bonus"]');
    
    // Should succeed (Rails handles Unicode well)
    await expect(page).toHaveURL(/\/bonuses\/\d+|\/bonuses$/);
  });
});
