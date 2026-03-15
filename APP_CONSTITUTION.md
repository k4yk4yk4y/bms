# BMS Application Constitution

**Version:** 1.0  
**Last Updated:** 2025-01-27  
**Application Name:** Casino Bonus Management System (BMS)

---

## Table of Contents

1. [Application Overview](#application-overview)
2. [Technology Stack](#technology-stack)
3. [Architecture & Structure](#architecture--structure)
4. [Core Domain Models](#core-domain-models)
5. [Controllers & Routing](#controllers--routing)
6. [Authentication & Authorization](#authentication--authorization)
7. [API Structure](#api-structure)
8. [Database Schema](#database-schema)
9. [Key Features](#key-features)
10. [Development Practices](#development-practices)
11. [Testing Strategy](#testing-strategy)
12. [Deployment Configuration](#deployment-configuration)

---

## Application Overview

BMS is a comprehensive Ruby on Rails application designed for managing casino bonuses with an interactive heatmap visualization. The system supports multiple bonus types, reward systems, and provides both web-based and API interfaces for bonus management.

### Core Purpose
- Manage casino bonuses with full lifecycle support (draft → active → inactive → expired)
- Visualize bonus distribution through interactive heatmap calendar
- Support multiple bonus event types and reward mechanisms
- Provide RESTful API for external integrations
- Track audit logs for all bonus operations

---

## Technology Stack

### Backend
- **Framework:** Ruby on Rails 8.0.2
- **Ruby Version:** 3.4.2
- **Database:** PostgreSQL
- **Web Server:** Puma
- **Background Jobs:** Solid Queue
- **Caching:** Solid Cache
- **WebSockets:** Solid Cable

### Frontend
- **Templates:** ERB (Embedded Ruby)
- **JavaScript:** ES6+ with Import Maps
- **Hotwire:** Turbo Rails & Stimulus Rails
- **Styling:** Bootstrap CSS, Sass
- **Asset Pipeline:** Sprockets

### Admin Interface
- **ActiveAdmin:** 3.3 (Admin panel)
- **CanCanCan:** 3.6 (Authorization)
- **Devise:** 4.9 (Authentication)

### Development & Testing
- **Testing:** RSpec Rails 6.1, Minitest
- **Test Data:** Factory Bot Rails 6.4, Faker 3.2
- **Code Quality:** RuboCop Rails Omakase, Brakeman
- **Coverage:** SimpleCov
- **System Testing:** Capybara, Selenium WebDriver

### Deployment
- **Deployment Tool:** Kamal
- **Containerization:** Docker
- **Performance:** Thruster (HTTP asset caching/compression)

### Additional Gems
- **Paper Trail:** 16.0 (Versioning/Auditing)
- **JBuilder:** JSON API responses

---

## Architecture & Structure

### Directory Structure

```
app/
├── admin/              # ActiveAdmin configurations
├── assets/             # CSS, JavaScript, images
├── controllers/        # Application controllers
│   ├── admin_users/   # Admin authentication
│   ├── api/v1/        # API endpoints
│   ├── concerns/      # Shared controller concerns
│   └── users/         # User authentication
├── helpers/            # View helpers
├── javascript/         # Stimulus controllers
├── jobs/               # Background jobs
├── mailers/            # Email templates
├── models/             # ActiveRecord models
│   └── concerns/      # Shared model concerns
└── views/              # ERB templates

config/
├── environments/       # Environment configurations
├── initializers/       # App initialization
├── locales/            # I18n translations
└── routes.rb           # Route definitions

db/
├── migrate/            # Database migrations
└── schema.rb           # Current schema

lib/
├── bonus_system_analysis/  # Analysis tools
└── tasks/              # Rake tasks

spec/                   # RSpec tests
test/                   # Minitest tests
```

### Design Patterns

1. **MVC (Model-View-Controller):** Standard Rails architecture
2. **Concerns:** Shared behavior extracted to concerns
   - `Auditable`: Audit logging functionality
   - `BonusCommonParameters`: Shared bonus parameters
   - `CurrencyManagement`: Currency handling logic
   - `CurrentUserTracking`: User tracking in controllers
3. **Service Objects:** Complex business logic (when needed)
4. **STI (Single Table Inheritance):** Reward types use polymorphic associations
5. **RESTful Routing:** Standard REST conventions

---

## Core Domain Models

### Primary Models

#### Bonus
**Purpose:** Central model representing a casino bonus

**Key Attributes:**
- `name` (string, required)
- `code` (string, optional)
- `status` (enum: draft, active, inactive, expired)
- `event` (enum: deposit, input_coupon, manual, collection, groups_update, scheduler)
- `availability_start_date` / `availability_end_date` (datetime)
- `minimum_deposit`, `wager`, `maximum_winnings` (decimal)
- `maximum_winnings_type` (enum: fixed, multiplier)
- `currencies` (JSON array)
- `groups` (JSON array)
- `currency_minimum_deposits` (JSON hash)
- `project`, `dsl_tag`, `country`, `user_group`
- `no_more` (usage limitation string)
- `totally_no_more` (integer, total activation limit)

**Associations:**
- `has_many` reward types (polymorphic)
- `has_many` bonus_audit_logs
- `belongs_to` creator/updater (User)
- `belongs_to` dsl_tag (optional)

**Key Methods:**
- `active?`, `available_now?`, `expired?`
- `activate!`, `deactivate!`, `mark_as_expired!`
- `all_rewards`, `has_rewards?`, `reward_types`
- Currency/group formatting methods

#### Reward Models (STI Pattern)

All reward models belong to `bonus` and share common structure:

1. **BonusReward** (Base reward type)
   - `amount`, `percentage`
   - `currency_amounts` (JSON)
   - `max_win_value`, `max_win_type`

2. **FreespinReward**
   - `spins_count`
   - `games` (YAML array)
   - `bet_level`
   - `code`, `stag`

3. **BonusBuyReward**
   - `buy_amount`, `multiplier`
   - `games` (YAML array)
   - `bet_level`
   - `max_win_value`, `max_win_type`

4. **FreechipReward**
   - `chip_value`, `chips_count`

5. **BonusCodeReward**
   - `code`, `code_type`
   - `title`

6. **CompPointReward**
   - `points_amount`, `multiplier`
   - `title`

7. **MaterialPrizeReward**
   - `prize_name`, `prize_value`

#### User Models

1. **User**
   - Standard Devise authentication
   - `role` (integer enum: 0=admin, 1=manager, 2=operator, 3=viewer)
   - `first_name`, `last_name`
   - Sign-in tracking fields

2. **AdminUser**
   - ActiveAdmin authentication
   - Separate from regular users

#### Supporting Models

1. **BonusTemplate**
   - Reusable bonus configurations
   - Indexed by `dsl_tag`, `project`, `name`

2. **DslTag**
   - Tagging system for bonuses
   - Unique name constraint

3. **Project**
   - Project/casino grouping
   - Unique name constraint

4. **PermanentBonus**
   - Special bonus type that doesn't expire
   - Links bonus to project

5. **MarketingRequest**
   - Marketing campaign bonus requests
   - Status workflow: pending → active/rejected
   - `request_type`, `promo_code`, `stag`

6. **BonusAuditLog**
   - Complete audit trail
   - Tracks: action, changes_data, metadata, user

7. **HeatmapComment**
   - User comments on heatmap dates
   - Soft delete support

---

## Controllers & Routing

### Main Controllers

1. **HomeController**
   - Root path (`/`)
   - Dashboard/homepage

2. **BonusesController**
   - Full CRUD for bonuses
   - `preview`, `duplicate` (member actions)
   - `by_type`, `bulk_update`, `find_template` (collection actions)

3. **HeatmapController**
   - Interactive calendar visualization
   - Route: `GET /heatmap`

4. **MarketingController**
   - Marketing request management
   - Actions: `activate`, `reject`, `transfer`

5. **BonusTemplatesController**
   - Template management
   - Settings namespace: `/settings/templates`

6. **SetupController**
   - Initial application setup
   - Admin user creation

### API Controllers (`/api/v1`)

1. **BonusesController**
   - RESTful bonus management
   - Collection actions: `by_type`, `active`, `expired`

2. **SetupController**
   - API setup endpoints
   - `create_admin`, `admin_status`

### Authentication Controllers

1. **Users::SessionsController**
   - User authentication (Devise)

2. **AdminUsers::SessionsController**
   - Admin authentication (ActiveAdmin/Devise)

### ActiveAdmin

Admin interface for:
- Bonuses
- Bonus Templates
- Users
- Admin Users
- DSL Tags
- Projects
- Permanent Bonuses
- Bonus Audit Logs

---

## Authentication & Authorization

### Authentication

1. **Devise** for both User and AdminUser
   - Email/password authentication
   - Password reset functionality
   - Remember me functionality
   - Session management

2. **User Roles** (enum on User model)
   - `admin`
   - `promo_manager`
   - `shift_leader`
   - `support_agent`
   - `marketing_manager`
   - `retention_manager`
   - `smm_manager`
   - `delivery_manager`

### Authorization

1. **CanCanCan** for ability management
   - `app/models/ability.rb` defines permissions
   - Role-based access control
   - Frontend access split by sections:
     - `bonuses` (full bonuses access)
     - `projects` (projects dropdown/filter)
     - `permanent_bonuses` (required to access `/bonuses`)
   - Permanent-only mode is supported: user can view only permanent bonuses and is redirected on non-permanent bonus URLs.

2. **ActiveAdmin** authorization
   - Integrated with CanCanCan
   - Admin-only access

---

## API Structure

### Base Path
`/api/v1`

### Endpoints

#### Bonuses
- `GET /api/v1/bonuses` - List all bonuses
- `POST /api/v1/bonuses` - Create bonus
- `GET /api/v1/bonuses/:id` - Show bonus
- `PUT /api/v1/bonuses/:id` - Update bonus
- `DELETE /api/v1/bonuses/:id` - Delete bonus
- `GET /api/v1/bonuses/by_type` - Filter by type
- `GET /api/v1/bonuses/active` - Active bonuses
- `GET /api/v1/bonuses/expired` - Expired bonuses

#### Setup
- `POST /api/v1/setup/create_admin` - Create admin user
- `GET /api/v1/setup/admin_status` - Check admin status

### Response Format
- JSON (via JBuilder)
- Standard HTTP status codes
- Error handling with appropriate messages

---

## Database Schema

### Key Tables

1. **bonuses** - Main bonus records
2. **bonus_rewards** - Base reward type
3. **freespin_rewards** - Free spin rewards
4. **bonus_buy_rewards** - Bonus buy rewards
5. **freechip_rewards** - Free chip rewards
6. **bonus_code_rewards** - Code-based rewards
7. **comp_point_rewards** - Comp point rewards
8. **material_prize_rewards** - Material prize rewards
9. **bonus_templates** - Reusable templates
10. **bonus_audit_logs** - Audit trail
11. **users** - Application users
12. **admin_users** - Admin users
13. **dsl_tags** - Tagging system
14. **projects** - Project grouping
15. **permanent_bonuses** - Non-expiring bonuses
16. **marketing_requests** - Marketing campaigns
17. **heatmap_comments** - Calendar comments

### Indexes

Key indexes on:
- `bonuses`: code, status, event, project, dsl_tag, dates, country, user_group
- `bonus_rewards`: bonus_id, reward_type
- Reward tables: bonus_id, specific fields (code, amount, etc.)
- Foreign keys on all associations

### Constraints

- Unique constraints on: bonus codes, promo codes, STAGs, email addresses
- Foreign key constraints on all associations
- Check constraints via validations

---

## Key Features

### 1. Bonus Management
- Full CRUD operations
- Multiple event types (deposit, manual, coupon, etc.)
- Status workflow (draft → active → inactive → expired)
- Automatic expiration checking
- Bulk operations support

### 2. Reward System
- Multiple reward types (bonus, freespins, chips, codes, etc.)
- Flexible reward configuration
- Currency support
- Maximum winnings limits (fixed or multiplier)

### 3. Heatmap Visualization
- Interactive calendar view
- Color-coded bonus distribution
- Filtering by bonus type
- Month/year navigation
- Date range comments

### 4. Template System
- Reusable bonus templates
- Quick bonus creation from templates
- Template search and filtering

### 5. Audit Logging
- Complete change tracking
- User attribution
- IP address logging
- Action history (create, update, delete, activate, deactivate)

### 6. Marketing Requests
- Request workflow (pending → active/rejected)
- Partner management
- Promo code tracking
- Transfer functionality

### 7. Multi-Currency Support
- Currency arrays on bonuses
- Currency-specific minimum deposits
- Precision validation for crypto vs fiat

### 8. User Group Management
- Group-based targeting
- JSON array storage
- Group filtering

### 9. Project Organization
- Project-based grouping
- DSL tag system
- Permanent bonus support

---

## Development Practices

### Code Style

1. **Ruby Style Guide**
   - Follow RuboCop Rails Omakase
   - Snake_case for methods/variables
   - CamelCase for classes/modules
   - Single quotes unless interpolation

2. **Rails Conventions**
   - RESTful routes
   - Strong parameters
   - Model validations
   - Scopes for queries

3. **Naming Conventions**
   - Descriptive method names (e.g., `available_now?`)
   - Boolean methods end with `?`
   - Destructive methods end with `!`

### Code Organization

1. **Concerns** for shared behavior
2. **Scopes** for common queries
3. **Validations** in models
4. **Callbacks** for lifecycle events
5. **Helper methods** for view logic

### Error Handling

1. **Model Validations**
   - Presence, inclusion, format validations
   - Custom validation methods
   - Error messages in Russian/English

2. **Controller Error Handling**
   - Standard Rails error responses
   - Flash messages for user feedback
   - API error responses with status codes

### Security

1. **Strong Parameters** in all controllers
2. **CSRF Protection** enabled
3. **SQL Injection Prevention** via ActiveRecord
4. **XSS Protection** via Rails defaults
5. **Authentication Required** for protected routes
6. **Authorization** via CanCanCan

### Performance

1. **Database Indexes** on frequently queried fields
2. **Eager Loading** to prevent N+1 queries
3. **Scopes** for efficient queries
4. **Caching** via Solid Cache
5. **Background Jobs** for long-running tasks

---

## Testing Strategy

### Test Frameworks

1. **RSpec** (Primary)
   - Model specs
   - Controller specs
   - Request specs
   - Helper specs
   - View specs

2. **Minitest** (Legacy/System)
   - System tests
   - Integration tests

### Test Structure

```
spec/
├── models/          # Model tests
├── controllers/     # Controller tests
├── requests/        # API/Request tests
├── helpers/         # Helper tests
├── views/           # View tests
├── factories/       # Factory Bot definitions
└── support/         # Test helpers

test/
├── system/          # System tests
├── integration/     # Integration tests
└── fixtures/        # Test fixtures
```

### Testing Tools

1. **Factory Bot** - Test data generation
2. **Faker** - Fake data generation
3. **Shoulda Matchers** - Model/controller matchers
4. **Database Cleaner** - Test data management
5. **SimpleCov** - Code coverage
6. **Capybara** - System testing
7. **Selenium** - Browser automation

### Test Coverage Goals

- Model validations and methods
- Controller actions and authorization
- API endpoints
- Critical business logic
- Edge cases and error handling

---

## Deployment Configuration

### Deployment Tool: Kamal

**Configuration:** `config/deploy.yml`

### Docker Support

- **Dockerfile** for containerization
- Multi-stage builds (if configured)
- Environment-specific configurations

### Environment Variables

Key variables:
- `DATABASE_URL` - PostgreSQL connection
- `RAILS_ENV` - Environment (development/production)
- `RAILS_MAX_THREADS` - Puma thread pool
- `SECRET_KEY_BASE` - Rails secret

### Database Configuration

- **Development:** `bms_development`
- **Test:** `bms_test`
- **Production:** `bms_production` (from `DATABASE_URL`)

### Background Jobs

- **Solid Queue** for job processing
- Separate database migrations path: `db/queue_migrate`

### Caching

- **Solid Cache** for application caching
- Separate database migrations path: `db/cache_migrate`

### WebSockets

- **Solid Cable** for Action Cable
- Separate database migrations path: `db/cable_migrate`

### Performance

- **Thruster** for HTTP asset caching/compression
- **Puma** web server configuration in `config/puma.rb`

---

## Rake Tasks

### Custom Tasks

1. **Heatmap Test Data**
   ```bash
   rails heatmap:create_test_data
   ```
   Creates 82 test bonuses for July 2025

2. **Bonus System Analysis**
   ```bash
   bundle exec rake bonus_system:analyze
   ```
   Runs Brakeman, RuboCop, ESLint analysis
   Output: `tmp/analysis_reports/bonus_system_report.json`

3. **Admin Creation**
   ```bash
   bin/create_admin.sh
   ```
   Interactive admin user creation

### Standard Rails Tasks

- `rails db:migrate` - Run migrations
- `rails db:seed` - Seed database
- `rails db:reset` - Reset database
- `rails console` - Rails console
- `rails server` - Start development server

---

## Configuration Files

### Application Config

- `config/application.rb` - Main application configuration
- `config/environments/` - Environment-specific configs
- `config/initializers/` - Initialization scripts
- `config/routes.rb` - Route definitions
- `config/database.yml` - Database configuration
- `config/puma.rb` - Web server configuration
- `config/importmap.rb` - JavaScript import maps

### Deployment Config

- `config/deploy.yml` - Kamal deployment config
- `Dockerfile` - Docker container definition
- `render.yaml` - Render.com deployment (if used)

### Code Quality

- `.rubocop.yml` (implicit via rubocop-rails-omakase)
- `.brakeman.yml` (if configured)

---

## Internationalization

### Locales

- `config/locales/` - Translation files
- Default: English
- Support for Russian (based on error messages)

### Localization

- Date/time formatting
- Number formatting
- Currency formatting
- Error messages

---

## Monitoring & Logging

### Logging

- Standard Rails logging
- Environment-specific log levels
- Audit logs in `bonus_audit_logs` table

### Health Checks

- Route: `GET /up`
- Returns 200 if app boots successfully
- Used by load balancers/uptime monitors

---

## Future Considerations

### Potential Enhancements

1. **API Versioning** - Additional API versions
2. **Webhooks** - Event notifications
3. **Export/Import** - Bulk bonus operations
4. **Advanced Analytics** - Bonus performance metrics
5. **Multi-tenancy** - Support for multiple casinos
6. **Real-time Updates** - WebSocket notifications
7. **Mobile API** - Enhanced mobile support

---

## Maintenance Guidelines

### Regular Tasks

1. **Database Maintenance**
   - Run migrations regularly
   - Monitor index performance
   - Clean up expired bonuses

2. **Code Quality**
   - Run RuboCop before commits
   - Run Brakeman for security
   - Maintain test coverage

3. **Security Updates**
   - Keep gems updated
   - Monitor security advisories
   - Review audit logs

4. **Performance Monitoring**
   - Monitor query performance
   - Review N+1 queries
   - Optimize slow endpoints

---

## Contact & Support

- **Repository:** GitHub (k4yk4yk4y/bms)
- **Issues:** GitHub Issues
- **Documentation:** README.md, this document

---

**End of Constitution**

*This document should be updated as the application evolves. All developers should be familiar with its contents.*
