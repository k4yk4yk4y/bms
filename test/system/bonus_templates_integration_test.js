const { test, expect } = require('@playwright/test');

test.describe('Bonus Templates Integration', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the application
    await page.goto('http://localhost:3000');
  });

  test('should create template and apply it to new bonus', async ({ page }) => {
    // Step 1: Create a bonus template
    await page.click('text=Settings');
    await page.click('text=Templates');
    
    // Click "New Template" button
    await page.click('text=New Template');
    
    // Fill in the template form
    await page.fill('input[name="bonus_template[name]"]', 'E2E Welcome Bonus Template');
    await page.fill('input[name="bonus_template[dsl_tag]"]', 'e2e_welcome_bonus');
    await page.selectOption('select[name="bonus_template[project]"]', 'VOLNA');
    await page.selectOption('select[name="bonus_template[event]"]', 'deposit');
    // Note: currencies and currency_minimum_deposits are handled by the model, not form fields
    await page.fill('input[name="bonus_template[wager]"]', '35');
    await page.fill('input[name="bonus_template[maximum_winnings]"]', '500');
    await page.fill('input[name="bonus_template[no_more]"]', '1');
    await page.fill('input[name="bonus_template[totally_no_more]"]', '5');
    await page.fill('input[name="bonus_template[groups]"]', 'VIP, Premium');
    await page.fill('textarea[name="bonus_template[description]"]', 'E2E test welcome bonus template');
    
    // Submit the form
    await page.click('text=Create Template');
    
    // Check for success message
    await expect(page.locator('.alert-success')).toContainText('Шаблон бонуса успешно создан');
    
    // Verify the template appears in the list
    await expect(page.locator('table')).toContainText('E2E Welcome Bonus Template');
    await expect(page.locator('table')).toContainText('e2e_welcome_bonus');
    await expect(page.locator('table')).toContainText('VOLNA');

    // Step 2: Navigate to create bonus using template
    // Find the template row and click the view button
    const templateRow = page.locator('tbody tr').filter({ hasText: 'E2E Welcome Bonus Template' });
    await templateRow.locator('.btn-outline-primary').click();

    // Check template details page
    await expect(page.locator('h1')).toContainText('Bonus Template Details');
    
    // Click "Create Bonus from Template" button (if it exists)
    const createBonusButton = page.locator('text=Create Bonus from Template');
    if (await createBonusButton.isVisible()) {
      await createBonusButton.click();
    } else {
      // Alternative: get template ID from URL and navigate manually
      const templateId = page.url().match(/\/(\d+)$/)?.[1];
      if (templateId) {
        await page.goto(`/bonuses/new?template_id=${templateId}`);
      } else {
        // Fallback: just go to new bonus page
        await page.goto('/bonuses/new');
      }
    }

    // Step 3: Verify template data is pre-filled
    await expect(page).toHaveURL(/.*bonuses\/new/);
    
    // Check that template data is pre-filled
    await expect(page.locator('input[name="bonus[dsl_tag]"]')).toHaveValue('e2e_welcome_bonus');
    await expect(page.locator('select[name="bonus[project]"]')).toHaveValue('VOLNA');
    await expect(page.locator('select[name="bonus[event]"]')).toHaveValue('deposit');
    await expect(page.locator('input[name="bonus[wager]"]')).toHaveValue('35.0');
    await expect(page.locator('input[name="bonus[maximum_winnings]"]')).toHaveValue('500.0');
    await expect(page.locator('textarea[name="bonus[description]"]')).toContainText('E2E test welcome bonus template');

    // Step 4: Complete bonus creation
    await page.fill('input[name="bonus[name]"]', 'E2E Test Bonus from Template');
    await page.fill('input[name="bonus[code]"]', 'E2ETEST123');
    await page.selectOption('select[name="bonus[status]"]', 'draft');
    
    // Select currencies (multi-select)
    await page.selectOption('select[name="bonus[currencies][]"]', ['USD', 'EUR']);
    
    // Set currency minimum deposits
    await page.fill('input[name="bonus[currency_minimum_deposits][USD]"]', '10');
    await page.fill('input[name="bonus[currency_minimum_deposits][EUR]"]', '8');
    
    // Submit the form
    await page.click('input[type="submit"][value="Create Bonus"]');
    
    // Check for successful creation
    await expect(page).toHaveURL(/\/bonuses\/\d+/);
    await expect(page.locator('.alert-success')).toContainText('successfully created');
    
    // Verify bonus details match template
    await expect(page.locator('body')).toContainText('E2E Test Bonus from Template');
    await expect(page.locator('body')).toContainText('e2e_welcome_bonus');
    await expect(page.locator('body')).toContainText('VOLNA');
    await expect(page.locator('body')).toContainText('deposit');
  });

  test('should apply template via URL parameter', async ({ page }) => {
    // First, create a template (we'll reuse the one from previous test if it exists)
    await page.goto('/settings/templates');
    
    // Check if our test template exists
    const templateExists = await page.locator('table').textContent().then(text => 
      text.includes('E2E Welcome Bonus Template')
    ).catch(() => false);
    
    let templateId;
    
    if (!templateExists) {
      // Create the template
      await page.click('text=New Template');
      await page.fill('input[name="bonus_template[name]"]', 'URL Test Template');
      await page.fill('input[name="bonus_template[dsl_tag]"]', 'url_test_template');
      await page.selectOption('select[name="bonus_template[project]"]', 'ROX');
      await page.selectOption('select[name="bonus_template[event]"]', 'manual');
      await page.fill('input[name="bonus_template[currencies]"]', 'USD');
      await page.fill('input[name="bonus_template[wager]"]', '0');
      await page.fill('input[name="bonus_template[maximum_winnings]"]', '1000');
      await page.fill('textarea[name="bonus_template[description]"]', 'Manual bonus template for URL test');
      
      await page.click('text=Create Template');
      await expect(page.locator('.alert-success')).toContainText('успешно создан');
      
      // Get the template ID from the created template
      const templateRow = page.locator('tbody tr').filter({ hasText: 'URL Test Template' });
      await templateRow.locator('.btn-outline-primary').click();
      templateId = page.url().match(/\/(\d+)$/)?.[1];
    } else {
      // Get existing template ID
      const templateRow = page.locator('tbody tr').filter({ hasText: 'E2E Welcome Bonus Template' });
      await templateRow.locator('.btn-outline-primary').click();
      templateId = page.url().match(/\/(\d+)$/)?.[1];
    }
    
    // Navigate to bonus creation with template_id parameter
    await page.goto(`/bonuses/new?template_id=${templateId}`);
    
    // Verify template data is applied
    await expect(page.locator('input[name="bonus[dsl_tag]"]')).not.toHaveValue('');
    await expect(page.locator('select[name="bonus[project]"]')).not.toHaveValue('');
    await expect(page.locator('select[name="bonus[event]"]')).not.toHaveValue('');
    
    // The form should be pre-filled with template data
    const dslTag = await page.locator('input[name="bonus[dsl_tag]"]').inputValue();
    const project = await page.locator('select[name="bonus[project]"]').inputValue();
    const event = await page.locator('select[name="bonus[event]"]').inputValue();
    
    expect(dslTag).toBeTruthy();
    expect(project).toBeTruthy();
    expect(event).toBeTruthy();
  });

  test('should handle invalid template_id gracefully', async ({ page }) => {
    // Navigate with non-existent template ID
    await page.goto('/bonuses/new?template_id=99999');
    
    // Page should load normally without errors
    await expect(page.locator('h1')).toContainText('Create New Bonus');
    
    // Form should be empty (not pre-filled)
    await expect(page.locator('input[name="bonus[dsl_tag]"]')).toHaveValue('');
    await expect(page.locator('select[name="bonus[project]"]')).toHaveValue('');
    
    // Default event should be selected
    await expect(page.locator('select[name="bonus[event]"]')).toHaveValue('deposit');
  });

  test('should override template event with URL parameter', async ({ page }) => {
    // First create a deposit template
    await page.goto('/settings/templates');
    
    await page.click('text=New Template');
    await page.fill('input[name="bonus_template[name]"]', 'Override Test Template');
    await page.fill('input[name="bonus_template[dsl_tag]"]', 'override_test');
    await page.selectOption('select[name="bonus_template[project]"]', 'VOLNA');
    await page.selectOption('select[name="bonus_template[event]"]', 'deposit');
    await page.fill('input[name="bonus_template[currencies]"]', 'USD');
    await page.fill('input[name="bonus_template[currency_minimum_deposits]"]', '{"USD": 10}');
    await page.fill('input[name="bonus_template[wager]"]', '35');
    await page.fill('input[name="bonus_template[maximum_winnings]"]', '500');
    
    await page.click('text=Create Template');
    
    // Get template ID
    const templateRow = page.locator('tbody tr').filter({ hasText: 'Override Test Template' });
    await templateRow.locator('.btn-outline-primary').click();
    const templateId = page.url().match(/\/(\d+)$/)?.[1];
    
    // Navigate with both template_id and event parameters
    await page.goto(`/bonuses/new?template_id=${templateId}&event=manual`);
    
    // Event should be manual (from URL) not deposit (from template)
    await expect(page.locator('select[name="bonus[event]"]')).toHaveValue('manual');
    
    // But other template data should still be applied
    await expect(page.locator('input[name="bonus[dsl_tag]"]')).toHaveValue('override_test');
    await expect(page.locator('select[name="bonus[project]"]')).toHaveValue('VOLNA');
  });

  test('should create freespin bonus from template', async ({ page }) => {
    // Create a freespin template
    await page.goto('/settings/templates');
    
    await page.click('text=New Template');
    await page.fill('input[name="bonus_template[name]"]', 'Freespin Test Template');
    await page.fill('input[name="bonus_template[dsl_tag]"]', 'freespin_test');
    await page.selectOption('select[name="bonus_template[project]"]', 'FRESH');
    await page.selectOption('select[name="bonus_template[event]"]', 'deposit');
    await page.fill('input[name="bonus_template[currencies]"]', 'USD, EUR');
    await page.fill('input[name="bonus_template[currency_minimum_deposits]"]', '{"USD": 20, "EUR": 15}');
    await page.fill('input[name="bonus_template[wager]"]', '25');
    await page.fill('input[name="bonus_template[maximum_winnings]"]', '200');
    await page.fill('textarea[name="bonus_template[description]"]', 'Freespin bonus template');
    
    await page.click('text=Create Template');
    
    // Get template ID and navigate to bonus creation
    const templateRow = page.locator('tbody tr').filter({ hasText: 'Freespin Test Template' });
    await templateRow.locator('.btn-outline-primary').click();
    const templateId = page.url().match(/\/(\d+)$/)?.[1];
    
    await page.goto(`/bonuses/new?template_id=${templateId}`);
    
    // Fill in bonus details
    await page.fill('input[name="bonus[name]"]', 'Test Freespin Bonus');
    await page.fill('input[name="bonus[code]"]', 'FREESPIN123');
    await page.selectOption('select[name="bonus[status]"]', 'draft');
    
    // Select currencies
    await page.selectOption('select[name="bonus[currencies][]"]', ['USD', 'EUR']);
    
    // Set currency minimum deposits from template
    await page.fill('input[name="bonus[currency_minimum_deposits][USD]"]', '20');
    await page.fill('input[name="bonus[currency_minimum_deposits][EUR]"]', '15');
    
    // Add freespin reward
    const addFreespinButton = page.locator('button:has-text("Add Freespins"), button:has-text("Add Free Spins")');
    if (await addFreespinButton.isVisible()) {
      await addFreespinButton.click();
      
      // Fill freespin details
      await page.fill('input[name="freespin_reward[spins_count]"]', '50');
      await page.fill('input[name="freespin_reward[games]"]', 'Book of Dead, Starburst');
      await page.fill('input[name="freespin_reward[bet_level]"]', '0.10');
      await page.fill('input[name="freespin_reward[max_win]"]', '100');
    }
    
    // Submit the form
    await page.click('input[type="submit"][value="Create Bonus"]');
    
    // Check for successful creation
    await expect(page).toHaveURL(/\/bonuses\/\d+/);
    
    // Verify bonus was created with template data
    await expect(page.locator('body')).toContainText('Test Freespin Bonus');
    await expect(page.locator('body')).toContainText('freespin_test');
    await expect(page.locator('body')).toContainText('FRESH');
  });

  test('should validate template data in bonus form', async ({ page }) => {
    // Create template with validation constraints
    await page.goto('/settings/templates');
    
    await page.click('text=New Template');
    await page.fill('input[name="bonus_template[name]"]', 'Validation Test Template');
    await page.fill('input[name="bonus_template[dsl_tag]"]', 'validation_test');
    await page.selectOption('select[name="bonus_template[project]"]', 'VOLNA');
    await page.selectOption('select[name="bonus_template[event]"]', 'deposit');
    await page.fill('input[name="bonus_template[currencies]"]', 'USD');
    await page.fill('input[name="bonus_template[currency_minimum_deposits]"]', '{"USD": 50}');
    await page.fill('input[name="bonus_template[wager]"]', '40');
    await page.fill('input[name="bonus_template[maximum_winnings]"]', '1000');
    
    await page.click('text=Create Template');
    
    // Get template ID and navigate to bonus creation
    const templateRow = page.locator('tbody tr').filter({ hasText: 'Validation Test Template' });
    await templateRow.locator('.btn-outline-primary').click();
    const templateId = page.url().match(/\/(\d+)$/)?.[1];
    
    await page.goto(`/bonuses/new?template_id=${templateId}`);
    
    // Try to submit without required fields
    await page.click('input[type="submit"][value="Create Bonus"]');
    
    // Should stay on form due to validation errors
    await expect(page).toHaveURL(/.*bonuses\/new/);
    
    // Template data should be preserved
    await expect(page.locator('input[name="bonus[dsl_tag]"]')).toHaveValue('validation_test');
    await expect(page.locator('select[name="bonus[project]"]')).toHaveValue('VOLNA');
    
    // Now fill required fields
    await page.fill('input[name="bonus[name]"]', 'Validation Test Bonus');
    await page.fill('input[name="bonus[code]"]', 'VALIDATION123');
    await page.selectOption('select[name="bonus[status]"]', 'draft');
    await page.selectOption('select[name="bonus[currencies][]"]', 'USD');
    await page.fill('input[name="bonus[currency_minimum_deposits][USD]"]', '50');
    
    // Submit again
    await page.click('input[type="submit"][value="Create Bonus"]');
    
    // Should succeed now
    await expect(page).toHaveURL(/\/bonuses\/\d+/);
  });

  test('should display template information in bonus form', async ({ page }) => {
    // Create a template first
    await page.goto('/settings/templates');
    
    await page.click('text=New Template');
    await page.fill('input[name="bonus_template[name]"]', 'Info Display Template');
    await page.fill('input[name="bonus_template[dsl_tag]"]', 'info_display');
    await page.selectOption('select[name="bonus_template[project]"]', 'SOL');
    await page.selectOption('select[name="bonus_template[event]"]', 'manual');
    await page.fill('input[name="bonus_template[currencies]"]', 'USD');
    await page.fill('input[name="bonus_template[wager]"]', '0');
    await page.fill('input[name="bonus_template[maximum_winnings]"]', '500');
    await page.fill('textarea[name="bonus_template[description]"]', 'Template for display testing');
    
    await page.click('text=Create Template');
    
    // Get template ID and navigate to bonus creation
    const templateRow = page.locator('tbody tr').filter({ hasText: 'Info Display Template' });
    await templateRow.locator('.btn-outline-primary').click();
    const templateId = page.url().match(/\/(\d+)$/)?.[1];
    
    await page.goto(`/bonuses/new?template_id=${templateId}`);
    
    // Check that form shows template values
    await expect(page.locator('input[name="bonus[dsl_tag]"]')).toHaveValue('info_display');
    await expect(page.locator('select[name="bonus[project]"]')).toHaveValue('SOL');
    await expect(page.locator('select[name="bonus[event]"]')).toHaveValue('manual');
    await expect(page.locator('input[name="bonus[wager]"]')).toHaveValue('0.0');
    await expect(page.locator('input[name="bonus[maximum_winnings]"]')).toHaveValue('500.0');
    await expect(page.locator('textarea[name="bonus[description]"]')).toContainText('Template for display testing');
    
    // Verify the correct event-specific fields are shown
    // For manual events, currency minimum deposits should be hidden
    const currencyMinDepositsSection = page.locator('#currency-minimum-deposits-section');
    await expect(currencyMinDepositsSection).toHaveCSS('display', 'none');
  });

  test('should handle template with different event types correctly', async ({ page }) => {
    const eventTypes = [
      { event: 'deposit', needsMinDeposits: true },
      { event: 'manual', needsMinDeposits: false },
      { event: 'input_coupon', needsMinDeposits: false },
      { event: 'collection', needsMinDeposits: false }
    ];
    
    for (const { event, needsMinDeposits } of eventTypes) {
      // Create template for each event type
      await page.goto('/settings/templates');
      
      await page.click('text=New Template');
      await page.fill('input[name="bonus_template[name]"]', `${event.charAt(0).toUpperCase() + event.slice(1)} Template`);
      await page.fill('input[name="bonus_template[dsl_tag]"]', `${event}_template`);
      await page.selectOption('select[name="bonus_template[project]"]', 'VOLNA');
      await page.selectOption('select[name="bonus_template[event]"]', event);
      await page.fill('input[name="bonus_template[currencies]"]', 'USD');
      
      // Only set minimum deposits for deposit events
      if (needsMinDeposits) {
        await page.fill('input[name="bonus_template[currency_minimum_deposits]"]', '{"USD": 10}');
      }
      
      await page.fill('input[name="bonus_template[wager]"]', needsMinDeposits ? '35' : '0');
      await page.fill('input[name="bonus_template[maximum_winnings]"]', '500');
      
      await page.click('text=Create Template');
      
      // Get template ID and test bonus creation
      const templateRow = page.locator('tbody tr').filter({ hasText: `${event.charAt(0).toUpperCase() + event.slice(1)} Template` });
      await templateRow.locator('.btn-outline-primary').click();
      const templateId = page.url().match(/\/(\d+)$/)?.[1];
      
      await page.goto(`/bonuses/new?template_id=${templateId}`);
      
      // Verify correct event is selected
      await expect(page.locator('select[name="bonus[event]"]')).toHaveValue(event);
      
      // Check currency minimum deposits visibility
      const currencyMinDepositsSection = page.locator('#currency-minimum-deposits-section');
      if (needsMinDeposits) {
        await expect(currencyMinDepositsSection).toBeVisible();
      } else {
        await expect(currencyMinDepositsSection).toHaveCSS('display', 'none');
      }
      
      // Create bonus
      await page.fill('input[name="bonus[name]"]', `Test ${event} Bonus`);
      await page.fill('input[name="bonus[code]"]', `${event.toUpperCase()}123`);
      await page.selectOption('select[name="bonus[status]"]', 'draft');
      await page.selectOption('select[name="bonus[currencies][]"]', 'USD');
      
      if (needsMinDeposits) {
        await page.fill('input[name="bonus[currency_minimum_deposits][USD]"]', '10');
      }
      
      await page.click('input[type="submit"][value="Create Bonus"]');
      
      // Should succeed
      await expect(page).toHaveURL(/\/bonuses\/\d+/);
      await expect(page.locator('body')).toContainText(`Test ${event} Bonus`);
    }
  });
});

test.describe('Bonus Templates - Error Handling', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('http://localhost:3000');
  });

  test('should handle network errors gracefully', async ({ page }) => {
    // Navigate to templates page
    await page.goto('/settings/templates');
    
    // Simulate network failure
    await page.route('**/settings/templates', route => route.abort());
    
    // Try to create new template
    try {
      await page.click('text=New Template');
      // If we get here, the route wasn't intercepted
    } catch (error) {
      // Expected behavior - network error
    }
    
    // Remove route interception
    await page.unroute('**/settings/templates');
    
    // Page should recover
    await page.goto('/settings/templates');
    await expect(page.locator('h1')).toContainText('Bonus Templates');
  });

  test('should validate template data before applying to bonus', async ({ page }) => {
    // Try to access bonus creation with malformed template_id
    await page.goto('/bonuses/new?template_id=invalid');
    
    // Should load normally with empty form
    await expect(page.locator('h1')).toContainText('Create New Bonus');
    await expect(page.locator('input[name="bonus[dsl_tag]"]')).toHaveValue('');
  });

  test('should handle concurrent template modifications', async ({ page, context }) => {
    // This test simulates two users modifying the same template
    const page2 = await context.newPage();
    
    // Both pages navigate to templates
    await page.goto('/settings/templates');
    await page2.goto('/settings/templates');
    
    // Create a template on page1
    await page.click('text=New Template');
    await page.fill('input[name="bonus_template[name]"]', 'Concurrent Test Template');
    await page.fill('input[name="bonus_template[dsl_tag]"]', 'concurrent_test');
    await page.selectOption('select[name="bonus_template[project]"]', 'VOLNA');
    await page.selectOption('select[name="bonus_template[event]"]', 'deposit');
    await page.fill('input[name="bonus_template[currencies]"]', 'USD');
    await page.fill('input[name="bonus_template[currency_minimum_deposits]"]', '{"USD": 10}');
    await page.fill('input[name="bonus_template[wager]"]', '35');
    await page.fill('input[name="bonus_template[maximum_winnings]"]', '500');
    
    await page.click('text=Create Template');
    
    // Refresh page2 to see the new template
    await page2.reload();
    await expect(page2.locator('table')).toContainText('Concurrent Test Template');
    
    // Both pages can use the template
    const templateRow1 = page.locator('tbody tr').filter({ hasText: 'Concurrent Test Template' });
    const templateRow2 = page2.locator('tbody tr').filter({ hasText: 'Concurrent Test Template' });
    
    await templateRow1.locator('.btn-outline-primary').click();
    await templateRow2.locator('.btn-outline-primary').click();
    
    // Both should show template details
    await expect(page.locator('h1')).toContainText('Bonus Template Details');
    await expect(page2.locator('h1')).toContainText('Bonus Template Details');
    
    await page2.close();
  });
});
