# AGENTS.md

This file provides instructions for AI coding agents to work on this project.

## About AGENTS.md

AGENTS.md is an open format for guiding coding agents, similar to a README file but specifically tailored for AI. It provides a dedicated place for instructions like setup commands, code style, and testing procedures that coding agents need to work on a project.

## Setup

To set up the development environment, run the following command:

```bash
./setup.sh
```

## Building and Running

To build and run the services, use docker-compose:

```bash
docker-compose up -d
```

## Testing

To run the tests for the egress service, use the following command:

```bash
docker-compose up -d egress
docker-compose exec egress tester.sh
```

This will start only the egress service and run the tests in `tester.sh`.

## Code Style

This project follows the standard shell script and Dockerfile conventions.

## Agent-Specific Instructions

### Gemini CLI

This project is compatible with the Gemini CLI.

### GitHub Copilot

This project is compatible with GitHub Copilot.
