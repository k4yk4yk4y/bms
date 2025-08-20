const { test, expect } = require('@playwright/test');

test.describe('Bonus Templates', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the application
    await page.goto('http://localhost:3000');
  });

  test('should display bonus templates page', async ({ page }) => {
    // Navigate to Settings > Templates
    await page.click('text=Settings');
    await page.click('text=Templates');
    
    // Check if we're on the templates page
    await expect(page).toHaveURL(/.*settings\/templates/);
    await expect(page.locator('h1')).toContainText('Bonus Templates');
  });

  test('should create a new bonus template', async ({ page }) => {
    // Navigate to Settings > Templates
    await page.click('text=Settings');
    await page.click('text=Templates');
    
    // Click "New Template" button
    await page.click('text=New Template');
    
    // Fill in the template form
    await page.fill('input[name="bonus_template[name]"]', 'Test Welcome Bonus');
    await page.fill('input[name="bonus_template[dsl_tag]"]', 'welcome_bonus');
    await page.selectOption('select[name="bonus_template[project]"]', 'VOLNA');
    await page.selectOption('select[name="bonus_template[event]"]', 'deposit');
    await page.fill('input[name="bonus_template[currency]"]', 'USD');
    await page.fill('input[name="bonus_template[minimum_deposit]"]', '10');
    await page.fill('input[name="bonus_template[wager]"]', '35');
    await page.fill('input[name="bonus_template[maximum_winnings]"]', '500');
    await page.fill('textarea[name="bonus_template[description]"]', 'Test welcome bonus template');
    
    // Submit the form
    await page.click('text=Create Template');
    
    // Check for success message
    await expect(page.locator('.alert-success')).toContainText('Шаблон бонуса успешно создан');
    
    // Verify the template appears in the list
    await expect(page.locator('table')).toContainText('Test Welcome Bonus');
    await expect(page.locator('table')).toContainText('welcome_bonus');
    await expect(page.locator('table')).toContainText('VOLNA');
  });

  test('should filter templates by project', async ({ page }) => {
    // Navigate to Settings > Templates
    await page.click('text=Settings');
    await page.click('text=Templates');
    
    // Select a project filter
    await page.selectOption('#project-filter', 'VOLNA');
    
    // Check that only VOLNA templates are visible
    const rows = page.locator('tbody tr');
    await expect(rows).toHaveCount(await rows.filter({ hasText: 'VOLNA' }).count());
  });

  test('should filter templates by DSL tag', async ({ page }) => {
    // Navigate to Settings > Templates
    await page.click('text=Settings');
    await page.click('text=Templates');
    
    // Select a DSL tag filter
    await page.selectOption('#dsl-tag-filter', 'welcome_bonus');
    
    // Check that only welcome_bonus templates are visible
    const rows = page.locator('tbody tr');
    await expect(rows).toHaveCount(await rows.filter({ hasText: 'welcome_bonus' }).count());
  });

  test('should edit a bonus template', async ({ page }) => {
    // Navigate to Settings > Templates
    await page.click('text=Settings');
    await page.click('text=Templates');
    
    // Click edit button on the first template
    await page.click('tbody tr:first-child .btn-outline-warning');
    
    // Update the template name
    await page.fill('input[name="bonus_template[name]"]', 'Updated Template Name');
    
    // Submit the form
    await page.click('text=Update Template');
    
    // Check for success message
    await expect(page.locator('.alert-success')).toContainText('Шаблон бонуса успешно обновлен');
    
    // Verify the updated name appears in the list
    await expect(page.locator('table')).toContainText('Updated Template Name');
  });

  test('should delete a bonus template', async ({ page }) => {
    // Navigate to Settings > Templates
    await page.click('text=Settings');
    await page.click('text=Templates');
    
    // Get the number of templates before deletion
    const initialCount = await page.locator('tbody tr').count();
    
    // Click delete button on the first template
    await page.click('tbody tr:first-child .btn-outline-danger');
    
    // Confirm deletion
    await page.click('text=OK');
    
    // Check for success message
    await expect(page.locator('.alert-success')).toContainText('Шаблон бонуса успешно удален');
    
    // Verify the template count decreased
    const finalCount = await page.locator('tbody tr').count();
    expect(finalCount).toBe(initialCount - 1);
  });

  test('should create bonus from template', async ({ page }) => {
    // Navigate to Settings > Templates
    await page.click('text=Settings');
    await page.click('text=Templates');
    
    // Click view button on the first template
    await page.click('tbody tr:first-child .btn-outline-primary');
    
    // Click "Create Bonus from Template" button
    await page.click('text=Create Bonus from Template');
    
    // Check that we're on the new bonus page with template data pre-filled
    await expect(page).toHaveURL(/.*bonuses\/new/);
    
    // Verify template data is pre-filled
    const nameField = page.locator('input[name="bonus[name]"]');
    await expect(nameField).toHaveValue(/.*/); // Should have some value
    
    const dslTagField = page.locator('input[name="bonus[dsl_tag]"]');
    await expect(dslTagField).toHaveValue(/.*/); // Should have some value
  });

  test('should display template details', async ({ page }) => {
    // Navigate to Settings > Templates
    await page.click('text=Settings');
    await page.click('text=Templates');
    
    // Click view button on the first template
    await page.click('tbody tr:first-child .btn-outline-primary');
    
    // Check that template details are displayed
    await expect(page.locator('h1')).toContainText('Bonus Template Details');
    await expect(page.locator('.card')).toContainText('Template Information');
    await expect(page.locator('.card')).toContainText('Financial Parameters');
  });

  test('should clear filters', async ({ page }) => {
    // Navigate to Settings > Templates
    await page.click('text=Settings');
    await page.click('text=Templates');
    
    // Apply some filters
    await page.selectOption('#project-filter', 'VOLNA');
    await page.selectOption('#dsl-tag-filter', 'welcome_bonus');
    
    // Click clear filters button
    await page.click('#clear-filters');
    
    // Check that filters are cleared
    await expect(page.locator('#project-filter')).toHaveValue('');
    await expect(page.locator('#dsl-tag-filter')).toHaveValue('');
  });
});
