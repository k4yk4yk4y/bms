const { test, expect } = require('@playwright/test');

test.describe('Template Priority and All Projects Functionality', () => {
  test('should test template API endpoint with specific project template', async ({ page }) => {
    // Test the find_template API endpoint with specific project
    const response = await page.request.get('/bonuses/find_template?dsl_tag=welcome_bonus&name=VOLNA Welcome Bonus&project=VOLNA');
    
    expect(response.status()).toBe(200);
    const data = await response.json();
    expect(data.template).toBeDefined();
    expect(data.found_by).toBe('Project: VOLNA');
    expect(data.template.project).toBe('VOLNA');
  });

  test('should test template API endpoint with "All" fallback', async ({ page }) => {
    // Test the find_template API endpoint with non-existent specific project
    const response = await page.request.get('/bonuses/find_template?dsl_tag=welcome_bonus&name=Universal Welcome Bonus&project=ROX');
    
    expect(response.status()).toBe(200);
    const data = await response.json();
    expect(data.template).toBeDefined();
    expect(data.found_by).toBe('All projects');
    expect(data.template.project).toBe('All');
  });

  test('should test template API endpoint without project parameter', async ({ page }) => {
    // Test the find_template API endpoint without project parameter
    const response = await page.request.get('/bonuses/find_template?dsl_tag=welcome_bonus&name=Universal Welcome Bonus');
    
    expect(response.status()).toBe(200);
    const data = await response.json();
    expect(data.template).toBeDefined();
    expect(data.found_by).toBe('All projects');
    expect(data.template.project).toBe('All');
  });

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

  test('should verify template priority logic', async ({ page }) => {
    // Test that specific project template takes priority over "All" template
    const response1 = await page.request.get('/bonuses/find_template?dsl_tag=welcome_bonus&name=VOLNA Welcome Bonus&project=VOLNA');
    const data1 = await response1.json();
    
    const response2 = await page.request.get('/bonuses/find_template?dsl_tag=welcome_bonus&name=Universal Welcome Bonus&project=VOLNA');
    const data2 = await response2.json();
    
    // The first should find the VOLNA-specific template
    expect(data1.found_by).toBe('Project: VOLNA');
    expect(data1.template.project).toBe('VOLNA');
    
    // The second should find the "All" template since there's no VOLNA-specific template with that name
    expect(data2.found_by).toBe('All projects');
    expect(data2.template.project).toBe('All');
  });

  test('should test template API with different dsl_tags', async ({ page }) => {
    // Test with different dsl_tag to ensure the logic works correctly
    const response = await page.request.get('/bonuses/find_template?dsl_tag=welcome_bonus&name=Universal Welcome Bonus&project=ROX');
    
    expect(response.status()).toBe(200);
    const data = await response.json();
    expect(data.template).toBeDefined();
    expect(data.found_by).toBe('All projects');
    expect(data.template.project).toBe('All');
  });

  test('should test template API with exact name match', async ({ page }) => {
    // Test exact name matching
    const response = await page.request.get('/bonuses/find_template?dsl_tag=welcome_bonus&name=Universal Welcome Bonus&project=All');
    
    expect(response.status()).toBe(200);
    const data = await response.json();
    expect(data.template).toBeDefined();
    expect(data.found_by).toBe('All projects');
    expect(data.template.name).toBe('Universal Welcome Bonus');
  });
});
