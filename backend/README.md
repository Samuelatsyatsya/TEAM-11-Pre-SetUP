# ServiceHub Backend (Base Starter)

Minimal Spring Boot backend starter for new project work.

## Included

- Spring Boot 3.x with Java 17
- `/api/v1` root endpoint
- `/api/v1/ping` liveness endpoint
- Actuator health/info endpoints (`/actuator/health`, `/actuator/info`)
- Environment-driven configuration
- Multi-stage Docker build with non-root runtime user

## Removed

All feature modules from the previous implementation were intentionally stripped out:

- Authentication/authorization
- Domain entities and repositories
- Workflow, SLA, notifications, and audit logging
- Flyway migrations and seed data

## Run Locally

1. Export environment values from the root `.env` (or use your shell/env manager), then run:

```bash
set -a && source ../.env && set +a
./mvnw spring-boot:run
```

2. Verify:

```bash
curl http://localhost:8080/actuator/health
curl http://localhost:8080/api/v1
curl http://localhost:8080/api/v1/ping
```

## Docker

Build and run via root `docker-compose.yml`.
All compose and Docker settings are parameterized through `.env`.
