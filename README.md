# Invoice Management System

A modern web application built with Phoenix LiveView for managing invoices, tracking transactions, and monitoring financial performance through interactive dashboards and analytics.

## Features

- **Invoice Management**: Create, edit, delete, and track invoices with automatic invoice number generation
- **Transaction Tracking**: Monitor income and expense transactions with detailed categorization
- **Financial Dashboard**: Interactive charts and metrics for analyzing financial performance including:
  - Income vs Expense tracking over time
  - Monthly comparison charts
  - Profit margin calculations
  - Cumulative cash flow visualization
  - Income/Expense ratio analysis
- **User Authentication**: Secure user registration and login system with bcrypt encryption
- **Data Import/Export**: Excel file support for importing historical data and PDF export for professional invoices
- **Responsive Design**: Mobile-friendly interface with Tailwind CSS
- **Real-time Updates**: Phoenix LiveView provides instant UI updates without page refreshes
- **Pagination & Sorting**: Efficient data handling for large datasets

## Tech Stack

### Core Framework
- **Phoenix Framework v1.8**: Modern web framework for Elixir
- **Phoenix LiveView v1.1**: Real-time, interactive web applications
- **Elixir v1.15+**: Functional programming language built on the Erlang VM
- **Ecto v3.13**: Database wrapper and query generator for Elixir

### Database & Storage
- **PostgreSQL**: Primary database for data persistence
- **Scrivener Ecto**: Pagination library for database queries

### Frontend & Styling
- **Tailwind CSS v4**: Utility-first CSS framework
- **HeroIcons**: Beautiful hand-crafted SVG icons
- **Chart.js**: Interactive charts and data visualization (via JavaScript hooks)
- **esbuild**: Fast JavaScript bundler

### Authentication & Security
- **bcrypt_elixir**: Secure password hashing
- **Phoenix Authentication**: Built-in user session management

### File Processing
- **ChromicPDF**: Professional PDF generation for invoices
- **elixlsx**: Excel file generation for exports  
- **xlsxir**: Excel file reading for imports

### HTTP & External Services
- **Req**: Modern HTTP client for external API calls
- **Swoosh**: Email composition and delivery library

### Development & Testing
- **Phoenix Live Dashboard**: Development and monitoring tools
- **Phoenix Live Reload**: Automatic browser refresh during development
- **LazyHTML**: HTML parsing and testing utilities

## Local Development Setup

### Prerequisites

Ensure you have the following installed on your system:

- **Elixir 1.15+** and **Erlang/OTP 25+**
  ```bash
  # macOS with Homebrew
  brew install elixir
  
  # Ubuntu/Debian
  sudo apt-get install elixir
  ```

- **PostgreSQL 12+**
  ```bash
  # macOS with Homebrew
  brew install postgresql
  brew services start postgresql
  
  # Ubuntu/Debian
  sudo apt-get install postgresql postgresql-contrib
  sudo service postgresql start
  ```

- **Node.js 18+** (for asset compilation)
  ```bash
  # macOS with Homebrew
  brew install node
  
  # Ubuntu/Debian
  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
  sudo apt-get install -y nodejs
  ```

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd invoices
   ```

2. **Set up environment variables**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` with your actual invoice configuration:
   ```env
   # Client Information
   CLIENT_NAME=Your Company Name
   CLIENT_ADDRESS=Your Company Address
   CLIENT_CITY_STATE_ZIP=City, State ZIP
   CLIENT_EIN=Your-EIN-Number

   # Bill To Information
   BILL_TO_NAME=Your Name
   BILL_TO_SWIFT_BIC=SWIFT-BIC-CODE
   BILL_TO_ACCOUNT_NUMBER=Account-Number
   BILL_TO_BANK_NAME=Bank Name
   BILL_TO_BANK_ADDRESS=Bank Address
   ```

3. **Install dependencies and setup database**
   ```bash
   mix setup
   ```
   This command will:
   - Install Elixir dependencies (`mix deps.get`)
   - Create and migrate the database (`mix ecto.setup`)
   - Install and setup frontend assets (`mix assets.setup`)
   - Build initial assets (`mix assets.build`)

4. **Start the Phoenix server**
   ```bash
   mix phx.server
   ```
   
   Or start with an interactive Elixir shell:
   ```bash
   iex -S mix phx.server
   ```

4. **Access the application**
   
   Open your browser and visit: [`http://localhost:4000`](http://localhost:4000)

### Development Commands

- **Run tests**: `mix test`
- **Run tests for a specific file**: `mix test test/my_test.exs`
- **Run failed tests only**: `mix test --failed`
- **Format code**: `mix format`
- **Check for unused dependencies**: `mix deps.unlock --unused`
- **Pre-commit checks**: `mix precommit` (runs compile with warnings as errors, format, and test)
- **Reset database**: `mix ecto.reset`
- **Generate new migration**: `mix ecto.gen.migration migration_name`

### Custom Mix Tasks

The application includes several custom tasks:

- **Create a new user**: `mix invoices.create_user`
- **Import historical data**: `mix invoices.import_historical`
- **Fix amount data**: `mix invoices.fix_amounts`

## Environment Configuration

The application uses environment variables for sensitive configuration data to prevent accidental exposure of sensitive information in public repositories.

### Configuration Files

- **`.env`** - Local environment variables (git-ignored)
- **`.env.example`** - Template for environment variables
- **`config/runtime.exs`** - Runtime configuration that reads from environment variables
- **`config/dev.exs`** - Development-specific configuration
- **`config/prod.exs`** - Production configuration

### Invoice Configuration

All sensitive invoice information is loaded from environment variables:

```env
# Client Information (Your Company Details)
CLIENT_NAME=Your Company Name
CLIENT_ADDRESS=Your Company Address  
CLIENT_CITY_STATE_ZIP=City, State ZIP
CLIENT_EIN=Your-EIN-Number

# Bill To Information (Banking Details)
BILL_TO_NAME=Your Name
BILL_TO_SWIFT_BIC=SWIFT-BIC-CODE
BILL_TO_ACCOUNT_NUMBER=Account-Number
BILL_TO_BANK_NAME=Bank Name
BILL_TO_BANK_ADDRESS=Bank Address
```

### Production Deployment

In production, set these environment variables directly on your hosting platform instead of using a `.env` file:

```bash
export CLIENT_NAME="Your Company Name"
export CLIENT_ADDRESS="Your Company Address"
export CLIENT_CITY_STATE_ZIP="City, State ZIP"
export CLIENT_EIN="Your-EIN-Number"
export BILL_TO_NAME="Your Name"
export BILL_TO_SWIFT_BIC="SWIFT-BIC-CODE"
export BILL_TO_ACCOUNT_NUMBER="Account-Number"
export BILL_TO_BANK_NAME="Bank Name"
export BILL_TO_BANK_ADDRESS="Bank Address"
```

## Project Structure

```
lib/
├── invoices/                    # Core business logic
│   ├── accounts/               # User management
│   ├── billing/                # Invoices and transactions
│   ├── application.ex          # OTP application
│   └── repo.ex                 # Database repository
├── invoices_web/               # Web interface layer  
│   ├── components/             # Reusable UI components
│   ├── controllers/            # HTTP controllers
│   ├── live/                   # LiveView modules
│   │   ├── auth_live/          # Authentication pages
│   │   ├── dashboard_live.ex   # Financial dashboard
│   │   ├── invoice_live/       # Invoice management
│   │   └── transaction_live/   # Transaction management
│   └── router.ex               # URL routing
├── mix/tasks/                  # Custom Mix tasks
priv/
├── repo/migrations/            # Database migrations
└── static/                     # Static assets
test/                           # Test files
assets/                         # Frontend assets (CSS, JS)
```

## Database Schema

The application uses three main entities:

- **Users**: Authentication and user management
- **Invoices**: Invoice records with amounts, dates, and descriptions  
- **Transactions**: Financial transactions (income/expense) with timestamps

## Configuration

Key configuration files:
- `config/config.exs` - General application config
- `config/dev.exs` - Development environment
- `config/prod.exs` - Production environment  
- `config/test.exs` - Test environment

## Debugging & Troubleshooting

### Common Issues

1. **Database connection errors**
   ```bash
   # Ensure PostgreSQL is running
   brew services start postgresql  # macOS
   sudo service postgresql start   # Linux
   
   # Check database configuration in config/dev.exs
   ```

2. **Asset compilation failures**
   ```bash
   # Reinstall Node.js dependencies
   cd assets && npm install
   
   # Rebuild assets
   mix assets.build
   ```

3. **Port already in use (4000)**
   ```bash
   # Find and kill process using port 4000
   lsof -ti:4000 | xargs kill -9
   
   # Or start on different port
   PORT=4001 mix phx.server
   ```

4. **Migration errors**
   ```bash
   # Reset database completely
   mix ecto.reset
   
   # Or drop and recreate
   mix ecto.drop && mix ecto.create && mix ecto.migrate
   ```

### Debugging Tools

1. **Phoenix Live Dashboard**: Visit `/dashboard` when server is running for real-time metrics

2. **IEx Debug Session**: Start server with `iex -S mix phx.server` for interactive debugging

3. **Database Console**: Access PostgreSQL directly
   ```bash
   psql -d invoices_dev
   ```

4. **Logs**: Check Phoenix logs in the terminal where server is running

5. **Tests**: Run specific test files to isolate issues
   ```bash
   mix test test/invoices_web/live/dashboard_live_test.exs --verbose
   ```

### Performance Monitoring

The application includes telemetry and metrics collection. Key performance indicators:
- Database query times
- LiveView mount/update times  
- Memory usage
- Request response times

Access these metrics through Phoenix Live Dashboard at `/dashboard`.

## Deployment

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

For production deployment:
1. Set environment variables for database and secrets
2. Run `mix assets.deploy` to compile and minify assets
3. Run database migrations in production
4. Start the application with `mix phx.server`

## Contributing

1. Run `mix precommit` before submitting changes
2. Ensure all tests pass with `mix test`
3. Follow Elixir and Phoenix coding conventions
4. Add tests for new functionality

## Learn More About Phoenix

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html  
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
