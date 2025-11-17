# OneTimeSecret Community Edition

A modern, secure secret-sharing platform built with Elixir and Phoenix. Share sensitive information that self-destructs after being viewed.

## Features

- **Secure Encryption**: AES-256-GCM encryption for all secrets
- **Burn After Reading**: Secrets automatically self-destruct after viewing
- **Time-Limited**: Configurable TTL from 5 minutes to 90 days
- **Passphrase Protection**: Optional additional security layer
- **Rate Limiting**: Protection against abuse
- **REST API**: Full-featured API for programmatic access
- **GraphQL**: Rich query interface via Absinthe
- **Real-time Updates**: Phoenix LiveView for instant feedback
- **User Accounts**: Optional authentication with secret history
- **Docker Support**: Easy deployment with Docker Compose

## Quick Start

### Prerequisites

- Elixir 1.15+ and Erlang/OTP 26+
- PostgreSQL 14+
- Node.js 18+ (for asset compilation)
- Redis (optional, for distributed rate limiting)

### Local Development

1. **Clone and Setup**
   ```bash
   git clone <repository-url>
   cd ots4
   cp .env.example .env
   # Edit .env and set secure values for all keys
   ```

2. **Install Dependencies**
   ```bash
   mix deps.get
   cd assets && npm install && cd ..
   ```

3. **Setup Database**
   ```bash
   mix ecto.create
   mix ecto.migrate
   mix run priv/repo/seeds.exs
   ```

4. **Start Phoenix Server**
   ```bash
   mix phx.server
   ```

5. **Visit** `http://localhost:4000`

### Docker Deployment

1. **Configure Environment**
   ```bash
   # Generate secrets
   mix phx.gen.secret 64  # Use for SECRET_KEY_BASE
   mix phx.gen.secret 64  # Use for GUARDIAN_SECRET
   mix phx.gen.secret 32  # Use for ENCRYPTION_KEY (exactly 32 bytes)

   # Update docker-compose.yml with generated values
   ```

2. **Deploy**
   ```bash
   docker-compose up -d
   ```

3. **Run Migrations**
   ```bash
   docker-compose exec app /app/bin/onetime eval "OneTime.Release.migrate"
   ```

## API Usage

### Create a Secret

```bash
curl -X POST http://localhost:4000/api/v1/secrets \
  -H "Content-Type: application/json" \
  -d '{
    "secret": {
      "content": "My secret message",
      "ttl": 3600,
      "passphrase": "optional_passphrase",
      "max_views": 1
    }
  }'
```

Response:
```json
{
  "success": true,
  "data": {
    "key": "abc123xyz",
    "url": "http://localhost:4000/secret/abc123xyz",
    "expires_at": "2025-01-02T12:00:00Z",
    "max_views": 1
  }
}
```

### Retrieve a Secret

```bash
curl -X POST http://localhost:4000/api/v1/secrets/abc123xyz \
  -H "Content-Type: application/json" \
  -d '{"passphrase": "optional_passphrase"}'
```

### Get Metadata

```bash
curl http://localhost:4000/api/v1/secrets/abc123xyz/metadata
```

### Burn a Secret

```bash
curl -X DELETE http://localhost:4000/api/v1/secrets/abc123xyz
```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | Required |
| `SECRET_KEY_BASE` | Phoenix secret key (64 bytes) | Required |
| `ENCRYPTION_KEY` | Master encryption key (32 bytes) | Required |
| `GUARDIAN_SECRET` | JWT signing secret | Required |
| `PHX_HOST` | Hostname for URL generation | `localhost` |
| `PHX_PORT` | HTTP port | `4000` |
| `REDIS_URL` | Redis connection string | Optional |
| `MAX_SECRET_SIZE` | Maximum secret size in bytes | `1048576` |
| `DEFAULT_TTL` | Default TTL in seconds | `604800` (7 days) |
| `MAX_TTL` | Maximum allowed TTL | `7776000` (90 days) |
| `ENABLE_REGISTRATION` | Allow user registration | `true` |
| `RATE_LIMIT_PER_MINUTE` | API rate limit | `60` |

## Security

### Encryption

- **Algorithm**: AES-256-GCM with authenticated encryption
- **Key Derivation**: PBKDF2-HMAC-SHA256 (10,000 iterations)
- **Password Hashing**: Argon2 with secure defaults
- **Random Generation**: Cryptographically secure (`crypto.strong_rand_bytes`)

### Best Practices

1. **Never** commit `.env` files or secrets to version control
2. **Always** use HTTPS in production
3. **Rotate** encryption keys periodically (see migration guide)
4. **Enable** rate limiting in production
5. **Monitor** logs for suspicious activity
6. **Backup** database with encrypted backups
7. **Update** dependencies regularly

## Architecture

```
lib/
├── onetime/              # Business logic contexts
│   ├── secrets/          # Secret management
│   │   ├── secret.ex     # Secret schema
│   │   └── janitor.ex    # Cleanup GenServer
│   ├── accounts/         # User management
│   │   └── user.ex       # User schema
│   ├── vault.ex          # Encryption service
│   ├── application.ex    # OTP application
│   └── repo.ex           # Ecto repository
├── onetime_web/          # Web interface
│   ├── live/             # LiveView modules
│   ├── controllers/      # REST controllers
│   ├── components/       # Reusable UI components
│   └── endpoint.ex       # Phoenix endpoint
└── onetime_crypto/       # Encryption library
    └── vault.ex          # Crypto operations
```

## Testing

```bash
# Run all tests
mix test

# Run with coverage
mix coveralls

# Run specific test file
mix test test/onetime/secrets_test.exs

# Run property-based tests
mix test --only property
```

## Development

### Code Quality

```bash
# Format code
mix format

# Static analysis
mix credo --strict

# Type checking
mix dialyzer
```

### Database

```bash
# Create migration
mix ecto.gen.migration migration_name

# Run migrations
mix ecto.migrate

# Rollback
mix ecto.rollback

# Reset database
mix ecto.reset
```

## Deployment

See [DEPLOYMENT.md](DEPLOYMENT.md) for comprehensive deployment instructions.

### Production Checklist

- [ ] Generate secure random values for all secrets
- [ ] Configure SSL/TLS certificates
- [ ] Set up database backups
- [ ] Configure monitoring (Telemetry + your tool)
- [ ] Set up log aggregation
- [ ] Enable rate limiting with Redis
- [ ] Configure firewall rules
- [ ] Set appropriate `MAX_SECRET_SIZE`
- [ ] Review OWASP Top 10 compliance
- [ ] Test disaster recovery procedures

### Release

```bash
# Build production release
MIX_ENV=prod mix release

# Start release
_build/prod/rel/onetime/bin/onetime start

# Run migrations in production
_build/prod/rel/onetime/bin/onetime eval "OneTime.Release.migrate"
```

## Contributing

We welcome contributions! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow Elixir style guide
- Add tests for new features
- Update documentation
- Run `mix format` before committing
- Ensure `mix credo` passes

## Documentation

- [API Documentation](API.md)
- [Deployment Guide](DEPLOYMENT.md)
- [Security Best Practices](SECURITY.md)

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Acknowledgments

- Original [OneTimeSecret](https://github.com/onetimesecret/onetimesecret) Ruby implementation
- Phoenix Framework team
- Elixir community

## Support

- **Issues**: GitHub Issues
- **Documentation**: `/docs` directory
- **Security**: Please report security vulnerabilities privately

## Roadmap

- [ ] Mobile applications (React Native)
- [ ] Browser extensions
- [ ] CLI tool
- [ ] File upload support
- [ ] Secret sharing via QR codes
- [ ] Advanced analytics dashboard
- [ ] LDAP/SAML authentication
- [ ] Multi-tenancy support
- [ ] Custom branding options

---

Built with ❤️ using Elixir and Phoenix