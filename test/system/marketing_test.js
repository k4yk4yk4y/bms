// Marketing System Tests with Playwright

const { test, expect } = require('@playwright/test');

// Базовый URL приложения
const BASE_URL = 'http://localhost:3000';

test.describe('Marketing Section', () => {
  test.beforeEach(async ({ page }) => {
    // Переходим на главную страницу
    await page.goto(BASE_URL);
  });

  test('should navigate to Marketing section from main menu', async ({ page }) => {
    // Проверяем наличие пункта Marketing в навигации
    const marketingLink = page.locator('a[href="/marketing"]');
    await expect(marketingLink).toBeVisible();
    
    // Кликаем на Marketing
    await marketingLink.click();
    
    // Проверяем, что перешли на страницу Marketing
    await expect(page).toHaveURL(/.*\/marketing/);
    await expect(page.locator('h1')).toContainText('Marketing');
  });

  test('should display tabs for different request types', async ({ page }) => {
    await page.goto(`${BASE_URL}/marketing`);
    
    // Проверяем наличие всех табов
    const expectedTabs = [
      'ПРОМО ВЕБОВ 50',
      'ПРОМО ВЕБОВ 100', 
      'ПРОМО БЕЗ ССЫЛКИ 50',
      'ПРОМО БЕЗ ССЫЛКИ 100',
      'ПРОМО БЕЗ ССЫЛКИ 125',
      'ПРОМО БЕЗ ССЫЛКИ 150',
      'ДЕПОЗИТНЫЕ БОНУСЫ ОТ ПАРТНЁРОВ'
    ];

    for (const tabText of expectedTabs) {
      await expect(page.locator('.nav-tabs').locator('a', { hasText: tabText })).toBeVisible();
    }
  });

  test('should switch between tabs', async ({ page }) => {
    await page.goto(`${BASE_URL}/marketing`);
    
    // Кликаем на второй таб
    await page.locator('.nav-tabs a').nth(1).click();
    
    // Проверяем, что URL изменился
    await expect(page).toHaveURL(/.*tab=promo_webs_100/);
    
    // Проверяем, что активный таб изменился
    await expect(page.locator('.nav-tabs a.active')).toContainText('ПРОМО ВЕБОВ 100');
  });

  test('should display marketing requests table', async ({ page }) => {
    await page.goto(`${BASE_URL}/marketing`);
    
    // Проверяем наличие таблицы
    await expect(page.locator('table')).toBeVisible();
    
    // Проверяем заголовки таблицы
    const headers = ['Менеджер', 'Площадка', 'Почта партнёра', 'Промокод', 'STAG', 'Дата активации', 'Статус', 'Действия'];
    for (const header of headers) {
      await expect(page.locator('th', { hasText: header })).toBeVisible();
    }
  });

  test('should filter requests by status', async ({ page }) => {
    await page.goto(`${BASE_URL}/marketing`);
    
    // Проверяем наличие кнопок фильтрации
    await expect(page.locator('a', { hasText: 'Все' })).toBeVisible();
    await expect(page.locator('a', { hasText: 'Ожидают' })).toBeVisible();
    await expect(page.locator('a', { hasText: 'Активированы' })).toBeVisible();
    await expect(page.locator('a', { hasText: 'Отклонены' })).toBeVisible();
    
    // Кликаем на фильтр "Ожидают"
    await page.locator('a', { hasText: 'Ожидают' }).click();
    
    // Проверяем, что URL содержит фильтр статуса
    await expect(page).toHaveURL(/.*status=pending/);
  });

  test('should open new request form', async ({ page }) => {
    await page.goto(`${BASE_URL}/marketing`);
    
    // Кликаем на кнопку "Добавить заявку"
    await page.locator('a', { hasText: 'Добавить заявку' }).click();
    
    // Проверяем, что перешли на страницу создания заявки
    await expect(page).toHaveURL(/.*\/marketing\/new/);
    await expect(page.locator('h1')).toContainText('Новая заявка');
    
    // Проверяем наличие формы
    await expect(page.locator('form')).toBeVisible();
    
    // Проверяем основные поля формы
    await expect(page.locator('select[name="marketing_request[request_type]"]')).toBeVisible();
    await expect(page.locator('input[name="marketing_request[manager]"]')).toBeVisible();
    await expect(page.locator('input[name="marketing_request[partner_email]"]')).toBeVisible();
    await expect(page.locator('input[name="marketing_request[promo_code]"]')).toBeVisible();
    await expect(page.locator('input[name="marketing_request[stag]"]')).toBeVisible();
  });

  test('should create new marketing request', async ({ page }) => {
    await page.goto(`${BASE_URL}/marketing/new`);
    
    // Заполняем форму
    await page.selectOption('select[name="marketing_request[request_type]"]', 'promo_webs_50');
    await page.fill('input[name="marketing_request[manager]"]', 'Тестовый менеджер');
    await page.fill('textarea[name="marketing_request[platform]"]', 'https://test-platform.com');
    await page.fill('input[name="marketing_request[partner_email]"]', 'test@partner.com');
    await page.fill('input[name="marketing_request[promo_code]"]', 'testpromo123');
    await page.fill('input[name="marketing_request[stag]"]', 'test_stag_unique');
    
    // Отправляем форму
    await page.click('input[type="submit"]');
    
    // Проверяем, что вернулись на главную страницу и есть сообщение об успехе
    await expect(page).toHaveURL(/.*\/marketing/);
    await expect(page.locator('.alert-success')).toContainText('успешно создана');
  });

  test('should validate promo code uniqueness', async ({ page }) => {
    await page.goto(`${BASE_URL}/marketing/new`);
    
    // Заполняем форму с существующим промокодом
    await page.selectOption('select[name="marketing_request[request_type]"]', 'promo_webs_50');
    await page.fill('input[name="marketing_request[manager]"]', 'Тестовый менеджер');
    await page.fill('input[name="marketing_request[partner_email]"]', 'test@partner.com');
    await page.fill('input[name="marketing_request[promo_code]"]', 'PROMO_WEBS_50_00'); // Существующий код из тестовых данных
    await page.fill('input[name="marketing_request[stag]"]', 'unique_test_stag_new');
    
    // Отправляем форму
    await page.click('input[type="submit"]');
    
    // Проверяем, что появилась ошибка валидации
    await expect(page.locator('.alert-danger')).toBeVisible();
  });

  test('should convert promo code to uppercase automatically', async ({ page }) => {
    await page.goto(`${BASE_URL}/marketing/new`);
    
    // Вводим промокод в нижнем регистре
    const promoCodeInput = page.locator('input[name="marketing_request[promo_code]"]');
    await promoCodeInput.fill('lowercase_promo');
    
    // Проверяем, что значение преобразовалось в верхний регистр
    await expect(promoCodeInput).toHaveValue('LOWERCASE_PROMO');
  });

  test('should view individual marketing request', async ({ page }) => {
    await page.goto(`${BASE_URL}/marketing`);
    
    // Кликаем на кнопку просмотра первой заявки
    await page.locator('a[title="Просмотр"]').first().click();
    
    // Проверяем, что перешли на страницу просмотра
    await expect(page).toHaveURL(/.*\/marketing\/\d+/);
    await expect(page.locator('h1')).toContainText('Заявка #');
    
    // Проверяем наличие основных элементов
    await expect(page.locator('.card-body')).toBeVisible();
    await expect(page.locator('button', { hasText: 'Скопировать' })).toBeVisible();
  });

  test('should edit marketing request', async ({ page }) => {
    await page.goto(`${BASE_URL}/marketing`);
    
    // Кликаем на кнопку редактирования первой заявки
    await page.locator('a[title="Редактировать"]').first().click();
    
    // Проверяем, что перешли на страницу редактирования
    await expect(page).toHaveURL(/.*\/marketing\/\d+\/edit/);
    await expect(page.locator('h1')).toContainText('Редактирование заявки');
    
    // Изменяем менеджера
    await page.fill('input[name="marketing_request[manager]"]', 'Обновленный менеджер');
    
    // Сохраняем изменения
    await page.click('input[type="submit"]');
    
    // Проверяем, что вернулись на главную страницу с сообщением об успехе
    await expect(page).toHaveURL(/.*\/marketing/);
    await expect(page.locator('.alert-success')).toContainText('успешно обновлена');
  });

  test('should activate pending request', async ({ page }) => {
    await page.goto(`${BASE_URL}/marketing`);
    
    // Находим заявку со статусом "Ожидает" и активируем ее
    const pendingRow = page.locator('tr', { has: page.locator('.badge.bg-warning') }).first();
    
    if (await pendingRow.count() > 0) {
      await pendingRow.locator('a[title="Активировать"]').click();
      
      // Подтверждаем действие
      await page.on('dialog', dialog => dialog.accept());
      
      // Проверяем сообщение об успехе
      await expect(page.locator('.alert-success')).toContainText('активирована');
    }
  });

  test('should reject pending request', async ({ page }) => {
    await page.goto(`${BASE_URL}/marketing`);
    
    // Находим заявку со статусом "Ожидает" и отклоняем ее
    const pendingRow = page.locator('tr', { has: page.locator('.badge.bg-warning') }).first();
    
    if (await pendingRow.count() > 0) {
      await pendingRow.locator('a[title="Отклонить"]').click();
      
      // Подтверждаем действие
      await page.on('dialog', dialog => dialog.accept());
      
      // Проверяем сообщение об успехе
      await expect(page.locator('.alert-success')).toContainText('отклонена');
    }
  });

  test('should delete marketing request', async ({ page }) => {
    await page.goto(`${BASE_URL}/marketing`);
    
    // Получаем количество строк до удаления
    const rowCountBefore = await page.locator('tbody tr').count();
    
    if (rowCountBefore > 0) {
      // Кликаем на кнопку удаления последней заявки
      await page.locator('a[title="Удалить"]').last().click();
      
      // Подтверждаем удаление
      await page.on('dialog', dialog => dialog.accept());
      
      // Проверяем сообщение об успехе
      await expect(page.locator('.alert-success')).toContainText('успешно удалена');
    }
  });

  test('should handle empty state correctly', async ({ page }) => {
    // Очищаем данные
    await page.goto(`${BASE_URL}/marketing`);
    
    // Если есть данные, переходим к последнему табу, который может быть пустым
    await page.locator('.nav-tabs a').last().click();
    
    // Если таблица пуста, должно показываться сообщение
    const tableRows = await page.locator('tbody tr').count();
    if (tableRows === 0) {
      await expect(page.locator('h5', { hasText: 'Заявки не найдены' })).toBeVisible();
      await expect(page.locator('a', { hasText: 'Создать первую заявку' })).toBeVisible();
    }
  });
});

// Дополнительные тесты для responsive design
test.describe('Marketing Responsive Design', () => {
  test('should work on mobile viewport', async ({ page }) => {
    // Устанавливаем мобильный viewport
    await page.setViewportSize({ width: 375, height: 667 });
    
    await page.goto(`${BASE_URL}/marketing`);
    
    // Проверяем, что интерфейс адаптируется под мобильные устройства
    await expect(page.locator('.container-fluid')).toBeVisible();
    await expect(page.locator('.nav-tabs')).toBeVisible();
    
    // Проверяем, что таблица остается читаемой
    await expect(page.locator('.table-responsive')).toBeVisible();
  });
});
