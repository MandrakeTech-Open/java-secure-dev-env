# Environment Setup Instructions

This document provides step-by-step instructions for setting up the Java Secure Development Environment.

## Prerequisites

- Docker and Docker Compose (version 2.0+)
- SSH key pair (Ed25519 recommended)
- Git

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/MandrakeTech-Open/java-secure-dev-env.git
cd java-secure-dev-env
```

### 2. Generate SSH Keys (if needed)

If you don't have an SSH key pair, generate one:

```bash
ssh-keygen -t ed25519 -C "your-email@example.com" -f ~/.ssh/id_ed25519
```

### 3. Run Setup Script

```bash
./setup.sh
```

This script will:
- Create necessary directories (`secrets/` folder)
- Validate SSH key presence
- Build and start all Docker services
- Display service endpoints

### 4. Verify Services Are Running

```bash
docker compose ps
```

You should see all services running (app, database, ingress, egress).

## Manual Setup (Alternative)

If you prefer to set up manually without the script:

```bash
# Create secrets directory
mkdir -p secrets

# Build all services
docker compose build --no-cache

# Start services
docker compose up -d

# Verify services
docker compose ps
```

## Accessing the Development Environment

### Web Application (Ingress)

- HTTPS: https://www.localhost:443
- Self-signed certificate (browser will warn, this is expected)

### SSH Access to Dev Container (Optional)

SSH access is not enabled by default. To enable SSH access, edit `docker-compose.override.yml` and add a `ports` section to the `app` service:

```yaml
# docker-compose.override.yml
services:
  app:
    ports:
      - "2222:22"
```

Then restart with:

```bash
docker compose up -d
```

Connect via:

```bash
ssh dev@localhost -p 2222
```

Default user: `dev`

Password authentication is disabled. Uses public key authentication only.

### Database Access

PostgreSQL is running on an internal network and is not directly accessible from the host. Access it through the app container:

```bash
docker compose exec app psql -h database -U psqladmin -d admin
```

Default credentials:
- User: `psqladmin`
- Password: `secret`
- Database: `admin`

## Docker Compose Configuration

The project uses Docker Compose's override pattern:

**docker-compose.yml** (Base Infrastructure):
- Ingress and egress proxy services
- Proxy environment variable definitions
- Networks: ingress-net, egress-net, internet

**docker-compose.override.yml** (Application Configuration):
- App container (Java application)
- Database container (PostgreSQL)
- Network: db-net
- Volumes for code and cache

Docker Compose automatically merges both files. This separation keeps infrastructure concerns separate from application configuration.

## Network Architecture

The environment uses four Docker networks:

1. **db-net** (Internal): Database network
   - Services: app, database
   - Purpose: Database communication only

2. **ingress-net** (Internal): Reverse proxy network
   - Services: app, ingress
   - Purpose: HTTPS ingress to application

3. **egress-net** (Internal): Outbound proxy network
   - Services: app, egress
   - Purpose: HTTP/HTTPS outbound proxy filtering

4. **internet** (External): Outbound internet access
   - Services: egress
   - Purpose: External internet connectivity

## Service Details

### App Container

- Image: `mandraketech.internal/secure-dev`
- Based on: BellSoft Liberica OpenJDK with Debian
- Includes: SSH server, Git, Maven support
- Mounts: `/code` volume, Maven cache

### Database Container

- Image: `postgres:16-alpine`
- Port: 5432 (internal only)
- Default credentials: psqladmin/secret

### Ingress Container

- Image: `mandraketech.internal/ingress`
- Based on: Caddy 2 Alpine
- Function: HTTPS reverse proxy to app
- Ports: 80, 443

### Egress Container

- Image: `mandraketech.internal/egress`
- Based on: Alpine with Squid
- Function: HTTP/HTTPS outbound proxy filtering
- Port: 3128 (internal only)

## Proxy Configuration

The app container is automatically configured to use the egress proxy:

- `http_proxy`: http://egress:3128
- `https_proxy`: http://egress:3128
- `no_proxy`: egress (bypass proxy for egress service itself)

## Environment Variables

The app container receives the following environment variables:

```
DB_HOST=database
DB_PORT=5432
DB_USER=psqladmin
DB_PASSWORD=secret
DB_DATABASE=admin
http_proxy=http://egress:3128
https_proxy=http://egress:3128
no_proxy=egress
```

## Common Commands

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f app
docker compose logs -f database
docker compose logs -f ingress
docker compose logs -f egress
```

### Stop Services

```bash
docker compose down
```

### Rebuild Services

```bash
docker compose build --no-cache
docker compose up -d
```

### Enter a Container

```bash
# App container
docker compose exec app bash

# Database container
docker compose exec database bash
```

### Test Egress Proxy

```bash
# Execute tester script inside egress container
docker compose exec egress /usr/local/bin/tester.sh
```

## Troubleshooting

### SSH Connection Refused

**Issue**: Cannot connect via SSH
```
ssh: connect to host localhost port 2222: Connection refused
```

**Solution**:
- Ensure the app container is running: `docker compose ps`
- Check logs: `docker compose logs app`
- Verify SSH keys are mounted correctly

### Database Connection Errors

**Issue**: Cannot connect to database
```
psql: error: could not connect to server
```

**Solution**:
- Database is only accessible from within app container
- Use `docker compose exec app` to access it
- Verify database container is running: `docker compose ps`

### Port Already in Use

**Issue**: Ports 80 or 443 already in use
```
Error response from daemon: driver failed programming external connectivity on endpoint ingress
```

**Solution**:
```bash
# Find what's using the port
lsof -i :443

# Change ports in docker-compose.yml if needed
```

### Proxy Not Working

**Issue**: Outbound connections fail despite proxy configuration

**Solution**:
- Verify egress container is running: `docker compose ps`
- Check egress logs: `docker compose logs egress`
- Test proxy directly: `docker compose exec app curl -x http://egress:3128 http://example.com`

## Next Steps

Once the environment is set up:

1. SSH into the app container
2. Review the `/code` volume (shared with host)
3. Check database access from the container
4. Review the proxy/ingress configurations in respective config files

For more details on customization, see [CUSTOMIZE.md](CUSTOMIZE.md).
