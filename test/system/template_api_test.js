const { test, expect } = require('@playwright/test');

test.describe('Template API Functionality', () => {
  test('should test template API endpoint with missing parameters', async ({ page }) => {
    // Test the find_template API endpoint with missing dsl_tag
    const response = await page.request.get('/bonuses/find_template?name=Universal Welcome Bonus');
    
    expect(response.status()).toBe(400);
    const data = await response.json();
    expect(data.error).toBe('dsl_tag and name are required');
  });

  test('should test template API endpoint with non-existent template', async ({ page }) => {
    // Test the find_template API endpoint with non-existent template
    const response = await page.request.get('/bonuses/find_template?dsl_tag=nonexistent&name=NonExistent Template');
    
    expect(response.status()).toBe(404);
    const data = await response.json();
    expect(data.error).toBe('Template not found');
  });

  test('should test template API endpoint with valid parameters', async ({ page }) => {
    // Test the find_template API endpoint with valid parameters
    const response = await page.request.get('/bonuses/find_template?dsl_tag=test&name=test');
    
    // Should return 404 since no such template exists, but API should work
    expect(response.status()).toBe(404);
    const data = await response.json();
    expect(data.error).toBe('Template not found');
  });
});
