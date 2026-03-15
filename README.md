# BMS (Bonus Management System)

Актуальная версия README для текущего состояния проекта (schema version: `2026_03_15_180000`).

## О проекте

BMS - Rails-приложение для управления бонусами казино с веб-интерфейсом, ActiveAdmin, REST API и модульной ролевой моделью доступа.

Ключевые разделы продукта:
- Bonuses (бонусы и rewards)
- Heatmap (календарная аналитика бонусов)
- Marketing Requests
- Retention (цепочки и письма)
- SMM (месяцы, проекты, бонусы, пресеты)
- Settings -> Bonus Templates
- ActiveAdmin (админ-панель)

## Технологический стек

- Ruby `3.4.6` (`.ruby-version`)
- Rails `8.0.2.1` (по `Gemfile.lock`, gem constraint `~> 8.0.2`)
- PostgreSQL
- Devise + CanCanCan
- ActiveAdmin `3.3`
- Hotwire (Turbo + Stimulus), Importmap
- Sprockets + Sass
- Solid Queue / Solid Cache / Solid Cable
- RSpec + Minitest + Playwright

## Быстрый старт (локально)

### 1. Требования

- Ruby `3.4.6`
- PostgreSQL (локально запущенный сервер)
- Node.js + npm (для Playwright/ESLint)

### 2. Установка

```bash
bundle install
npm install
bin/setup
```

`bin/setup` устанавливает gem-зависимости, выполняет `db:prepare`, чистит `log/tmp` и запускает сервер.

### 3. Ручной запуск (если нужен контроль по шагам)

```bash
bundle install
npm install
bin/rails db:prepare
bin/rails db:seed
bin/dev
```

Приложение поднимется на `http://localhost:3000`.

### 4. Логин после `db:seed`

Seed создает тестовые аккаунты, например:
- `admin@bms.com / password123`
- `marketing@bms.com / password123`

Также в development seed создает `AdminUser`:
- `admin@example.com / password`

## Роли и доступы

Роли `User`:
- `admin`
- `promo_manager`
- `shift_leader`
- `support_agent`
- `marketing_manager`
- `retention_manager`
- `smm_manager`
- `delivery_manager`

Фактические доступы управляются через таблицу `roles` (`Role.permissions`) и `Ability`.
Для ActiveAdmin используется отдельная модель `AdminUser` и роли `AdminRole`.

## Основные URL

- `/users/sign_in` - вход пользователей
- `/bonuses` - бонусы
- `/heatmap` - тепловая карта
- `/marketing` - маркетинговые заявки
- `/retention` - retention-цепочки
- `/smm` - SMM-месяцы
- `/settings/templates` - шаблоны бонусов
- `/admin` - ActiveAdmin
- `/up` - healthcheck
- `/setup` - первичная настройка админа

## API

Базовый префикс: `/api/v1`.

Основные endpoints:
- `GET /api/v1/bonuses`
- `GET /api/v1/bonuses/:id`
- `POST /api/v1/bonuses`
- `PATCH /api/v1/bonuses/:id`
- `DELETE /api/v1/bonuses/:id`
- `GET /api/v1/bonuses/by_type`
- `GET /api/v1/bonuses/active`
- `GET /api/v1/bonuses/expired`
- `POST /api/v1/setup/create_admin`
- `GET /api/v1/setup/admin_status`

API авторизуется через текущую сессию и CanCanCan-права (`:api` section в `Role.permissions`).

## Полезные Rake-задачи

```bash
bundle exec rake -T
```

Часто используемые:
- `rake roles:sync`
- `rake admin_roles:sync`
- `rake seed:deploy_data`
- `rake admin:create_default`
- `rake bonus_system:analyze`
- `rake heatmap:create_test_data`
- `rake marketing:create_test_data`

## Тесты и качество

```bash
# RSpec
bundle exec rspec

# Minitest (включая system tests)
bin/rails test test:system

# Playwright UI tests (JS)
npx playwright test

# Линт и security
bin/rubocop
bin/brakeman
bin/importmap audit
```

CI (`.github/workflows/ci.yml`) запускает Brakeman, importmap audit, RuboCop, Minitest и RSpec.

## Docker / Deploy

### Docker Compose (production-like)

Файл `docker-compose.yml` поднимает:
- `db` (`postgres:18.3-bookworm`)
- `app` (Rails в production)

Минимально нужны переменные:
- `POSTGRES_PASSWORD`
- `RAILS_MASTER_KEY`

### Kamal

Есть базовый шаблон в `config/deploy.yml` (нужно заполнить своими серверами/registry/доменом).

### Render

Есть `render.yaml` и `bin/render-build.sh`.

## Структура проекта (кратко)

- `app/models` - доменные модели (Bonus, Reward-модели, Role/AdminRole, Marketing, Retention, SMM)
- `app/controllers` - web + API контроллеры
- `app/admin` - ресурсы ActiveAdmin
- `app/javascript/controllers` - Stimulus-контроллеры
- `lib/tasks` - rake-задачи сидирования, синхронизации ролей и утилиты
- `db/migrate`, `db/schema.rb` - миграции и актуальная схема

## Дополнительная документация

- `DOCUMENTATION_RU.md` - полная спецификация UI/API/правил (детально)
- `DEPLOY_DOCKER_RU.md` - развертывание через Docker
- `APP_CONSTITUTION.md` - архитектурное описание

## Важные замечания по безопасности

- Перед production обязательно заменить дефолтные пароли/учетки из seed и rake-задач.
- Не хранить реальные секреты (`RAILS_MASTER_KEY`, пароли, токены) в репозитории.
