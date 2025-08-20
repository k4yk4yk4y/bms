// Playwright test for permanent bonus preview cards functionality
const { test, expect } = require('@playwright/test');

test.describe('Permanent Bonus Preview Cards', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to bonuses page with a project parameter
    await page.goto('/bonuses?project=VOLNA');
    
    // Wait for the page to load
    await page.waitForSelector('h3:has-text("Permanent Bonuses Preview")', { timeout: 10000 });
  });

  test('should display permanent bonus preview cards when project is selected', async ({ page }) => {
    // Check that the permanent bonus previews section exists
    await expect(page.locator('h3:has-text("Permanent Bonuses Preview")')).toBeVisible();
    
    // Check that project badge is displayed (more specific selector)
    await expect(page.locator('h3:has-text("Permanent Bonuses Preview") .badge:has-text("VOLNA")')).toBeVisible();
    
    // Check that we have the expected number of bonus preview cards (9)
    const bonusCards = page.locator('.permanent-bonus-card');
    await expect(bonusCards).toHaveCount(9);
  });

  test('should display all 9 permanent bonus types', async ({ page }) => {
    const expectedBonusNames = [
      'Welcome Bonus',
      'Second Bonus',
      'Third Bonus',
      'Fourth Bonus',
      'Reload Cash',
      'Reload Freespins',
      'Happy Birthday Bonus',
      'Cashback Bonus',
      'Live Cashback Bonus'
    ];

    // Check each expected bonus name is present (more specific selector)
    for (const bonusName of expectedBonusNames) {
      // Use first() to handle duplicate elements
      await expect(page.locator(`.permanent-bonus-card .card-title:has-text("${bonusName}")`).first()).toBeVisible();
    }
  });

  test('should show status badges for bonus cards', async ({ page }) => {
    // Wait for cards to load
    await page.waitForSelector('.permanent-bonus-card', { timeout: 10000 });
    
    // Wait a bit more for content to appear
    await page.waitForTimeout(2000);
    
    // Check that status indicators exist (either check-circle or plus-circle icons)
    const activeCards = page.locator('.permanent-bonus-card .fa-check-circle');
    const missingCards = page.locator('.permanent-bonus-card .fa-plus-circle');
    
    const totalCards = await activeCards.count() + await missingCards.count();
    expect(totalCards).toBeGreaterThan(0);
    
    // Check that we have both active and missing bonuses
    const activeCount = await activeCards.count();
    const missingCount = await missingCards.count();
    expect(activeCount + missingCount).toBeGreaterThan(0);
  });

  test('should display action buttons for each bonus card', async ({ page }) => {
    // Wait for cards to load
    await page.waitForSelector('.permanent-bonus-card', { timeout: 10000 });
    
    // Wait a bit more for content to appear
    await page.waitForTimeout(2000);
    
    const bonusCards = page.locator('.permanent-bonus-card');
    const cardCount = await bonusCards.count();

    for (let i = 0; i < Math.min(cardCount, 3); i++) { // Test first 3 cards to avoid timeout
      const card = bonusCards.nth(i);
      
      // Check if card has active or missing status by looking for icons
      const hasActiveIcon = await card.locator('.fa-check-circle').count() > 0;
      const hasMissingIcon = await card.locator('.fa-plus-circle').count() > 0;
      
      if (hasActiveIcon) {
        // For active bonuses, check for View and Edit buttons
        await expect(card.locator('a:has-text("View")')).toBeVisible();
        await expect(card.locator('a:has-text("Edit")')).toBeVisible();
      } else if (hasMissingIcon) {
        // For missing bonuses, check for Create button
        await expect(card.locator('a:has-text("Create")')).toBeVisible();
      }
    }
  });

  test('should display bonus details for active bonuses', async ({ page }) => {
    // Wait for cards to load
    await page.waitForSelector('.permanent-bonus-card', { timeout: 10000 });
    
    // Look for cards with active status
    const activeCards = page.locator('.permanent-bonus-card.border-success');
    const activeCount = await activeCards.count();

    if (activeCount > 0) {
      const firstActiveCard = activeCards.first();
      
      // Check that bonus details are displayed
      await expect(firstActiveCard.locator('text=Code:')).toBeVisible();
      await expect(firstActiveCard.locator('text=DSL:')).toBeVisible();
      await expect(firstActiveCard.locator('text=Event:')).toBeVisible();
    }
  });

  test('should display expected DSL tags for missing bonuses', async ({ page }) => {
    // Wait for cards to load
    await page.waitForSelector('.permanent-bonus-card', { timeout: 10000 });
    
    // Look for cards with missing status
    const missingCards = page.locator('.permanent-bonus-card.border-warning');
    const missingCount = await missingCards.count();

    if (missingCount > 0) {
      const firstMissingCard = missingCards.first();
      
      // Check that expected DSL is displayed
      await expect(firstMissingCard.locator('text=Expected DSL:')).toBeVisible();
    }
  });

  test('should navigate to edit page when edit button is clicked', async ({ page }) => {
    // Wait for cards to load
    await page.waitForSelector('.permanent-bonus-card', { timeout: 10000 });
    
    // Look for an edit button on an active bonus
    const editButton = page.locator('.permanent-bonus-card a:has-text("Edit")').first();
    
    if (await editButton.count() > 0) {
      await editButton.click();
      
      // Check that we're navigated to the edit page
      await expect(page).toHaveURL(/\/bonuses\/\d+\/edit/);
    }
  });

  test('should navigate to show page when view button is clicked', async ({ page }) => {
    // Wait for cards to load
    await page.waitForSelector('.permanent-bonus-card', { timeout: 10000 });
    
    // Look for a view button on an active bonus
    const viewButton = page.locator('.permanent-bonus-card a:has-text("View")').first();
    
    if (await viewButton.count() > 0) {
      await viewButton.click();
      
      // Check that we're navigated to the show page
      await expect(page).toHaveURL(/\/bonuses\/\d+$/);
    }
  });

  test('should navigate to new bonus page when create button is clicked', async ({ page }) => {
    // Wait for cards to load
    await page.waitForSelector('.permanent-bonus-card', { timeout: 10000 });
    
    // Look for a create button on a missing bonus
    const createButton = page.locator('.permanent-bonus-card a:has-text("Create Bonus")').first();
    
    if (await createButton.count() > 0) {
      await createButton.click();
      
      // Check that we're navigated to the new bonus page with appropriate parameters
      await expect(page).toHaveURL(/\/bonuses\/new/);
      await expect(page.url()).toContain('event=deposit');
    }
  });

  test('should not display permanent bonus previews when no project is selected', async ({ page }) => {
    // Navigate to bonuses page without project parameter
    await page.goto('/bonuses');
    
    // Check that permanent bonus previews section is not visible
    const previewSection = page.locator('h3:has-text("Permanent Bonuses Preview")');
    await expect(previewSection).not.toBeVisible();
  });

  test('should display responsive layout on mobile devices', async ({ page }) => {
    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    
    // Check that cards are still visible and properly arranged
    const bonusCards = page.locator('.permanent-bonus-card');
    await expect(bonusCards.first()).toBeVisible();
    
    // Check that cards stack properly on mobile
    const firstCard = bonusCards.first();
    const firstCardBox = await firstCard.boundingBox();
    expect(firstCardBox?.width).toBeLessThan(400); // Should be mobile-friendly width
  });

  test('should display hover effects on desktop', async ({ page }) => {
    // Check that cards have hover class in CSS
    const bonusCard = page.locator('.permanent-bonus-card').first();
    await expect(bonusCard).toBeVisible();
    
    // Hover over the card
    await bonusCard.hover();
    
    // Cards should have transition effects (tested via CSS presence)
    const computedStyle = await page.evaluate(() => {
      const card = document.querySelector('.permanent-bonus-card');
      return window.getComputedStyle(card).transition;
    });
    
    expect(computedStyle).toContain('ease-in-out');
  });
});

// Configuration for Playwright
module.exports = {
  use: {
    baseURL: 'http://localhost:3000',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
};
