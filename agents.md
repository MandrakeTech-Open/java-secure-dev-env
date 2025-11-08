# AGENTS.md

This document provides guidance for AI coding agents working on this project, including Gemini CLI and GitHub Copilot.

## Project Context

This project is a Java secure development environment, primarily focusing on Dockerized services for egress filtering, ingress reverse proxying, and secure application hosting. It provides a complete Docker-based development infrastructure with network segmentation, egress proxy filtering via Squid, and HTTPS ingress via Caddy.

The instructions in this project will ALWAYS be overridden by the downstream project.

## Architecture Overview

The project consists of multiple Docker services organized with network segmentation:

- **app**: Main Java application container (BellSoft Liberica OpenJDK with Debian)
- **database**: PostgreSQL 16-alpine for data persistence
- **ingress**: Caddy 2-alpine reverse proxy providing HTTPS termination
- **egress**: Alpine with Squid for outbound HTTP/HTTPS proxy filtering

Three internal networks enforce isolation:
- **db-net**: App ↔ Database (internal)
- **ingress-net**: App ↔ Ingress (internal)
- **egress-net**: App ↔ Egress (internal)
- **internet**: Egress ↔ External internet (outbound only)

## Setup Instructions

For detailed setup instructions, see [docs/SETUP.md](docs/SETUP.md).

Quick start:
1.  Ensure Docker and Docker Compose are installed.
2.  Clone the repository.
3.  Run `./setup.sh` or manually execute:
    ```bash
    mkdir -p secrets
    docker compose build --no-cache
    docker compose up -d
    ```

## Code Style and Conventions

-   **Dockerfiles:** Follow best practices for Dockerfile optimization and security.
-   **Squid Configuration:** Follow Squid's official documentation and best practices for security and performance.

## Testing Instructions

- Ensure the project build works when done without a cache. 
    - Use `docker compose --progress=plain build --no-cache`

-   To run integration tests for egress service:
    1.  Start only the egress service: `docker compose up -d egress`
    2.  Execute the tester script inside the egress container: `docker compose exec egress /usr/local/bin/tester.sh`
    3.  Stop the egress service: `docker compose down egress`

## Docker Compose Files

The project uses Docker Compose's override pattern for clean separation:

- **docker-compose.yml**: Base infrastructure (ingress, egress, proxy networks)
- **docker-compose.override.yml**: Application config (app, database, app networks)

Docker Compose automatically merges both files when you run `docker compose` commands. This pattern resolves the service conflict issue and provides flexibility for environment-specific configurations.

See [CHANGELOG.md](CHANGELOG.md) for architectural details.

## Agent Workflow Guidelines

-   **Verification**: After making any code changes, always run relevant tests to ensure functionality.
-   **Code Quality**: Before finalizing changes, check for any linting or formatting errors.
-   **Ambiguity**: If instructions are unclear or conflicting, ask for clarification from the user before proceeding.
-   **Documentation**: Keep this `AGENTS.md` file updated with any new instructions or changes in workflow.

## Version Control

- Uses github for hosting
- Use the `gh` cli to perform operations, specially on issues and pull requests.
- Always work off a branch. Never on the main branch.
- Always squash the code during merge, never carry the history.

## Pull Request Instructions

-   Ensure all changes are thoroughly tested.
-   Provide clear and concise commit messages.
-   Reference relevant issues or tasks.
-   Ensure code adheres to project style guides.
-   Always needs a self code review before converting the review from draft to final.