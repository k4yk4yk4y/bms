# BMS — полная спецификация проекта (RU)

**Версия:** 1.0  
**Дата:** 2025-01-27  
**Приложение:** Casino Bonus Management System (BMS)

---

## 1) Назначение и границы
BMS — система управления бонусами казино, содержащая веб‑интерфейс, REST API и административную панель ActiveAdmin. Система покрывает полный цикл жизни бонусов, наград, маркетинговых заявок и retention‑цепочек.

В документе описаны все разделы UI, все поля и их валидации, бизнес‑правила и доступы.

---

## 2) Роли и доступы

### 2.1 Пользовательские роли (User)
Роли определяются `User.role` и расширяются настройками `Role.permissions`.

**Доступы по умолчанию (Role::DEFAULT_PERMISSIONS):**
- **admin**: полный доступ ко всем разделам; `admin_panel_access: true`.
- **promo_manager**: чтение бонусов/retention, доступ к своему профилю.
- **shift_leader**: чтение бонусов/маркетинга/retention, доступ к профилю.
- **marketing_manager**: управление маркетингом (только свои заявки), доступ к профилю.
- **retention_manager**: управление retention, чтение бонусов, доступ к профилю.
- **support_agent**: чтение бонусов/маркетинга/retention, доступ к профилю.

**Уровни доступа:** `none`, `read`, `write`, `manage`.

### 2.2 Административные роли (AdminUser)
ActiveAdmin использует `AdminRole` с секциями:
- `dashboard`, `bonuses`, `bonus_templates`, `marketing_requests`, `bonus_audit_logs`, `dsl_tags`, `permanent_bonuses`, `projects`, `users`, `admin_users`, `roles`, `admin_roles`.

**Уровни:** `none`, `read`, `write`, `manage`.

Каждый `AdminUser` обязан иметь `admin_role`. По умолчанию назначается роль `superadmin` (если существует).

---

## 3) Навигация и общие элементы UI
- Верхнее меню: `Bonuses`, `Heatmap`, `Marketing`, `Retention`, `Projects` (фильтр по проекту), профиль пользователя.
- Пункты показываются по разрешениям CanCan (`can?`).
- `Projects` — выпадающий список проектов с фильтрацией списка бонусов.
- Профиль: доступ к `Profile` и `Sign out`.

---

## 4) Разделы Web UI

### 4.1 Аутентификация
- **User login** (`/users/sign_in`): email + password.
- Регистрация и восстановление пароля выключены.
- После входа редирект по роли:
  - marketing_manager → Marketing
  - retention_manager → Retention
  - admin/promo_manager/shift_leader/support_agent → Bonuses

### 4.2 Setup (первичный админ)
- URL: `/setup`
- Доступен, только если нет пользователей с ролью `admin`.
- Поля: `email`, `first_name`, `last_name`, `password`, `password_confirmation`.
- Валидации формы: пароль ≥ 6 символов, подтверждение совпадает.
- При наличии admin → редирект на логин.

### 4.3 Bonuses

#### 4.3.1 Список бонусов (`/bonuses`)
Фильтры:
- **Type/Event:** `deposit | input_coupon | manual | collection | groups_update | scheduler`.
- **Status:** `active | inactive | expired`.
- **Search:** по `name` или `code`.
- **Project:** по `project_id`.
- **DSL Tag:** по строке.

Действия:
- Просмотр, редактирование, дублирование, удаление.
- Массовые действия: `duplicate`, `delete`.
- Пагинация (25/стр.).

Особенности:
- При фильтрации по проекту показывается блок **Permanent Bonuses** для проекта.
- Дублирование создаёт копию со статусом `draft` и новыми датами.

#### 4.3.2 Создание/редактирование бонуса (`/bonuses/new`, `/bonuses/:id/edit`)
**Basic Information:**
- `name` (обязательное).
- `code` (опционально; длина ≤ 50, пустая строка допустима).
- `description` (до 1000 символов).
- `event` (обязательное; после создания нельзя менять).
- `status` (обязательное: `draft/active/inactive/expired`).
- `project` (по умолчанию `All`).
- `dsl_tag_id` (выбор из списка; при отсутствии — допускается строковое поле `dsl_tag`).
- `currencies` (чекбоксы; набор зависит от проекта).
- `groups` (текст, можно вводить через запятую).
- `no_more` (строковое ограничение использования).
- `totally_no_more` (целое число лимита активаций).
- `country`, `user_group`, `tags` (в редактировании).

**Currency Minimum Deposits:**
- Показано только для `event = deposit`.
- Поля по валютам `currency_minimum_deposits[CUR]`.

**Wagering Information:**
- `minimum_deposit` (используется только для депозитных событий; в non‑deposit запрещён).
- `wager` (≥ 0).
- `maximum_winnings_type` (`multiplier` | `fixed`).
- `maximum_winnings` (≥ 0).
- `wagering_strategy` (варианты: `wager`, `wager_win`, `wager_free`, `insurance_bonus`, `wager_real`).

**Availability:**
- `availability_start_date` (обязательное).
- `availability_end_date` (обязательное, строго позже старта).

#### 4.3.3 Награды (Rewards)
UI позволяет добавлять **несколько наград каждого типа**.

**Cash Bonus (BonusReward):**
- Выбор `bonus_type`: `fixed` или `percentage`.
- Если `fixed`: суммы по валютам `currency_amounts[CUR]` (обязательны).  
- Если `percentage`: поле `percentage` (0..100).
- `user_can_have_duplicates` (checkbox).
- `code`, `stag` (опц.).
- Advanced параметры в `config`:  
  `range`, `last_login_country`, `profile_country`, `current_ip_country`, `emails`, `stag`,  
  `deposit_payment_systems`, `cashout_payment_systems`, `user_can_have_disposable_email`,  
  `total_deposits`, `deposits_sum`, `loss_sum`, `deposits_count`, `spend_sum`,  
  `category_loss_sum`, `wager_sum`, `bets_count`, `affiliates_user`, `balance`,  
  `cashout`, `chargeable_comp_points`, `persistent_comp_points`, `date_of_birth`,  
  `deposit`, `gender`, `issued_bonus`, `registered`, `social_networks`, `hold_min`, `hold_max`.

**Freespin Reward:**
- `spins_count` (обяз., > 0).
- `games` (список через запятую).
- `bet_level` (>= 0).
- `deposit_percentage` (опц., процент; может быть любым числом).
- `currency_freespin_bet_levels[CUR]` — обязателен минимум один > 0.
- `code`, `stag` (опц.).
- Advanced параметры в `config`:  
  `auto_activate`, `duration`, `activation_duration`, `email_template`, `range`,  
  `last_login_country`, `profile_country`, `current_ip_country`, `emails`,  
  `deposit_payment_systems`, `cashout_payment_systems`, `user_can_have_duplicates`,  
  `user_can_have_disposable_email`, `total_deposits`, `deposits_sum`, `loss_sum`,  
  `deposits_count`, `spend_sum`, `category_loss_sum`, `wager_sum`, `bets_count`,  
  `affiliates_user`, `balance`, `chargeable_comp_points`, `persistent_comp_points`,  
  `date_of_birth`, `deposit`, `gender`, `issued_bonus`, `registered`,  
  `social_networks`, `wager_done`, `hold_min`, `hold_max`.

**Bonus Buy Reward:**
- `buy_amount` (обяз., > 0).
- `multiplier` (опц., > 0).
- `games`.
- `bet_level` (>= 0).
- `deposit_percentage` (опц., процент; может быть любым числом).
- `currency_bet_levels[CUR]` — обязателен минимум один > 0.
- `code`, `stag` (опц.).
- Advanced параметры в `config` (аналогично Freespin).

**Comp Point Reward:**
- `title` (обязательное).
- `points_amount` (обязательное, >= 0).
- `multiplier` (>= 0, опц.).
- Advanced параметры: JSON в `config_json`.

**Bonus Code Reward:**
- `title` (обязательное).
- `set_bonus_code` (обязательное).  
- `code_type` обязателен на уровне модели; по умолчанию задаётся `bonus` в массовой форме.  
- Advanced параметры: JSON в `config_json`.

**Freechip / Material Prize:**
- Модели существуют (`FreechipReward`, `MaterialPrizeReward`), но кнопок создания в UI нет.

#### 4.3.4 Детали бонуса (`/bonuses/:id`)
- Основная информация, валюты, группы, теги, проект, DSL tag.
- Минимальные депозиты по валютам (для deposit).
- Wagering информация, стратегия.
- Availability + флаги `available now` и `expired`.
- Список наград с деталями.

### 4.4 Bonus Templates (Settings)
- URL: `/settings/templates`.
- Фильтры: `project`, `dsl_tag`, `event`.
- Поля формы: `name`, `dsl_tag`, `project`, `event`, `currencies`, `currency_minimum_deposits`, `wager`, `maximum_winnings`, `no_more`, `totally_no_more`, `groups`, `description`.

### 4.5 Marketing Requests

#### 4.5.1 Список (`/marketing`)
- Вкладки по `request_type`.
- Поиск: `promo_code`, `stag`, `manager`, `partner_email`.
- Фильтр по статусу: `pending/activated/rejected`.
- Доступы: `marketing_manager` видит только свои заявки (`manager = email`).

#### 4.5.2 Создание/редактирование
Поля:
- `request_type` (обяз.).
- `platform` (опц., текст или URL).
- `partner_email` (обяз. email).
- `promo_code` (обяз., список, авто‑upper, без пробелов, только [A‑Z0‑9_]).
- `stag` (обяз., без пробелов, уникален).
- `status` (по умолчанию `pending`).
- `activation_date` (опц.; задаётся при активации).

### 4.6 Retention

#### 4.6.1 Retention Chains (`/retention`)
Фильтры:
- `project`, `launch_date` range, `bonus_code`, `subject`, `header`.

Форма:
- `name` (обязателен при `status != draft`).
- `project` (обязателен при `status != draft`).
- `status` (`draft/active/archived`).
- `launch_date` (авто при `active`).
- Автосохранение (autosave).

#### 4.6.2 Retention Emails (внутри цепочки)
Форма:
- `subject`, `header`, `preheader`, `send_timing`.
- `status` (`draft/active/archived`).
- `launch_date` (авто при `active`).
- `description`, `body`.
- `bonuses` (множественный выбор; только бонусы проекта цепочки, автокомплит).
- `images` (multiple upload, удаление по одному).
- Drag&drop сортировка писем в цепочке.

### 4.7 Heatmap (`/heatmap`)
- Фильтры: `bonus_event`, `month`, `year`.
- Данные строятся по `availability_start_date` и событиям.
- Интенсивность: `count / 10` (макс. 1.0).
- Статистика: total bonuses, active days, max/day, average/day.

### 4.8 Profile (`/users/:id`)
- Email, имя/фамилия, роль, дата создания.

---

## 5) ActiveAdmin (админ‑панель)
Разделы:
- Bonuses
- Bonus Templates
- Marketing Requests
- Bonus Audit Logs
- DSL Tags
- Projects
- Permanent Bonuses
- Users
- Admin Users
- Roles
- Admin Roles

**Особенности:**
- Массовые действия по бонусам: `activate`, `deactivate`.
- История изменений бонусов в Bonus Audit Logs.
- Управление постоянными бонусами (PermanentBonus) через админ‑панель.

---

## 6) Бизнес‑правила и системное поведение

### 6.1 Статусы бонусов
- `availability_end_date` > `availability_start_date`.
- Истёкшие активные бонусы автоматически переводятся в `inactive` при чтении (`after_find`).

### 6.2 Валюты
- Валюты задаются в Project и валидируются как ISO‑коды (3–5 символов).
- `Bonus.currencies` должны быть подмножеством валют проекта (или всех валют для `All`).
- Точность сумм по валютам: 2 знака после запятой.

### 6.3 Минимальные депозиты
- `currency_minimum_deposits` допустимы только для `event = deposit`.
- Для событий `input_coupon/manual/collection/groups_update/scheduler` минимальные депозиты запрещены.
- Значения должны быть > 0.
- Валюты должны входить в `currencies` бонуса.

### 6.4 Дублирование бонусов
- Новый бонус создаётся со статусом `draft`.
- `code` = `original_code_COPYN`, учитывается лимит 50 символов и уникальность.
- Даты: старт = сейчас, конец = через 1 год.
- Копируются все награды (bonus_rewards, freespin_rewards, bonus_buy_rewards, comp_point_rewards, bonus_code_rewards, freechip_rewards, material_prize_rewards).

### 6.5 Маркетинговые заявки
- `stag` уникален во всех заявках.
- `promo_code` уникален поштучно среди всех заявок.
- Любое изменение заявки (кроме `status/activation_date`) возвращает её в `pending`.
- Активация выставляет `activation_date`.

### 6.6 Retention
- `RetentionEmail` может быть привязан только к бонусам проекта цепочки.
- При `active` ставится `launch_date` автоматически.
- Письма сортируются по `position` и могут переставляться drag&drop.

---

## 7) API

### 7.1 Bonuses API (`/api/v1/bonuses`)
- `GET /api/v1/bonuses` — список с фильтрами:  
  `type`, `status`, `project`, `dsl_tag`, `currency`, `country`, `search`, `start_date`, `end_date`, `page`, `per_page`.
- `GET /api/v1/bonuses/:id` — детальная информация.
- `POST /api/v1/bonuses` — создание.
- `PUT/PATCH /api/v1/bonuses/:id` — обновление.
- `DELETE /api/v1/bonuses/:id` — удаление.
- `GET /api/v1/bonuses/by_type` — фильтр по `type`.
- `GET /api/v1/bonuses/active` — активные + доступные сейчас.
- `GET /api/v1/bonuses/expired` — просроченные.

### 7.2 Setup API (`/api/v1/setup`)
- `POST /api/v1/setup/create_admin` — создаёт admin, если его нет.
- `GET /api/v1/setup/admin_status` — статус наличия админов.

**Доступ:** все API‑эндпоинты требуют разрешение `:access, :api` (CanCanCan).

---

## 8) Аудит и логирование
- Все изменения бонусов пишутся в `BonusAuditLog` (`created/updated/deleted/activated/deactivated`) с IP и автором.
- История изменений доступна в ActiveAdmin.

---

## 9) Ограничения и заметки
- `BonusCodeReward` требует `code_type` на уровне модели; в UI подразумевается значение по умолчанию `bonus`.
- Freechip/Material Prize награды доступны на уровне моделей и API, но не через основной UI.
- Валидации и ограничения в UI не отменяют серверные проверки.

---

**Конец документа**
