# Deployment Guide

This guide covers deploying OneTimeSecret to production environments.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
- [Docker Deployment](#docker-deployment)
- [Manual Deployment](#manual-deployment)
- [Database Setup](#database-setup)
- [SSL/TLS Configuration](#ssltls-configuration)
- [Monitoring](#monitoring)
- [Backup & Recovery](#backup--recovery)

## Prerequisites

### System Requirements

- **OS**: Ubuntu 20.04+ or Debian 11+
- **RAM**: Minimum 2GB, recommended 4GB+
- **CPU**: 2+ cores
- **Disk**: 20GB+ SSD
- **Network**: Static IP or domain name

### Software Requirements

- Docker & Docker Compose (for containerized deployment)
- PostgreSQL 14+ (can be containerized)
- Redis 7+ (optional, for distributed rate limiting)
- Nginx (for reverse proxy)

## Environment Setup

### 1. Generate Secrets

```bash
# Install Elixir locally or use Docker
docker run --rm hexpm/elixir:1.15.7-erlang-26.1.2-debian-bullseye-20231009-slim \
  sh -c "mix local.hex --force && mix phx.gen.secret 64"

# Generate all required secrets
SECRET_KEY_BASE=$(mix phx.gen.secret 64)
GUARDIAN_SECRET=$(mix phx.gen.secret 64)
ENCRYPTION_KEY=$(mix phx.gen.secret 32)
```

### 2. Create Environment File

Create `.env.production`:

```bash
# Database
DATABASE_URL=postgresql://onetime:SECURE_PASSWORD@localhost:5432/onetime_prod

# Phoenix
SECRET_KEY_BASE=<generated-64-byte-secret>
PHX_HOST=secrets.yourdomain.com
PHX_PORT=4000

# Security
ENCRYPTION_KEY=<generated-32-byte-secret>
GUARDIAN_SECRET=<generated-64-byte-secret>

# Optional: Redis for distributed rate limiting
REDIS_URL=redis://localhost:6379/0

# Application Settings
MAX_SECRET_SIZE=1048576
DEFAULT_TTL=604800
MAX_TTL=7776000
ENABLE_REGISTRATION=true
RATE_LIMIT_PER_MINUTE=60

# Database Pool
POOL_SIZE=10
```

## Docker Deployment

### 1. Prepare Docker Compose

```yaml
version: '3.8'

services:
  db:
    image: postgres:14-alpine
    environment:
      POSTGRES_USER: onetime
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: onetime_prod
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backups:/backups
    restart: always
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U onetime"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    restart: always
    command: redis-server --appendonly yes

  app:
    build: .
    ports:
      - "127.0.0.1:4000:4000"
    depends_on:
      db:
        condition: service_healthy
    env_file:
      - .env.production
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  postgres_data:
  redis_data:
```

### 2. Build and Deploy

```bash
# Build image
docker-compose build

# Start services
docker-compose up -d

# Run migrations
docker-compose exec app /app/bin/onetime eval "OneTime.Release.migrate"

# Check logs
docker-compose logs -f app
```

### 3. Nginx Configuration

Create `/etc/nginx/sites-available/onetime`:

```nginx
upstream onetime {
    server 127.0.0.1:4000;
}

server {
    listen 80;
    server_name secrets.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name secrets.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/secrets.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/secrets.yourdomain.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    client_max_body_size 2M;

    location / {
        proxy_pass http://onetime;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # Security headers
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
}
```

Enable and restart Nginx:

```bash
sudo ln -s /etc/nginx/sites-available/onetime /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

## Manual Deployment

### 1. Install Dependencies

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Erlang & Elixir
wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb
sudo dpkg -i erlang-solutions_2.0_all.deb
sudo apt update
sudo apt install -y esl-erlang elixir

# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
```

### 2. Create Application User

```bash
sudo useradd -m -s /bin/bash onetime
sudo su - onetime
```

### 3. Deploy Application

```bash
# Clone repository
git clone <your-repo> /home/onetime/app
cd /home/onetime/app

# Install dependencies
mix deps.get --only prod
cd assets && npm install && cd ..

# Compile assets
mix assets.deploy

# Build release
MIX_ENV=prod mix release

# Copy release to deployment directory
cp -r _build/prod/rel/onetime ~/production
```

### 4. Create Systemd Service

Create `/etc/systemd/system/onetime.service`:

```ini
[Unit]
Description=OneTimeSecret
After=network.target postgresql.service

[Service]
Type=simple
User=onetime
Group=onetime
WorkingDirectory=/home/onetime/production
EnvironmentFile=/home/onetime/.env.production
ExecStart=/home/onetime/production/bin/onetime start
ExecStop=/home/onetime/production/bin/onetime stop
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=onetime

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable onetime
sudo systemctl start onetime
sudo systemctl status onetime
```

## Database Setup

### 1. Create PostgreSQL User and Database

```bash
sudo -u postgres psql

CREATE USER onetime WITH PASSWORD 'SECURE_PASSWORD';
CREATE DATABASE onetime_prod OWNER onetime;
\q
```

### 2. Run Migrations

```bash
# Docker
docker-compose exec app /app/bin/onetime eval "OneTime.Release.migrate"

# Manual
/home/onetime/production/bin/onetime eval "OneTime.Release.migrate"
```

### 3. Database Tuning

Edit `/etc/postgresql/14/main/postgresql.conf`:

```conf
# Memory
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 16MB
maintenance_work_mem = 128MB

# Checkpoints
checkpoint_completion_target = 0.9
wal_buffers = 16MB

# Query Planning
random_page_cost = 1.1
effective_io_concurrency = 200

# Logging
log_min_duration_statement = 1000
```

## SSL/TLS Configuration

### Using Let's Encrypt

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Obtain certificate
sudo certbot --nginx -d secrets.yourdomain.com

# Auto-renewal
sudo certbot renew --dry-run
```

## Monitoring

### 1. Health Checks

```bash
# Application health
curl https://secrets.yourdomain.com/health

# Database connection
docker-compose exec db psql -U onetime -d onetime_prod -c "SELECT 1"
```

### 2. Logs

```bash
# Application logs (Docker)
docker-compose logs -f app

# Application logs (Systemd)
journalctl -u onetime -f

# Nginx logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

### 3. Prometheus Metrics

Add to `config/prod.exs`:

```elixir
config :onetime, OneTimeWeb.Telemetry,
  metrics_port: 9568
```

## Backup & Recovery

### Database Backups

```bash
# Automated daily backup
cat > /etc/cron.daily/onetime-backup << 'EOF'
#!/bin/bash
BACKUP_DIR=/backups
DATE=$(date +%Y%m%d_%H%M%S)
docker-compose exec -T db pg_dump -U onetime onetime_prod | \
  gzip > $BACKUP_DIR/onetime_${DATE}.sql.gz

# Keep only last 30 days
find $BACKUP_DIR -name "onetime_*.sql.gz" -mtime +30 -delete
EOF

chmod +x /etc/cron.daily/onetime-backup
```

### Restore Database

```bash
# Stop application
docker-compose stop app

# Restore
gunzip -c /backups/onetime_20250101_120000.sql.gz | \
  docker-compose exec -T db psql -U onetime onetime_prod

# Start application
docker-compose start app
```

## Scaling

### Horizontal Scaling

1. Use external PostgreSQL and Redis
2. Deploy multiple app instances behind load balancer
3. Configure session store to use Redis
4. Ensure all instances share same `SECRET_KEY_BASE`

### Vertical Scaling

- Increase `POOL_SIZE` based on available connections
- Adjust Erlang VM flags in `rel/env.sh.eex`
- Monitor and tune PostgreSQL settings

## Troubleshooting

### Application won't start

```bash
# Check logs
journalctl -u onetime -n 100

# Verify environment
env | grep -E 'DATABASE_URL|SECRET_KEY_BASE|ENCRYPTION_KEY'

# Test database connection
psql $DATABASE_URL -c "SELECT 1"
```

### High memory usage

```bash
# Check Erlang processes
docker-compose exec app /app/bin/onetime rpc "erlang:memory()."

# Adjust VM flags
export ERL_OPTS="+K true +A 16 +SDio 16"
```

### Secrets not expiring

```bash
# Check janitor process
docker-compose exec app /app/bin/onetime rpc "Process.whereis(OneTime.Secrets.Janitor)"

# Manually trigger cleanup
docker-compose exec app /app/bin/onetime eval "OneTime.Secrets.delete_expired_secrets()"
```
