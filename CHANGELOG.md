# Changelog

## Docker Compose Override Pattern (Latest)

### Overview

Resolved Docker Compose v2 conflict ("services.app conflicts with imported resource") by switching to Docker Compose's override pattern. This approach separates base infrastructure from application-specific configuration.

### Architecture

```
docker-compose.yml              (Base Infrastructure)
├─ networks: ingress-net, egress-net, internet
├─ services: ingress, egress
└─ x-proxy-env anchor

docker-compose.override.yml     (Application Config)
├─ networks: db-net
├─ services: app, database
├─ x-pgsql-creds anchor
└─ volumes: db_data, code_m2, code_vol
```

### Changes

1. **Removed docker-compose.base.yml**
   - Deleted problematic base file that caused the conflict

2. **Refactored docker-compose.yml**
- Now contains ONLY base infrastructure
- Services: ingress (reverse proxy), egress (outbound proxy)
- Networks: ingress-net, egress-net, internet
- App service stub defines proxy environment variables and networks

3. **Created docker-compose.override.yml**
   - Contains application-specific configuration
   - Services: app (Java app), database (PostgreSQL)
   - Networks: db-net (internal database network)
   - Database credentials and app configuration
   - Volumes for app code and Maven cache

4. **How It Works**
   - Docker Compose automatically merges both files
   - Naming convention: `docker-compose.yml` (base) + `docker-compose.override.yml` (overrides)
   - App service is extended with database connection and network definitions
   - No conflicts because services aren't redefined, they're composed

### Result

✓ No Docker Compose warnings or errors
✓ Clear separation of concerns (infra vs app)
✓ Easy to customize per environment (dev/prod)
✓ Standard Docker Compose pattern
✓ Scales well for multiple applications

### Development Notes

- Override file automatically applied when running `docker compose` commands
- To use only base infrastructure: `docker compose -f docker-compose.yml`
- Database-only development: `docker compose -f docker-compose.override.yml up database`

---

## Branch: updates/docker-and-config

### Overview

This branch introduced significant Docker Compose and configuration improvements to consolidate infrastructure services and improve app networking.

### Commits

- `cd275d0`: Bring all ingress and egress into base
- `69b9ae0`: Move ingress and egress services to base compose file
- `c23bacd`: Merge main and update Docker configuration and egress Dockerfile

### Changes

1. **Consolidated Docker Compose Files**
   - Moved ingress and egress service definitions to `docker-compose.base.yml`
   - `docker-compose.yml` now includes `docker-compose.base.yml`
   - This separation allows cleaner management of base infrastructure vs. application-specific config

2. **Removed SSH-only Dockerfile**
   - Deleted `Dockerfile.ssh` (was an alternative SSH-based entry point)
   - Now only one app Dockerfile with SSH support built-in

3. **Improved App Container Networking**
   - App container now explicitly connects to both `ingress-net` and `egress-net`
   - App container automatically receives proxy environment variables from `docker-compose.base.yml`
   - Environment variables defined in base file are merged into app service

4. **Proxy Environment Variable Management**
   - Introduced YAML anchor `x-proxy-env` in `docker-compose.base.yml`
   - App container automatically uses:
     - `http_proxy=http://egress:3128`
     - `https_proxy=http://egress:3128`
     - `no_proxy=egress`

5. **Egress Dockerfile Minor Update**
   - Updated to ensure proper command syntax

### File Structure

```
docker-compose.yml          # Application and database config
├─ include: docker-compose.base.yml
└─ services: app, database

docker-compose.base.yml     # Base infrastructure
├─ networks: ingress-net, egress-net, internet
├─ services: ingress, egress
└─ x-proxy-env anchor
```

### Removed Files

- `Dockerfile.ssh` - SSH-specific Dockerfile (functionality merged into main Dockerfile)

### Benefits

1. **Network Isolation**: Three isolated networks prevent unauthorized inter-service communication
2. **Automatic Proxy Configuration**: App automatically configured for egress filtering
3. **Clean Separation of Concerns**: Base infrastructure separate from application config
4. **Scalability**: Easy to add multiple application services sharing the same infrastructure

### Known Issues

**Docker Compose Service Conflict**: The current structure causes Docker Compose v2 to report "services.app conflicts with imported resource". This is due to the `app` service being partially defined in both `docker-compose.base.yml` (for proxy environment and network extensions) and `docker-compose.yml` (for the full service definition). While the configuration is logically sound for the merge, Docker Compose v2 doesn't fully support this pattern. 

**Workaround**: The configuration still works despite the warning. Future refactoring options:
- Remove the `app` service definition from base and use `extends`
- Keep full definition in one file only
- Reorganize to avoid partial service definitions
