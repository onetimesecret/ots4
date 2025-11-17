# OneTimeSecret - Elixir Implementation

A modern, secure implementation of OneTimeSecret in Elixir/Phoenix. Share sensitive information safely with one-time links that automatically expire after viewing.

## 🚀 Features

- **One-Time Secrets**: Secrets are automatically deleted after being viewed once
- **Time-Based Expiration**: Set custom TTL for secrets (up to 7 days)
- **Passphrase Protection**: Optional passphrase encryption for additional security
- **AES-256-GCM Encryption**: Industry-standard encryption for all secrets
- **Rate Limiting**: Redis-backed distributed rate limiting
- **RESTful API**: Full JSON API for programmatic access
- **Real-time Monitoring**: Built-in telemetry and health checks
- **Fault Tolerant**: OTP supervision trees for automatic recovery
- **Scalable**: Redis-backed storage with connection pooling

## 🏗️ Architecture

### Tech Stack

- **Elixir**: 1.16+
- **Phoenix**: 1.7+
- **Redis**: 7.0+ (via Redix)
- **OTP**: 26+

### Application Structure

```
lib/
├── onetimesecret/              # Business logic layer
│   ├── secrets/                # Secret management context
│   │   ├── secret.ex           # Secret struct and validation
│   │   ├── encryption.ex       # AES-256-GCM encryption
│   │   ├── storage.ex          # Redis storage adapter
│   │   └── supervisor.ex       # Secrets supervision tree
│   ├── redis/                  # Redis connection management
│   │   └── supervisor.ex       # Connection pool supervisor
│   ├── redis.ex                # Redis client wrapper
│   └── application.ex          # OTP Application supervisor
├── onetimesecret_web/          # Web layer
│   ├── controllers/            # HTTP controllers
│   │   ├── api/                # API endpoints
│   │   ├── page_controller.ex
│   │   └── secret_controller.ex
│   ├── plugs/                  # Custom plugs
│   │   └── rate_limiter.ex     # Rate limiting
│   ├── components/             # Phoenix components
│   ├── endpoint.ex             # Phoenix endpoint
│   ├── router.ex               # Route definitions
│   └── telemetry.ex            # Metrics and monitoring
└── config/                     # Configuration files
```

### OTP Supervision Tree

```
OneTimeSecret.Application
├── OneTimeSecretWeb.Telemetry
├── Phoenix.PubSub
├── OneTimeSecret.Redis.Supervisor
│   └── Redix connection pool (10 connections)
├── OneTimeSecret.Secrets.Supervisor
└── OneTimeSecretWeb.Endpoint
```

## 🔐 Security Features

### Encryption
- **AES-256-GCM**: Authenticated encryption with associated data (AEAD)
- **PBKDF2**: Key derivation for passphrase-based secrets (100,000 iterations)
- **Random IVs**: Unique initialization vector for each encryption
- **Secure Key Storage**: Master key from environment variables

### Application Security
- **CSRF Protection**: Built-in Phoenix CSRF tokens
- **Rate Limiting**: Per-IP, per-endpoint rate limits via Redis
- **Input Validation**: Strict validation of all secret attributes
- **Secure Headers**: Content Security Policy and security headers
- **Static Analysis**: Sobelow security scanning integration

### Data Protection
- **Burn After Reading**: Secrets automatically deleted after first view
- **Time-Based Expiration**: Redis TTL ensures automatic cleanup
- **No Persistent Storage**: All data stored in Redis with expiration
- **Metadata Isolation**: View tracking separate from secret data

## 📦 Installation

### Prerequisites

- Elixir 1.16 or later
- Erlang/OTP 26 or later
- Redis 7.0 or later

### Setup

1. Clone the repository:
```bash
git clone https://github.com/yourusername/onetimesecret-elixir.git
cd onetimesecret-elixir
```

2. Install dependencies:
```bash
mix deps.get
```

3. Configure environment variables:
```bash
export REDIS_HOST=localhost
export REDIS_PORT=6379
export ENCRYPTION_KEY=$(mix phx.gen.secret)
export SECRET_KEY_BASE=$(mix phx.gen.secret)
```

4. Start Redis:
```bash
redis-server
```

5. Run tests:
```bash
mix test
```

6. Start the application:
```bash
mix phx.server
```

The application will be available at `http://localhost:4000`.

## 🔧 Configuration

### Environment Variables

#### Required (Production)
- `SECRET_KEY_BASE` - Phoenix secret key (generate with `mix phx.gen.secret`)
- `ENCRYPTION_KEY` - Master encryption key (32+ characters)

#### Optional
- `REDIS_HOST` - Redis host (default: `localhost`)
- `REDIS_PORT` - Redis port (default: `6379`)
- `REDIS_PASSWORD` - Redis password (if authentication enabled)
- `REDIS_SSL` - Enable SSL for Redis (default: `false`)
- `REDIS_DATABASE` - Redis database number (default: `0`)
- `REDIS_POOL_SIZE` - Connection pool size (default: `10`)
- `DEFAULT_TTL` - Default secret TTL in seconds (default: `86400` = 1 day)
- `MAX_TTL` - Maximum secret TTL in seconds (default: `604800` = 7 days)
- `MAX_SECRET_SIZE` - Maximum secret size in bytes (default: `1000000` = 1MB)
- `PHX_HOST` - Production host (default: `example.com`)
- `PORT` - HTTP port (default: `4000`)

### Redis Data Model

```
Keys:
  secret:<key>              # Secret data (hash)
  secret:<key>:metadata     # Metadata (string with TTL)
  secret:<key>:views        # View tracking (list)
  rate:<ip>:<endpoint>      # Rate limiting (string with TTL)
```

## 📚 API Documentation

### Create Secret

**POST** `/api/secret`

```json
{
  "value": "my secret data",
  "ttl": 3600,
  "passphrase": "optional-passphrase",
  "recipient": "optional-recipient-id"
}
```

**Response:**
```json
{
  "status": "success",
  "data": {
    "key": "abc123def456",
    "ttl": 3600,
    "expires_at": "2024-01-01T12:00:00Z",
    "passphrase_required": false,
    "share_url": "https://example.com/secret/abc123def456"
  }
}
```

### Retrieve Secret

**GET** `/api/secret/:key`

Query parameters:
- `passphrase` - Required if secret was created with passphrase

**Response:**
```json
{
  "status": "success",
  "data": {
    "value": "my secret data",
    "created_at": "2024-01-01T11:00:00Z",
    "recipient": null
  }
}
```

### Get Metadata

**GET** `/api/secret/:key/metadata`

Returns metadata without burning the secret.

### Burn Secret

**POST** `/api/secret/:key/burn`

Manually delete a secret before it's viewed.

### Statistics

**GET** `/api/stats`

Returns current statistics about stored secrets.

### Health Check

**GET** `/health`

Returns application health status including Redis connectivity.

## 🧪 Testing

### Run All Tests
```bash
mix test
```

### Run with Coverage
```bash
mix test --cover
```

### Security Scanning
```bash
mix sobelow --config
```

### Code Quality
```bash
mix credo --strict
```

### Static Analysis
```bash
mix dialyzer
```

## 🚢 Production Deployment

### Using Releases

1. Build a production release:
```bash
MIX_ENV=prod mix release
```

2. Set environment variables in your production environment

3. Run the release:
```bash
_build/prod/rel/onetimesecret/bin/onetimesecret start
```

### Docker Deployment

A `Dockerfile` can be created following Elixir release best practices.

### Environment-Specific Configuration

All production configuration is handled via environment variables in `config/runtime.exs`, following the Twelve-Factor App methodology.

## 🔍 Monitoring & Observability

### Telemetry
Built-in telemetry events for:
- HTTP request metrics
- Secret creation/retrieval metrics
- Redis connection pool metrics
- VM metrics (memory, schedulers)

### Live Dashboard
Access the Phoenix LiveDashboard in development at:
```
http://localhost:4000/dev/dashboard
```

### Health Checks
Health endpoint at `/health` returns:
- Application status
- Redis connectivity
- Timestamp

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Standards
- Follow the Elixir Style Guide
- Run `mix format` before committing
- Ensure all tests pass (`mix test`)
- Run security checks (`mix sobelow`)
- Maintain code quality (`mix credo --strict`)

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Original [OneTimeSecret](https://github.com/onetimesecret/onetimesecret) Ruby implementation
- Phoenix Framework team
- Elixir community

## 📞 Support

- **Documentation**: See inline documentation with `mix docs`
- **Issues**: GitHub Issues for bug reports and feature requests
- **Security**: Report security vulnerabilities privately

## 🗺️ Roadmap

- [ ] User accounts and secret history
- [ ] Custom secret URLs
- [ ] Email notifications
- [ ] Multi-language support (i18n)
- [ ] Browser extension
- [ ] Mobile app
- [ ] Secret analytics dashboard
- [ ] Webhook notifications
- [ ] S3 storage backend option
- [ ] GraphQL API

---

**Built with ❤️ using Elixir and Phoenix**