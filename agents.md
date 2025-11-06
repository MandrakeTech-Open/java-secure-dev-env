# AGENTS.md

This document provides guidance for AI coding agents working on this project, including Gemini CLI and GitHub Copilot.

## Project Context

This project is a Java secure development environment, primarily focusing on Dockerized services for egress filtering.

## Setup Instructions

To set up the development environment:
1.  Ensure Docker and Docker Compose are installed.
2.  Clone the repository.
3.  Build and run the services using `docker compose up --build`.

## Code Style and Conventions

-   **Java:** Adhere to Google Java Format.
-   **Shell Scripts:** Follow ShellCheck recommendations.
-   **Dockerfiles:** Follow best practices for Dockerfile optimization and security.
-   **Squid Configuration:** Follow Squid's official documentation and best practices for security and performance.

## Development Environment

-   **IDE:** IntelliJ IDEA (for Java), VS Code (for general development, Dockerfiles, shell scripts).
-   **Tools:** Docker, Docker Compose, Git.

## Testing Instructions

-   To run unit tests (if applicable): [Specify command, e.g., `mvn test`]
-   To run integration tests for egress service:
    1.  Start only the egress service: `docker compose up -d egress`
    2.  Execute the tester script inside the egress container: `docker compose exec egress /egress/tester.sh`
    3.  Stop the egress service: `docker compose down egress`

## Pull Request Instructions

-   Ensure all changes are thoroughly tested.
-   Provide clear and concise commit messages.
-   Reference relevant issues or tasks.
-   Ensure code adheres to project style guides.