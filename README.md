# Casino Bonus Management System

A comprehensive Rails application for managing casino bonuses with an interactive heatmap visualization.

## Features

- **Bonus Management**: Create, edit, and manage different types of bonuses
- **Interactive Heatmap**: Visual calendar showing bonus distribution by date
- **Multiple Bonus Types**: Support for deposit, manual, input coupon, collection, groups update, and scheduler bonuses
- **RESTful API**: JSON API for bonus management
- **Modern UI**: Responsive design with Bootstrap and custom styling

## Tech Stack

- **Backend**: Ruby on Rails 8.0.2
- **Database**: PostgreSQL
- **Frontend**: ERB templates, Bootstrap CSS, JavaScript
- **Testing**: Minitest framework
- **Deployment**: Kamal deployment configuration

## Getting Started

### Prerequisites

- Ruby 3.4.2
- PostgreSQL
- Node.js (for asset compilation)

### Installation

1. Clone the repository:
   ```bash
   git clone git@github.com:k4yk4yk4y/bms.git
   cd bms
   ```

2. Install dependencies:
   ```bash
   bundle install
   npm install
   ```

3. Set up the database:
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

4. Start the server:
   ```bash
   rails server
   ```

5. Visit `http://localhost:3000` in your browser

## Usage

### Creating Test Data

To create test bonus data for the heatmap:

```bash
rails heatmap:create_test_data
```

This will create 82 test bonuses for July 2025 with various distributions.

### Heatmap Features

- **Calendar View**: Monthly calendar showing bonus distribution
- **Color Coding**: 
  - White: 0 bonuses
  - Light green: 1-2 bonuses
  - Medium green: 3-4 bonuses
  - Dark green: 5-6 bonuses
  - Green-red: 7-8 bonuses
  - Red: 9-10+ bonuses
- **Filtering**: Filter by bonus type
- **Navigation**: Navigate between months and years

### API Endpoints

- `GET /api/v1/bonuses` - List all bonuses
- `POST /api/v1/bonuses` - Create a new bonus
- `GET /api/v1/bonuses/:id` - Get a specific bonus
- `PUT /api/v1/bonuses/:id` - Update a bonus
- `DELETE /api/v1/bonuses/:id` - Delete a bonus

## Project Structure

```
app/
├── controllers/          # Application controllers
│   ├── api/v1/         # API controllers
│   └── heatmap_controller.rb
├── models/              # ActiveRecord models
├── views/               # ERB templates
│   ├── bonuses/        # Bonus management views
│   └── heatmap/        # Heatmap visualization
└── helpers/             # View helpers

lib/
└── tasks/               # Rake tasks
    └── create_test_heatmap_data.rake

config/                  # Application configuration
db/                      # Database migrations and schema
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For questions or support, please open an issue on GitHub.
