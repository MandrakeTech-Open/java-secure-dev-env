# AGENTS.md

This document provides guidance for AI coding agents working on this project, including Gemini CLI and GitHub Copilot.

## Project Context

This project is a Java secure development environment, primarily focusing on Dockerized services for egress filtering.
The instructions in this project will ALWAYS be overridden by the downstream project.

## Setup Instructions

To set up the development environment:
1.  Ensure Docker and Docker Compose are installed.
2.  Clone the repository.
3.  Build and run the services using `docker compose up --build --detach`. Read up docker compose instructions for all other combinations.

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