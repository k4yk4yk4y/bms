const { chromium } = require('@playwright/test');
const fs = require('fs');
const path = require('path');

module.exports = async () => {
  const baseURL = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:3000';
  const email = process.env.PW_EMAIL || 'playwright@example.com';
  const password = process.env.PW_PASSWORD || 'Password123!';
  const authDir = path.join(__dirname, '.auth');
  const authFile = path.join(authDir, 'user.json');

  fs.mkdirSync(authDir, { recursive: true });

  const browser = await chromium.launch();
  const page = await browser.newPage();

  await page.goto(`${baseURL}/users/sign_in`);
  await page.fill('input[name="user[email]"]', email);
  await page.fill('input[name="user[password]"]', password);
  await page.click('input[type="submit"]');
  await page.waitForURL(/\/bonuses/);

  await page.context().storageState({ path: authFile });
  await browser.close();
};
