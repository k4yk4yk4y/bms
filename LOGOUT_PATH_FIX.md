# Исправление ошибки logout_path в ActiveAdmin

## Проблема
При переходе в админ-панель возникала ошибка:
```
NoMethodError: undefined method 'destroy_admin_user_session_path' for an instance of ActiveAdmin::Views::MenuItem
```

## Причина
ActiveAdmin по умолчанию настроен для работы с моделью `AdminUser`, но мы настроили его для использования обычной модели `User`. В конфигурации ActiveAdmin оставались ссылки на маршруты `admin_user`, которые не существуют.

## Решение

### 1. Исправление конфигурации logout_link_path
В файле `config/initializers/active_admin.rb`:

```ruby
# Было:
config.logout_link_path = :destroy_admin_user_session_path

# Стало:
config.logout_link_path = :destroy_user_session_path
config.logout_link_method = :delete
```

### 2. Обновление layout
В файле `app/views/layouts/active_admin.html.erb`:

```erb
<!-- Было: -->
<%= link_to "Logout", "/users/sign_out", method: :delete %>

<!-- Стало: -->
<%= link_to "Logout", destroy_user_session_path, method: :delete %>
```

### 3. Проверка маршрутов
Команда `rails routes | grep session` показывает доступные маршруты:

```
new_user_session GET    /admin/login(.:format)     active_admin/devise/sessions#new
user_session POST       /admin/login(.:format)     active_admin/devise/sessions#create
destroy_user_session DELETE|GET /admin/logout(.:format) active_admin/devise/sessions#destroy
```

## Результат
Теперь ActiveAdmin корректно использует маршруты для модели `User`:
- ✅ Вход через `/admin/login`
- ✅ Выход через `/admin/logout`
- ✅ Корректная работа ссылки "Logout" в админ-панели

## Измененные файлы:
1. `config/initializers/active_admin.rb` - исправлен logout_link_path
2. `app/views/layouts/active_admin.html.erb` - обновлена ссылка logout

## Тестирование
Админ-панель теперь доступна по адресу http://localhost:3000/admin с корректной функциональностью входа и выхода для всех тестовых пользователей:

- `admin@bms.com / password123`
- `promo@bms.com / password123`
- `shift@bms.com / password123`
- `support@bms.com / password123`
