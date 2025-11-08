# Customization Guide

This document explains how to customize various components of the Java Secure Development Environment.

## Table of Contents

1. [Modifying Service Ports](#modifying-service-ports)
2. [Database Configuration](#database-configuration)
3. [SSH Configuration](#ssh-configuration)
4. [Egress Proxy (Squid) Configuration](#egress-proxy-squid-configuration)
5. [Ingress Reverse Proxy (Caddy) Configuration](#ingress-reverse-proxy-caddy-configuration)
6. [Environment Variables](#environment-variables)
7. [Docker Compose Configuration](#docker-compose-configuration)
8. [Resource Limits](#resource-limits)

## Modifying Service Ports

### Changing Published Ports

Ports are defined in `docker-compose.yml` under the `ingress` service:

```yaml
ingress:
    ports:
        - name: https
          published: 443          # Change this
          target: 443
        - name: http
          published: 80           # Change this
          target: 80
```

**Example**: To use ports 8443 and 8080:

```yaml
ports:
    - name: https
      published: 8443
      target: 443
    - name: http
      published: 8080
      target: 80
```

Then access via: https://www.localhost:8443

> **Note**: Only the `published` port needs to change. The `target` port (internal to container) stays the same.

### SSH Port Mapping

SSH port mapping is not enabled by default. To enable SSH access, edit `docker-compose.override.yml` and add a `ports` section to the `app` service:

```yaml
# docker-compose.override.yml
services:
  app:
    ports:
      - "2222:22"
```

Then run:
```bash
docker compose up -d
```

You can then connect via:
```bash
ssh dev@localhost -p 2222
```

## Database Configuration

Database settings are in `docker-compose.override.yml`:

```yaml
x-pgsql-creds: &db-creds
    POSTGRES_USER: psqladmin        # Change username
    POSTGRES_PASSWORD: secret       # Change password
    POSTGRES_DB: app_db             # Change database name
```

### Changing Database Credentials

Edit `docker-compose.override.yml` and update the `x-pgsql-creds` block:

```yaml
x-pgsql-creds: &db-creds
    POSTGRES_USER: myuser
    POSTGRES_PASSWORD: mysecurepassword
    POSTGRES_DB: myappdb
```

Then rebuild and restart:

```bash
docker compose down
docker compose up -d --build
```

### Changing Database Memory/CPU Limits

In `docker-compose.override.yml`, modify the `database` service:

```yaml
database:
    deploy:
        resources:
            limits:
                cpus: "1.0"          # Increase from 0.5
                memory: 512m         # Increase from 128m
```

### Using a Different PostgreSQL Version

Change the image in `docker-compose.override.yml`:

```yaml
database:
    image: postgres:15-alpine  # Change from 16-alpine
```

## SSH Configuration

SSH daemon configuration is in `sshd-config/user-dev-enable.conf`:

```conf
PermitRootLogin no              # Allow root login (not recommended)
PasswordAuthentication no        # Allow password auth
PubkeyAuthentication yes         # Disable public key auth
ListenAddress 0.0.0.0           # Change listen address
ListenAddress ::
AllowUsers dev                   # Add more users
```

### Allowing Additional Users

To add more users with SSH access, edit `sshd-config/user-dev-enable.conf`:

```conf
AllowUsers dev user2 user3
```

Then modify the `Dockerfile` to create additional users:

```dockerfile
RUN adduser --disabled-password --comment "user2" --shell /bin/bash user2 && \
    adduser --disabled-password --comment "user3" --shell /bin/bash user3
```

### Enabling Password Authentication

In `sshd-config/user-dev-enable.conf`, change:

```conf
PasswordAuthentication yes       # Instead of no
```

> **Security Note**: Password auth is disabled by default for security. Re-enabling reduces security.

### Changing SSH Port

The SSH daemon listens on port 22 inside the container. To expose it:

Edit `docker-compose.yml` and add to the `app` service:

```yaml
app:
    ports:
        - "2222:22"              # Host:Container
```

## Egress Proxy (Squid) Configuration

Squid configuration is in `egress/squid.conf`.

### Changing Proxy Port

In `egress/squid.conf`:

```conf
http_port 3128              # Change this
```

Then update proxy references in `docker-compose.yml`:

```yaml
x-proxy-env: &proxy-env 
    http_proxy: http://egress:3129    # Update this
    https_proxy: http://egress:3129   # Update this
```

### Adding Domain Blacklist/Whitelist

Domain lists are in `egress/domain-lists.d/`:

Create a new file like `egress/domain-lists.d/example-block.txt`:

```
.example.com
.blocked-site.org
.internal-only.local
```

Then reference in `squid.conf`:

```conf
acl blocked_domains dstdom_regex "/etc/squid/domain-lists.d/example-block.txt"
http_access deny blocked_domains
```

### Adding Certificate Revocation Lists

CRL files go in `egress/crl-lists.d/` and are referenced in `squid.conf`.

### Changing Squid Caching Behavior

Edit `egress/squid.conf` to modify cache settings:

```conf
cache_dir ufs /var/cache/squid 1000 16 256    # Cache size in MB, directories
cache_mem 256 MB                              # RAM cache
maximum_object_size 4 GB                      # Max cacheable object size
```

## Ingress Reverse Proxy (Caddy) Configuration

Caddy configuration is in `ingress/Caddyfile`.

### Changing the Domain

In `ingress/Caddyfile`:

```caddy
www.localhost {              # Change this
    tls internal
    # ... rest of config
}
```

Example for custom domain:

```caddy
myapp.example.com {
    tls /etc/caddy/tls/cert.pem /etc/caddy/tls/key.pem
    # ... rest of config
}
```

### Adding Additional Routes

```caddy
www.localhost {
    # ... existing config ...

    handle /api/* {
        reverse_proxy api:8081
    }

    handle /admin/* {
        reverse_proxy admin:9000
    }
}
```

### Enabling Prometheus Metrics

In `ingress/Caddyfile`:

```caddy
{
    admin off
    # ... existing config ...
}

www.localhost {
    # ... existing config ...
    metrics /metrics              # Uncomment or add this
}
```

### Adding Custom Headers

```caddy
www.localhost {
    header {
        # existing headers...
        X-Custom-Header "custom-value"
        X-App-Version "1.0.0"
    }
}
```

### Setting Up HTTPS with Real Certificates

Replace the `tls internal` line:

```caddy
www.localhost {
    tls /path/to/cert.pem /path/to/key.pem
    # ... rest of config
}
```

Then mount the certificate files in `docker-compose.yml`:

```yaml
ingress:
    volumes:
        - ./secrets/certs:/etc/caddy/tls:ro
```

## Environment Variables

### App Container Environment Variables

Edit `docker-compose.override.yml` app service to add custom variables:

```yaml
app:
    environment:
        DB_HOST: database
        DB_PORT: 5432
        <<: *db-creds
        JAVA_OPTS: "-Xmx512m -Xms256m"
        APP_DEBUG: "true"
```

### Proxy Environment Variables

In `docker-compose.yml`:

```yaml
x-proxy-env: &proxy-env 
    http_proxy: http://egress:3128
    https_proxy: http://egress:3128
    no_proxy: egress,localhost
```

## Docker Compose Configuration

The project uses two files:
- `docker-compose.yml` - Base infrastructure (ingress, egress)
- `docker-compose.override.yml` - Application config (app, database)

Modifications to app/database should go in `docker-compose.override.yml`.
Modifications to ingress/egress should go in `docker-compose.yml`.

### Changing Container Image Names

For the app and database services, modify `docker-compose.override.yml`:

```yaml
app:
    image: company/custom-app:latest
```

For ingress/egress, modify `docker-compose.yml`:

```yaml
ingress:
    image: company/custom-ingress:latest

egress:
    image: company/custom-egress:latest
```

### Adding New Services

For application-level services like caches or queues, add to `docker-compose.override.yml`:

```yaml
redis:
    image: redis:7-alpine
    networks:
        - cache-net
    deploy:
        resources:
            limits:
                cpus: "0.1"
                memory: 64m
```

And create the network in `docker-compose.override.yml`:

```yaml
networks:
    cache-net:
        internal: true
```

### Changing Volume Mounts

In `docker-compose.override.yml`:

```yaml
app:
    volumes:
        - custom_code:/code              # Use different volume name
        - /local/path:/container/path    # Bind mount from host
```

## Resource Limits

### CPU and Memory Limits

Edit limits in `docker-compose.yml` or `docker-compose.override.yml`, depending on the service:

```yaml
ingress:
    deploy:
        resources:
            limits:
                cpus: "0.5"              # 50% of 1 CPU
                memory: 64m              # 64 MB RAM
            reservations:                # Minimum guaranteed
                cpus: "0.1"
                memory: 32m
```

Common settings:

- **Light services** (cache, queue): 0.1 CPU, 32-64m memory
- **Medium services** (proxy): 0.2-0.5 CPU, 64-256m memory
- **Heavy services** (database, app): 0.5-1.0 CPU, 256m-1g memory

### Changing Volume Sizes

For PostgreSQL data directory in `docker-compose.override.yml`, if you need to resize the volume:

```bash
# Stop services
docker compose down

# Remove the volume
docker volume rm java-secure-dev-env_db_data

# Restart
docker compose up -d
```

The new volume will be initialized with the new size.

## Rebuilding After Customization

After making any changes:

```bash
# Rebuild affected services
docker compose build --no-cache

# Restart services
docker compose down
docker compose up -d

# Verify
docker compose ps
docker compose logs -f
```

## Testing Customizations

### Test Proxy Changes

```bash
docker compose exec app curl -x http://egress:3128 http://example.com
```

### Test Ingress Changes

```bash
# Inside ingress container
docker compose exec ingress caddy validate --config /etc/caddy/Caddyfile

# Test reverse proxy
curl -k https://www.localhost
```

### Test Database Changes

```bash
docker compose exec app psql -h database -U psqladmin -d app_db
```

## Common Customization Scenarios

### Scenario 1: Corporate Proxy with Authentication

In `egress/squid.conf`:

```conf
http_port 3128
cache_peer proxy.corporate.com parent 8080 0
cache_peer_access proxy.corporate.com allow all

authenticate_ttl 1 hour
auth_param basic program /usr/lib/squid/basic_auth_helper /etc/squid/auth.txt
```

### Scenario 2: Development with Multiple Apps

In `docker-compose.override.yml`, add additional services:

```yaml
app2:
    image: mandraketech.internal/secure-dev
    build:
        context: ./app2
    networks:
        - db-net
        - ingress-net
        - egress-net
```

In `ingress/Caddyfile`:

```caddy
app1.localhost {
    reverse_proxy app:8080
}

app2.localhost {
    reverse_proxy app2:8080
}
```

### Scenario 3: Production-Like TLS

Generate certificates and mount them:

```bash
# Generate self-signed cert
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes

# Copy to secrets
mkdir -p secrets/certs
cp cert.pem key.pem secrets/certs/
```

In `ingress/Caddyfile`:

```caddy
www.example.com {
    tls /etc/caddy/tls/cert.pem /etc/caddy/tls/key.pem
}
```

In `docker-compose.yml`:

```yaml
ingress:
    volumes:
        - ./secrets/certs:/etc/caddy/tls:ro
```

For more information on individual components, consult their official documentation:

- [Caddy Documentation](https://caddyserver.com/docs/)
- [Squid Documentation](http://www.squid-cache.org/doc/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
