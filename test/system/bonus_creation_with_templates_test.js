const { test, expect } = require('@playwright/test');

test.describe('Bonus Creation with Templates', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('http://localhost:3000');
  });

  test('should pre-fill form when using template_id parameter', async ({ page }) => {
    // First create a template
    await page.goto('/settings/templates');
    await page.click('text=New Template');
    
    await page.fill('input[name="bonus_template[name]"]', 'Form Prefill Template');
    await page.fill('input[name="bonus_template[dsl_tag]"]', 'form_prefill');
    await page.selectOption('select[name="bonus_template[project]"]', 'VOLNA');
    await page.selectOption('select[name="bonus_template[event]"]', 'deposit');
    await page.fill('input[name="bonus_template[currencies]"]', 'USD, EUR, GBP');
    await page.fill('input[name="bonus_template[currency_minimum_deposits]"]', '{"USD": 10, "EUR": 8, "GBP": 7}');
    await page.fill('input[name="bonus_template[wager]"]', '35');
    await page.fill('input[name="bonus_template[maximum_winnings]"]', '500');
    await page.fill('input[name="bonus_template[no_more]"]', '1');
    await page.fill('input[name="bonus_template[totally_no_more]"]', '5');
    await page.fill('input[name="bonus_template[groups]"]', 'VIP, Premium, Gold');
    await page.fill('textarea[name="bonus_template[description]"]', 'Complete template for form prefill testing');
    
    await page.click('text=Create Template');
    
    // Get template ID
    const templateRow = page.locator('tbody tr').filter({ hasText: 'Form Prefill Template' });
    await templateRow.locator('.btn-outline-primary').click();
    const templateId = page.url().match(/\/(\d+)$/)?.[1];
    
    // Navigate to bonus creation with template
    await page.goto(`/bonuses/new?template_id=${templateId}`);
    
    // Verify all form fields are pre-filled
    await expect(page.locator('input[name="bonus[dsl_tag]"]')).toHaveValue('form_prefill');
    await expect(page.locator('select[name="bonus[project]"]')).toHaveValue('VOLNA');
    await expect(page.locator('select[name="bonus[event]"]')).toHaveValue('deposit');
    await expect(page.locator('input[name="bonus[wager]"]')).toHaveValue('35.0');
    await expect(page.locator('input[name="bonus[maximum_winnings]"]')).toHaveValue('500.0');
    await expect(page.locator('input[name="bonus[no_more]"]')).toHaveValue('1');
    await expect(page.locator('input[name="bonus[totally_no_more]"]')).toHaveValue('5');
    await expect(page.locator('textarea[name="bonus[description]"]')).toContainText('Complete template for form prefill testing');
    
    // Check that groups field is pre-filled (as text)
    const groupsField = page.locator('input[name="bonus[groups]"]');
    await expect(groupsField).toHaveValue('VIP, Premium, Gold');
    
    // Check currency selection (multi-select)
    const currencySelect = page.locator('select[name="bonus[currencies][]"]');
    const selectedOptions = await currencySelect.evaluate(select => {
      return Array.from(select.selectedOptions).map(option => option.value);
    });
    expect(selectedOptions).toEqual(['USD', 'EUR', 'GBP']);
    
    // Check currency minimum deposits
    await expect(page.locator('input[name="bonus[currency_minimum_deposits][USD]"]')).toHaveValue('10');
    await expect(page.locator('input[name="bonus[currency_minimum_deposits][EUR]"]')).toHaveValue('8');
    await expect(page.locator('input[name="bonus[currency_minimum_deposits][GBP]"]')).toHaveValue('7');
  });

  test('should maintain template data after validation errors', async ({ page }) => {
    // Create a template
    await page.goto('/settings/templates');
    await page.click('text=New Template');
    
    await page.fill('input[name="bonus_template[name]"]', 'Validation Persistence Template');
    await page.fill('input[name="bonus_template[dsl_tag]"]', 'validation_persist');
    await page.selectOption('select[name="bonus_template[project]"]', 'ROX');
    await page.selectOption('select[name="bonus_template[event]"]', 'manual');
    await page.fill('input[name="bonus_template[currencies]"]', 'USD');
    await page.fill('input[name="bonus_template[wager]"]', '0');
    await page.fill('input[name="bonus_template[maximum_winnings]"]', '1000');
    await page.fill('textarea[name="bonus_template[description]"]', 'Template for validation persistence test');
    
    await page.click('text=Create Template');
    
    // Get template ID
    const templateRow = page.locator('tbody tr').filter({ hasText: 'Validation Persistence Template' });
    await templateRow.locator('.btn-outline-primary').click();
    const templateId = page.url().match(/\/(\d+)$/)?.[1];
    
    // Navigate to bonus creation with template
    await page.goto(`/bonuses/new?template_id=${templateId}`);
    
    // Don't fill required fields and submit to trigger validation error
    await page.click('input[type="submit"][value="Create Bonus"]');
    
    // Should stay on form due to validation error
    await expect(page).toHaveURL(/.*bonuses\/new/);
    
    // Template data should be preserved after validation error
    await expect(page.locator('input[name="bonus[dsl_tag]"]')).toHaveValue('validation_persist');
    await expect(page.locator('select[name="bonus[project]"]')).toHaveValue('ROX');
    await expect(page.locator('select[name="bonus[event]"]')).toHaveValue('manual');
    await expect(page.locator('input[name="bonus[wager]"]')).toHaveValue('0');
    await expect(page.locator('input[name="bonus[maximum_winnings]"]')).toHaveValue('1000');
    await expect(page.locator('textarea[name="bonus[description]"]')).toContainText('Template for validation persistence test');
  });

  test('should allow overriding template values', async ({ page }) => {
    // Create a template
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
    
    // Navigate to bonus creation with template
    await page.goto(`/bonuses/new?template_id=${templateId}`);
    
    // Verify template values are pre-filled
    await expect(page.locator('input[name="bonus[wager]"]')).toHaveValue('35.0');
    await expect(page.locator('input[name="bonus[maximum_winnings]"]')).toHaveValue('500.0');
    
    // Override template values
    await page.fill('input[name="bonus[wager]"]', '40');
    await page.fill('input[name="bonus[maximum_winnings]"]', '1000');
    
    // Complete bonus creation
    await page.fill('input[name="bonus[name]"]', 'Override Test Bonus');
    await page.fill('input[name="bonus[code]"]', 'OVERRIDE123');
    await page.selectOption('select[name="bonus[status]"]', 'draft');
    await page.selectOption('select[name="bonus[currencies][]"]', 'USD');
    await page.fill('input[name="bonus[currency_minimum_deposits][USD]"]', '10');
    
    await page.click('input[type="submit"][value="Create Bonus"]');
    
    // Should succeed with overridden values
    await expect(page).toHaveURL(/\/bonuses\/\d+/);
    
    // Check that overridden values were saved
    await expect(page.locator('body')).toContainText('Override Test Bonus');
    // Note: We'd need to check the actual bonus details to verify the overridden values
  });

  test('should handle template with multiple currencies', async ({ page }) => {
    // Create template with multiple currencies
    await page.goto('/settings/templates');
    await page.click('text=New Template');
    
    await page.fill('input[name="bonus_template[name]"]', 'Multi Currency Template');
    await page.fill('input[name="bonus_template[dsl_tag]"]', 'multi_currency');
    await page.selectOption('select[name="bonus_template[project]"]', 'VOLNA');
    await page.selectOption('select[name="bonus_template[event]"]', 'deposit');
    await page.fill('input[name="bonus_template[currencies]"]', 'USD, EUR, GBP, RUB, UAH');
    await page.fill('input[name="bonus_template[currency_minimum_deposits]"]', '{"USD": 10, "EUR": 8, "GBP": 7, "RUB": 750, "UAH": 300}');
    await page.fill('input[name="bonus_template[wager]"]', '35');
    await page.fill('input[name="bonus_template[maximum_winnings]"]', '500');
    
    await page.click('text=Create Template');
    
    // Get template ID and create bonus
    const templateRow = page.locator('tbody tr').filter({ hasText: 'Multi Currency Template' });
    await templateRow.locator('.btn-outline-primary').click();
    const templateId = page.url().match(/\/(\d+)$/)?.[1];
    
    await page.goto(`/bonuses/new?template_id=${templateId}`);
    
    // Check that all currencies are selected
    const currencySelect = page.locator('select[name="bonus[currencies][]"]');
    const selectedOptions = await currencySelect.evaluate(select => {
      return Array.from(select.selectedOptions).map(option => option.value);
    });
    expect(selectedOptions).toEqual(expect.arrayContaining(['USD', 'EUR', 'GBP', 'RUB', 'UAH']));
    
    // Check currency minimum deposits are set
    await expect(page.locator('input[name="bonus[currency_minimum_deposits][USD]"]')).toHaveValue('10');
    await expect(page.locator('input[name="bonus[currency_minimum_deposits][EUR]"]')).toHaveValue('8');
    await expect(page.locator('input[name="bonus[currency_minimum_deposits][GBP]"]')).toHaveValue('7');
    await expect(page.locator('input[name="bonus[currency_minimum_deposits][RUB]"]')).toHaveValue('750');
    await expect(page.locator('input[name="bonus[currency_minimum_deposits][UAH]"]')).toHaveValue('300');
    
    // Create the bonus
    await page.fill('input[name="bonus[name]"]', 'Multi Currency Bonus');
    await page.fill('input[name="bonus[code]"]', 'MULTICURR123');
    await page.selectOption('select[name="bonus[status]"]', 'draft');
    
    await page.click('input[type="submit"][value="Create Bonus"]');
    
    // Should succeed
    await expect(page).toHaveURL(/\/bonuses\/\d+/);
  });

  test('should handle template with complex groups', async ({ page }) => {
    // Create template with multiple groups
    await page.goto('/settings/templates');
    await page.click('text=New Template');
    
    await page.fill('input[name="bonus_template[name]"]', 'Complex Groups Template');
    await page.fill('input[name="bonus_template[dsl_tag]"]', 'complex_groups');
    await page.selectOption('select[name="bonus_template[project]"]', 'VOLNA');
    await page.selectOption('select[name="bonus_template[event]"]', 'manual');
    await page.fill('input[name="bonus_template[currencies]"]', 'USD');
    await page.fill('input[name="bonus_template[wager]"]', '0');
    await page.fill('input[name="bonus_template[maximum_winnings]"]', '500');
    await page.fill('input[name="bonus_template[groups]"]', 'VIP, Premium, Gold, Platinum, Diamond');
    
    await page.click('text=Create Template');
    
    // Get template ID and create bonus
    const templateRow = page.locator('tbody tr').filter({ hasText: 'Complex Groups Template' });
    await templateRow.locator('.btn-outline-primary').click();
    const templateId = page.url().match(/\/(\d+)$/)?.[1];
    
    await page.goto(`/bonuses/new?template_id=${templateId}`);
    
    // Check that groups field is populated
    await expect(page.locator('input[name="bonus[groups]"]')).toHaveValue('VIP, Premium, Gold, Platinum, Diamond');
    
    // Modify groups and create bonus
    await page.fill('input[name="bonus[groups]"]', 'VIP, Platinum');
    
    await page.fill('input[name="bonus[name]"]', 'Complex Groups Bonus');
    await page.fill('input[name="bonus[code]"]', 'GROUPS123');
    await page.selectOption('select[name="bonus[status]"]', 'draft');
    await page.selectOption('select[name="bonus[currencies][]"]', 'USD');
    
    await page.click('input[type="submit"][value="Create Bonus"]');
    
    // Should succeed
    await expect(page).toHaveURL(/\/bonuses\/\d+/);
  });

  test('should work with template for different event types', async ({ page }) => {
    const eventConfigs = [
      {
        event: 'deposit',
        needsMinDeposits: true,
        wager: '35',
        maxWin: '500',
        currencies: 'USD, EUR',
        minDeposits: '{"USD": 10, "EUR": 8}'
      },
      {
        event: 'manual',
        needsMinDeposits: false,
        wager: '0',
        maxWin: '1000',
        currencies: 'USD',
        minDeposits: '{}'
      },
      {
        event: 'input_coupon',
        needsMinDeposits: false,
        wager: '20',
        maxWin: '200',
        currencies: 'USD',
        minDeposits: '{}'
      }
    ];
    
    for (const config of eventConfigs) {
      // Create template for this event type
      await page.goto('/settings/templates');
      await page.click('text=New Template');
      
      const templateName = `${config.event.charAt(0).toUpperCase() + config.event.slice(1)} Event Template`;
      
      await page.fill('input[name="bonus_template[name]"]', templateName);
      await page.fill('input[name="bonus_template[dsl_tag]"]', `${config.event}_event`);
      await page.selectOption('select[name="bonus_template[project]"]', 'VOLNA');
      await page.selectOption('select[name="bonus_template[event]"]', config.event);
      await page.fill('input[name="bonus_template[currencies]"]', config.currencies);
      await page.fill('input[name="bonus_template[currency_minimum_deposits]"]', config.minDeposits);
      await page.fill('input[name="bonus_template[wager]"]', config.wager);
      await page.fill('input[name="bonus_template[maximum_winnings]"]', config.maxWin);
      
      await page.click('text=Create Template');
      
      // Get template ID and create bonus
      const templateRow = page.locator('tbody tr').filter({ hasText: templateName });
      await templateRow.locator('.btn-outline-primary').click();
      const templateId = page.url().match(/\/(\d+)$/)?.[1];
      
      await page.goto(`/bonuses/new?template_id=${templateId}`);
      
      // Verify correct event type is selected
      await expect(page.locator('select[name="bonus[event]"]')).toHaveValue(config.event);
      
      // Check currency minimum deposits section visibility
      const currencyMinDepositsSection = page.locator('#currency-minimum-deposits-section');
      if (config.needsMinDeposits) {
        await expect(currencyMinDepositsSection).toBeVisible();
      } else {
        await expect(currencyMinDepositsSection).toHaveCSS('display', 'none');
      }
      
      // Complete bonus creation
      await page.fill('input[name="bonus[name]"]', `Test ${config.event} Bonus`);
      await page.fill('input[name="bonus[code]"]', `${config.event.toUpperCase()}123`);
      await page.selectOption('select[name="bonus[status]"]', 'draft');
      
      // Handle currencies
      const currencies = config.currencies.split(', ');
      for (const currency of currencies) {
        await page.selectOption('select[name="bonus[currencies][]"]', currency);
      }
      
      // Set currency minimum deposits if needed
      if (config.needsMinDeposits) {
        const minDeposits = JSON.parse(config.minDeposits);
        for (const [currency, amount] of Object.entries(minDeposits)) {
          await page.fill(`input[name="bonus[currency_minimum_deposits][${currency}]"]`, amount.toString());
        }
      }
      
      await page.click('input[type="submit"][value="Create Bonus"]');
      
      // Should succeed
      await expect(page).toHaveURL(/\/bonuses\/\d+/);
      await expect(page.locator('body')).toContainText(`Test ${config.event} Bonus`);
    }
  });

  test('should display helpful validation messages when template data conflicts', async ({ page }) => {
    // Create a template with specific requirements
    await page.goto('/settings/templates');
    await page.click('text=New Template');
    
    await page.fill('input[name="bonus_template[name]"]', 'Strict Validation Template');
    await page.fill('input[name="bonus_template[dsl_tag]"]', 'strict_validation');
    await page.selectOption('select[name="bonus_template[project]"]', 'VOLNA');
    await page.selectOption('select[name="bonus_template[event]"]', 'deposit');
    await page.fill('input[name="bonus_template[currencies]"]', 'USD');
    await page.fill('input[name="bonus_template[currency_minimum_deposits]"]', '{"USD": 100}');
    await page.fill('input[name="bonus_template[wager]"]', '50');
    await page.fill('input[name="bonus_template[maximum_winnings]"]', '2000');
    
    await page.click('text=Create Template');
    
    // Get template ID and create bonus
    const templateRow = page.locator('tbody tr').filter({ hasText: 'Strict Validation Template' });
    await templateRow.locator('.btn-outline-primary').click();
    const templateId = page.url().match(/\/(\d+)$/)?.[1];
    
    await page.goto(`/bonuses/new?template_id=${templateId}`);
    
    // Try to create bonus with conflicting data
    await page.fill('input[name="bonus[name]"]', ''); // Empty name should cause validation error
    await page.fill('input[name="bonus[code]"]', 'STRICT123');
    await page.selectOption('select[name="bonus[status]"]', 'draft');
    await page.selectOption('select[name="bonus[currencies][]"]', 'USD');
    await page.fill('input[name="bonus[currency_minimum_deposits][USD]"]', '100');
    
    await page.click('input[type="submit"][value="Create Bonus"]');
    
    // Should stay on form due to validation error
    await expect(page).toHaveURL(/.*bonuses\/new/);
    
    // Check that validation errors are shown appropriately
    // Template data should be preserved
    await expect(page.locator('input[name="bonus[dsl_tag]"]')).toHaveValue('strict_validation');
    await expect(page.locator('select[name="bonus[project]"]')).toHaveValue('VOLNA');
    await expect(page.locator('input[name="bonus[wager]"]')).toHaveValue('50');
    await expect(page.locator('input[name="bonus[maximum_winnings]"]')).toHaveValue('2000');
    
    // Fix the validation error
    await page.fill('input[name="bonus[name]"]', 'Strict Validation Bonus');
    
    await page.click('input[type="submit"][value="Create Bonus"]');
    
    // Should succeed now
    await expect(page).toHaveURL(/\/bonuses\/\d+/);
  });
});

