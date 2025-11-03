# GitHub Actions CI/CD

This repository includes a comprehensive CI/CD pipeline using GitHub Actions.

## CI Workflow

The CI workflow (`.github/workflows/ci.yml`) runs automatically on:
- Pull requests to the `master` branch  
- Pushes to the `master` branch

### What the CI Checks

The CI pipeline includes three main jobs:

#### 1. Test and Validation
- ✅ **Dependencies**: Installs and checks for unused dependencies
- ✅ **Compilation**: Compiles code with warnings treated as errors
- ✅ **Code Formatting**: Verifies code is properly formatted with `mix format`
- ✅ **Database Setup**: Creates and migrates test database
- ✅ **Tests**: Runs the full test suite
- ✅ **Precommit Checks**: Runs the project's `mix precommit` task

#### 2. Asset Building
- ✅ **Node.js Setup**: Installs Node.js and dependencies
- ✅ **Asset Compilation**: Builds CSS and JavaScript assets
- ✅ **Asset Verification**: Ensures compiled assets exist

#### 3. Code Quality Checks
- ✅ **Security Patterns**: Scans for potential hardcoded secrets
- ✅ **Code Comments**: Checks for TODO/FIXME comments
- ✅ **Final Validation**: Confirms all checks passed

### Environment

The CI runs on:
- **OS**: Ubuntu 22.04
- **Elixir**: 1.16.1
- **OTP**: 26.2
- **Node.js**: 20
- **PostgreSQL**: 15

### Database Configuration

The CI uses PostgreSQL with these settings:
- **Host**: localhost:5432
- **Database**: invoices_test
- **Username**: postgres  
- **Password**: postgres

### Caching

The workflow includes intelligent caching for:
- Elixir dependencies (`deps/`)
- Compiled build artifacts (`_build/`)
- Node.js dependencies (when applicable)

### Status Checks

All three jobs must pass for a pull request to be considered ready for merge:
- 🟢 **Test and Validation** - Core functionality tests
- 🟢 **Asset Building** - Frontend asset compilation  
- 🟢 **Code Quality Checks** - Additional quality gates

### Local Development

To run the same checks locally before pushing:

```bash
# Run the precommit checks (includes compile, format, test)
mix precommit

# Build assets
mix assets.setup
mix assets.build

# Check formatting specifically
mix format --check-formatted

# Run tests with database setup
mix ecto.create --quiet
mix ecto.migrate --quiet  
mix test
```

### Troubleshooting

If CI fails:

1. **Compilation Errors**: Fix any compilation warnings/errors locally
2. **Formatting Issues**: Run `mix format` to auto-fix formatting
3. **Test Failures**: Run `mix test` locally to debug failing tests
4. **Asset Issues**: Ensure Node.js dependencies are properly installed
5. **Database Issues**: Verify database migrations are up to date

The CI is designed to catch issues early and ensure code quality before merge.