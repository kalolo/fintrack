# Security Guidelines

## Before Making Repository Public

This document outlines security best practices and requirements before making this repository public.

## ⚠️ Critical Security Checklist

- [x] Remove `.env.dev` from git history (contains real credentials)
- [x] Update `.gitignore` to prevent future credential leaks
- [x] Remove hardcoded secrets from config files
- [ ] Review git history for accidentally committed secrets
- [ ] Rotate all exposed credentials (if any were previously committed)

## Secrets Management

### Environment Variables

**NEVER commit real credentials to the repository.** Use environment variables for all sensitive data:

- `SECRET_KEY_BASE` - Phoenix secret key (generate with `mix phx.gen.secret`)
- `DATABASE_URL` - Production database connection string
- `CLIENT_NAME`, `CLIENT_ADDRESS`, etc. - Invoice configuration
- `BILL_TO_*` - Banking and payment information

### Required Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
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

### Development Setup

1. Copy `.env.example` to `.env.dev`
2. Fill in your actual development values
3. Source the file: `source .env.dev`
4. Run the application

## Files That Must NEVER Be Committed

- `.env` - Production environment variables
- `.env.dev`, `.env.local`, `.env.production` - Any environment-specific configs
- `config/*.secret.exs` - Secret configuration files
- `priv/cert/*.pem` - SSL certificates
- Database dumps or backups containing real data

## Database Security

### Development
- Default credentials are `postgres/postgres` (safe for local development)
- Never use production database credentials in development

### Production
- Use strong, randomly generated passwords
- Use `DATABASE_URL` environment variable
- Enable SSL connections
- Restrict database access by IP

## Authentication & Password Security

### Password Requirements
- Minimum 8 characters
- Maximum 72 characters (bcrypt limitation)
- Passwords are hashed with bcrypt before storage

### Admin Password Reset
For emergency password resets, use IEx console:

```elixir
user = Invoices.Accounts.get_user_by_email("user@example.com")
Invoices.Accounts.admin_reset_password(user, "new_secure_password")
```

**IMPORTANT:** The `admin_reset_password/2` function should NEVER be exposed through web APIs or controllers.

## Session Security

### Secret Key Base
- Development: Uses a placeholder secret (overridable via `SECRET_KEY_BASE` env var)
- Test: Uses a static secret (safe for testing)
- Production: MUST set `SECRET_KEY_BASE` environment variable

Generate new secret:
```bash
mix phx.gen.secret
```

## Git History Cleanup

If sensitive data was previously committed:

1. Use BFG Repo Cleaner or `git filter-branch` to remove sensitive data
2. Force push to remote (coordinate with team)
3. Rotate ALL exposed credentials immediately
4. Review all historical commits for other potential leaks

Example using BFG:
```bash
# Install BFG
brew install bfg

# Remove sensitive file from history
bfg --delete-files .env.dev
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

## Reporting Security Issues

If you discover a security vulnerability, please email the maintainers directly instead of creating a public issue.

## Production Deployment Checklist

- [ ] All secrets moved to environment variables
- [ ] `SECRET_KEY_BASE` set and unique
- [ ] Database uses strong credentials
- [ ] SSL/TLS enabled
- [ ] No test/default credentials in production
- [ ] Error pages don't expose stack traces
- [ ] Logging doesn't include sensitive data
- [ ] CORS configured appropriately
- [ ] Rate limiting enabled

## Additional Security Measures

### HTTPS
Always use HTTPS in production. Configure in `config/prod.exs`:
```elixir
config :invoices, InvoicesWeb.Endpoint,
  force_ssl: [hsts: true]
```

### Content Security Policy
Consider adding CSP headers to prevent XSS attacks.

### Regular Updates
Keep dependencies updated:
```bash
mix deps.update --all
mix deps.audit
```

## References

- [Phoenix Security Guide](https://hexdocs.pm/phoenix/security.html)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Elixir Security Working Group](https://erlef.org/wg/security)
