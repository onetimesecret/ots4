# OneTimeSecret - Elixir Community Edition

A modern, security-first secret sharing application built with Elixir and Phoenix. Share passwords, API keys, and sensitive data that automatically self-destruct after viewing.

## Features

- 🔒 **End-to-End Encryption**: All secrets encrypted with AES-256-GCM
- ⏰ **Automatic Expiration**: Secrets self-destruct after viewing or time limit
- 🔑 **Passphrase Protection**: Optional additional passphrase layer
- 🚀 **High Performance**: Built on Erlang/OTP for reliability and scalability
- 📊 **Analytics**: Track usage patterns and secret lifecycle
- 🌐 **REST API**: Full API v2 compatibility for programmatic access
- 💻 **LiveView Interface**: Modern, responsive web UI
- 🐳 **Docker Ready**: Easy deployment with Docker and Docker Compose

## Architecture

### Technology Stack

- **Phoenix Framework**: 1.7+ with LiveView for real-time interactions
- **Elixir**: 1.15+ with OTP 26
- **Mnesia**: Distributed Erlang database for persistent storage
- **ETS**: High-performance caching and rate limiting
- **Cloak.Ecto**: Field-level encryption for sensitive data

### Security Features

- AES-256-GCM encryption at rest
- Secure key management with process-level sensitivity flags
- Rate limiting per IP and API key
- CSRF protection for web interface
- Content Security Policy (CSP) headers
- HTTP Strict Transport Security (HSTS)
- Comprehensive audit logging

## Quick Start

### Prerequisites

- Elixir 1.15 or later
- Erlang/OTP 26 or later
- Node.js 18+ (for asset compilation)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/ots4.git
   cd ots4
   ```

2. Install dependencies:
   ```bash
   mix deps.get
   cd assets && npm install && cd ..
   ```

3. Set up the database:
   ```bash
   mix onetimesecret.setup
   ```

4. Start the Phoenix server:
   ```bash
   mix phx.server
   ```

5. Visit [`localhost:4000`](http://localhost:4000) in your browser.

### Using Docker

For the easiest setup, use Docker Compose:

```bash
docker-compose up
```

The application will be available at [`localhost:4000`](http://localhost:4000).

## Configuration

### Environment Variables

Create a `.env` file or export these variables:

```bash
# Required for production
export SECRET_KEY_BASE="your-secret-key-base"  # Generate with: mix phx.gen.secret
export ENCRYPTION_KEY="your-base64-encoded-key"  # Generate with: mix phx.gen.secret 32 | base64

# Optional
export PHX_HOST="example.com"
export PORT="4000"
export MNESIA_DIR="priv/mnesia/prod"
```

### Generating Secure Keys

```bash
# Generate secret key base
mix phx.gen.secret

# Generate encryption key
mix phx.gen.secret 32
```

## API Usage

### Create a Secret

```bash
curl -X POST http://localhost:4000/api/v2/share \
  -H "Content-Type: application/json" \
  -d '{
    "secret": "my secret content",
    "ttl": 3600,
    "passphrase": "optional-passphrase"
  }'
```

Response:
```json
{
  "secret_key": "abc123...",
  "metadata_key": "xyz789...",
  "ttl": 3600,
  "expires_at": "2025-01-01T12:00:00Z"
}
```

### Retrieve a Secret

```bash
curl http://localhost:4000/api/v2/secret/abc123
```

Response:
```json
{
  "secret": "my secret content",
  "view_count": 1,
  "remaining_views": 0
}
```

### Burn a Secret

```bash
curl -X POST http://localhost:4000/api/v2/secret/abc123/burn
```

## Development

### Running Tests

```bash
mix test
```

### Code Formatting

```bash
mix format
```

### Generate Documentation

```bash
mix docs
```

Documentation will be available in `doc/index.html`.

## Project Structure

```
lib/
├── onetimesecret/              # Core business logic
│   ├── secrets/                # Secret management context
│   │   ├── secret.ex           # Secret schema with encryption
│   │   ├── metadata.ex         # Secret metadata schema
│   │   └── sweeper.ex          # Background cleanup worker
│   ├── accounts/               # User and API key management
│   │   ├── user.ex
│   │   └── api_key.ex
│   ├── analytics/              # Usage tracking
│   ├── application.ex          # OTP application entry point
│   ├── vault.ex                # Cloak encryption vault
│   └── cache.ex                # ETS cache manager
├── onetimesecret_web/          # Web interface
│   ├── live/                   # LiveView components
│   ├── controllers/            # HTTP controllers
│   ├── api/v2/                 # REST API v2
│   └── plugs/                  # Authentication and rate limiting
```

## Deployment

### Production Release

Build a production release:

```bash
MIX_ENV=prod mix release
```

Run the release:

```bash
_build/prod/rel/onetimesecret/bin/onetimesecret start
```

### Docker Production

Build and run the production Docker image:

```bash
docker build -t onetimesecret:latest .
docker run -p 4000:4000 \
  -e SECRET_KEY_BASE="your-key" \
  -e ENCRYPTION_KEY="your-encryption-key" \
  onetimesecret:latest
```

## Mix Tasks

### Setup Mnesia Database

```bash
mix onetimesecret.setup
```

### Rotate Encryption Keys

```bash
NEW_ENCRYPTION_KEY="new-key..." mix onetimesecret.rotate_keys
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Security

For security issues, please email security@example.com instead of using the issue tracker.

## Acknowledgments

- Inspired by the original [OneTimeSecret](https://onetimesecret.com/)
- Built with the amazing [Phoenix Framework](https://www.phoenixframework.org/)
- Powered by the [Erlang/OTP](https://www.erlang.org/) platform

## Support

- Documentation: [https://hexdocs.pm/onetimesecret](https://hexdocs.pm/onetimesecret)
- Issues: [GitHub Issues](https://github.com/yourusername/ots4/issues)
- Discussions: [GitHub Discussions](https://github.com/yourusername/ots4/discussions)

---

Built with ❤️ using Elixir and Phoenix