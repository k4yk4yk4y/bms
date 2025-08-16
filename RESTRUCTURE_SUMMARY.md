# Реструктуризация системы бонусов

## Что было изменено

### Концептуальные изменения

1. **Разделение на события и типы наград**:
   - **Раньше**: Каждый тип события имел свою таблицу (deposit_bonuses, input_coupon_bonuses, etc.)
   - **Теперь**: События (`event`) определяют когда активируется бонус, а типы наград определяют что получает пользователь

2. **Новая логика**:
   - Пользователь выбирает **событие** (deposit, input_coupon, manual, collection, groups_update, scheduler)
   - Затем добавляет любое количество **типов наград** (bonus, freespins, bonus_buy, freechips, bonus_code, material_prize, comp_points)

### Структурные изменения

#### Удаленные таблицы
- `deposit_bonuses`
- `input_coupon_bonuses`
- `manual_bonuses`
- `collect_bonuses`
- `groups_update_bonuses`
- `scheduler_bonuses`

#### Добавленные таблицы
- `bonus_rewards` - денежные бонусы (фиксированные или процентные)
- `freespin_rewards` - бесплатные вращения
- `bonus_buy_rewards` - бонусы на покупку функций
- `freechip_rewards` - бесплатные фишки
- `bonus_code_rewards` - бонусные коды
- `material_prize_rewards` - материальные призы
- `comp_point_rewards` - компенсационные очки

#### Изменения в таблице bonuses
- Добавлено поле `event` (заменяет `bonus_type`)
- Удалено поле `bonus_type`

### Модели

#### Новые модели наград
- `BonusReward`
- `FreespinReward`
- `BonusBuyReward`
- `FreechipReward`
- `BonusCodeReward`
- `MaterialPrizeReward`
- `CompPointReward`

#### Обновленная модель Bonus
- Добавлены ассоциации с новыми типами наград
- Убраны старые ассоциации событий
- Добавлены методы:
  - `all_rewards` - все награды бонуса
  - `has_rewards?` - проверка наличия наград
  - `reward_types` - типы наград бонуса

### Преимущества новой структуры

1. **Гибкость**: Один бонус может содержать несколько типов наград
2. **Масштабируемость**: Легко добавлять новые типы наград
3. **Логичность**: Четкое разделение между событиями активации и наградами
4. **Простота**: Унифицированная структура для всех типов наград

### Пример использования

```ruby
# Создание бонуса на депозит с несколькими наградами
bonus = Bonus.create!(
  name: "Welcome Bonus",
  event: "deposit",  # событие активации
  # ... другие поля
)

# Добавление денежного бонуса
bonus.bonus_rewards.create!(
  reward_type: "cash",
  amount: 100
)

# Добавление фриспинов
bonus.freespin_rewards.create!(
  spins_count: 50,
  game_restrictions: "slots_only"
)

# Добавление comp points
bonus.comp_point_rewards.create!(
  points_amount: 1000
)

# Проверка
puts bonus.reward_types
# => ["bonus", "freespins", "comp_points"]
```

### Совместимость

- Все существующие данные были сохранены (поле `event` заполнено на основе старого `bonus_type`)
- Добавлен deprecated метод `type_specific_record` для обратной совместимости
- Миграция содержит возможность отката (rollback)

## Исправления после реструктуризации

### Исправленная ошибка
После реструктуризации возникла ошибка:
```
Association named 'deposit_bonus' was not found on Bonus; perhaps you misspelled it?
```

### Что было исправлено

1. **Контроллер BonusesController**:
   - Заменены старые `includes(:deposit_bonus, ...)` на новые `includes(:bonus_rewards, ...)`
   - Заменен `by_type` на `by_event`
   - Обновлены параметры с `bonus_type` на `event`
   - Упрощены методы создания и обновления
   - Удалены методы старой архитектуры

2. **Представления (Views)**:
   - `index.html.erb`: заменен `bonus.bonus_type` на `bonus.event`
   - `show.html.erb`: обновлены все ссылки на `bonus_type`
   - `edit.html.erb`: изменены поля и метки с `bonus_type` на `event`
   - `new.html.erb`: обновлены формы и JavaScript
   - Полностью переписаны партиалы `_type_specific_form.html.erb` и `_type_specific_details.html.erb`

3. **Хелперы**:
   - Добавлен новый метод `event_type_options`
   - Сохранен старый `bonus_type_options` для совместимости

### Результат
- ✅ Приложение запускается без ошибок
- ✅ Страницы загружаются корректно
- ✅ Новые бонусы создаются с полем `event`
- ✅ Система наград работает правильно
- ✅ Все методы модели функционируют

### Тестирование
```ruby
# Создание бонуса с новой структурой
bonus = Bonus.create!(
  name: "Test Fixed Bonus",
  event: "deposit",  # новое поле
  # ... другие параметры
)

# Добавление наград
bonus.bonus_rewards.create!(reward_type: "cash", amount: 50)
bonus.freespin_rewards.create!(spins_count: 25)

# Проверка
bonus.has_rewards?     # => true
bonus.reward_types     # => ["bonus", "freespins"]
bonus.all_rewards.count # => 2
```
