# FinTrack

A modern financial management application built with Phoenix LiveView for managing invoices, tracking transactions and investments, and monitoring financial performance through interactive dashboards and analytics.

## Features

- **Invoice Management**: Create, edit, delete, and track invoices with automatic invoice number generation
- **Transaction Tracking**: Monitor income and expense transactions with detailed categorization and payment method tracking
- **Investment Tracking**: Monitor and track investment portfolios with value capture over time
- **Financial Dashboard**: Interactive charts and metrics for analyzing financial performance including:
  - Income vs Expense tracking over time
  - Monthly comparison charts
  - Profit margin calculations
  - Cumulative cash flow visualization
  - Income/Expense ratio analysis
  - Payment method breakdown and analysis
  - All-time monthly performance summary table
- **User Authentication**: Secure user registration and login system with bcrypt password hashing
- **Data Import/Export**: Excel file support for importing historical data and PDF export for professional invoices
- **Responsive Design**: Mobile-friendly interface with Tailwind CSS v4
- **Real-time Updates**: Phoenix LiveView provides instant UI updates without page refreshes
- **Pagination & Sorting**: Efficient data handling for large datasets

## Tech Stack

### Core Framework
- **Phoenix Framework v1.8.1**: Modern web framework for Elixir
- **Phoenix LiveView v1.1**: Real-time, interactive web applications
- **Elixir v1.17+** / **OTP 27+**: Functional programming language built on the Erlang VM
- **Ecto v3.13**: Database wrapper and query generator for Elixir
- **Bandit v1.5**: HTTP server built on Thousand Island

### Database & Storage
- **PostgreSQL**: Primary database for data persistence
- **Scrivener Ecto**: Pagination library for database queries

### Frontend & Styling
- **Tailwind CSS v4**: Utility-first CSS framework
- **HeroIcons**: Beautiful hand-crafted SVG icons
- **Chart.js**: Interactive charts and data visualization (via JavaScript hooks)
- **esbuild**: Fast JavaScript bundler

### Authentication & Security
- **bcrypt_elixir v3.0**: Secure password hashing with bcrypt algorithm
- **Phoenix Authentication**: Built-in user session management
- **Environment-based Secrets**: Secure configuration management via environment variables

### File Processing
- **ChromicPDF v1.15**: Professional PDF generation for invoices
- **elixlsx v0.6**: Excel file generation for exports
- **xlsxir v1.6**: Excel file reading for imports

### HTTP & External Services
- **Req v0.5**: Modern HTTP client for external API calls (preferred over HTTPoison/Tesla)
- **Swoosh v1.16**: Email composition and delivery library

### Development & Testing
- **Phoenix Live Dashboard**: Development and monitoring tools
- **Phoenix Live Reload**: Automatic browser refresh during development
- **LazyHTML**: HTML parsing and testing utilities

## Local Development Setup

### Prerequisites

Ensure you have the following installed on your system:

- **Elixir 1.17+** and **Erlang/OTP 27+**
  ```bash
  # macOS with Homebrew
  brew install elixir

  # Ubuntu/Debian
  sudo apt-get install elixir

  # Verify versions
  elixir --version  # Should show 1.17+
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
   git clone https://github.com/YOUR_USERNAME/fintrack.git
   cd fintrack
   ```

2. **Set up environment variables**
   ```bash
   cp .env.example .env.dev
   # Or for production: cp .env.example .env
   ```

   Edit `.env.dev` (or `.env`) with your actual invoice configuration:
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

   **Note:** If you encounter asset building errors, manually install Node.js dependencies:
   ```bash
   cd assets && npm install && cd ..
   ```

4. **Load environment variables and start the Phoenix server**
   ```bash
   # Load environment variables
   source .env.dev

   # Start the server
   mix phx.server
   ```

   Or start with an interactive Elixir shell:
   ```bash
   source .env.dev && iex -S mix phx.server
   ```

5. **Access the application**
   
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

- **Create a new user**: `mix invoices.create_user EMAIL PASSWORD`
  ```bash
  mix invoices.create_user user@example.com mypassword123
  ```

For other available custom tasks, check the `lib/mix/tasks/` directory.

## Environment Configuration

The application uses environment variables for sensitive configuration data to prevent accidental exposure of sensitive information in public repositories.

### Configuration Files

- **`.env.dev`** - Development environment variables (git-ignored, you must create this)
- **`.env`** - Production environment variables (git-ignored)
- **`.env.example`** - Template for environment variables (safe to commit)
- **`config/runtime.exs`** - Runtime configuration that reads from environment variables
- **`config/dev.exs`** - Development-specific configuration
- **`config/prod.exs`** - Production configuration
- **`config/test.exs`** - Test configuration

**Important:** Never commit `.env` or `.env.dev` files. Only `.env.example` should be in version control.

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
│   ├── accounts/               # User management and authentication
│   ├── billing/                # Invoices and transactions
│   ├── investments/            # Investment tracking
│   ├── application.ex          # OTP application
│   ├── mailer.ex               # Email functionality
│   └── repo.ex                 # Database repository
├── invoices_web/               # Web interface layer
│   ├── components/             # Reusable UI components
│   ├── controllers/            # HTTP controllers
│   ├── live/                   # LiveView modules
│   │   ├── auth_live/          # Authentication pages
│   │   ├── dashboard_live.ex   # Financial dashboard with analytics
│   │   ├── invoice_live/       # Invoice management
│   │   ├── investment_live/    # Investment tracking
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

The application uses the following main entities:

- **Users**: Authentication and user management with bcrypt password hashing
- **Invoices**: Invoice records with amounts, dates, and descriptions
- **Transactions**: Financial transactions (income/expense) with payment methods and timestamps
- **Investments**: Investment portfolio tracking
- **Value Captures**: Time-series tracking of investment values

## Configuration

Key configuration files:
- `config/config.exs` - General application config
- `config/runtime.exs` - Runtime config (loads environment variables)
- `config/dev.exs` - Development environment
- `config/prod.exs` - Production environment
- `config/test.exs` - Test environment

See the [Environment Configuration](#environment-configuration) section for details on setting up environment variables.

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

## Security

This project follows security best practices:
- All sensitive data is stored in environment variables
- Passwords are hashed with bcrypt
- No credentials are committed to version control
- See [SECURITY.md](SECURITY.md) for detailed security guidelines

## Contributing

1. Run `mix precommit` before submitting changes (runs compile with warnings as errors, format check, and tests)
2. Ensure all tests pass with `mix test`
3. Follow Elixir and Phoenix coding conventions
4. Add tests for new functionality
5. Never commit `.env` or `.env.dev` files - only `.env.example` should be in git

## Learn More About Phoenix

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html  
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
