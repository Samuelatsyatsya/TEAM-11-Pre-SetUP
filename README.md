# ServiceHub

Internal service request and ticketing platform with workflow automation, SLA tracking, and role-based access control.

## Stack

- Backend: Java 17, Spring Boot 3, Spring Security, Flyway
- Frontend: Next.js 14, React 18, TypeScript
- Database: PostgreSQL 16
- Email (dev): MailHog
- Container orchestration: Docker Compose

## Services

When running locally, the stack includes:

- `frontend` (Next.js UI)
- `api` (Spring Boot API)
- `postgres` (database)
- `mailhog` (SMTP + inbox UI)
- `pgadmin` (optional, `dev` profile)
- `data-engineering` (optional, `etl` profile)

## Quick Start (Recommended)

### 1. Prerequisites

- Docker Engine + Docker Compose
- Git
- `curl`

### 2. Clone

```bash
git clone <repository-url>
cd Team-11-Group-Project
```

### 3. Create local env

```bash
cp .env.example .env
```

Update sensitive values in `.env` before sharing your machine or network:

- `DB_PASSWORD`
- `JWT_SECRET`
- `ANALYTICS_DB_PASSWORD`
- `PGADMIN_PASSWORD`
- `SMOKE_TEST_PASSWORD`

### 4. Run one-command onboarding deploy

```bash
./devops/scripts/deploy.sh
```

What this script does:

- Creates `.env` from `.env.example` if missing
- Tears down old stack safely
- Builds and starts core services
- Waits for API and frontend health
- Runs API login smoke test
- Retries automatically on failure and prints diagnostics

### 5. Open the app

Use values from `.env`:

- Frontend: `http://localhost:${FRONTEND_PORT}`
- API base: `http://localhost:${API_PORT}/api/v1`
- Swagger UI: `http://localhost:${API_PORT}/api/docs`
- MailHog UI: `http://localhost:${MAIL_UI_PORT}`

## Manual Compose Usage

If you prefer manual Docker Compose commands:

```bash
docker compose up --build -d postgres api frontend mailhog
```

Optional profiles:

- Add pgAdmin:
```bash
docker compose --profile dev up --build -d
```
- Run ETL service:
```bash
docker compose --profile etl up --build -d data-engineering
```

Stop stack:

```bash
docker compose down
```

Reset everything (including volumes):

```bash
docker compose down -v --remove-orphans
```

## Environment Configuration

The root `.env.example` is the source of truth for local runtime config.

### Core keys

- Database: `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USERNAME`, `DB_USER`, `DB_PASSWORD`
- Ports: `API_PORT`, `FRONTEND_PORT`, `MAIL_PORT`, `MAIL_UI_PORT`, `PGADMIN_PORT`
- Auth: `JWT_SECRET`, `JWT_EXPIRATION_MS`, `JWT_REFRESH_EXPIRATION_MS`
- API file settings: `FILE_UPLOAD_DIR`, `FILE_MAX_SIZE_MB`, `FILE_MAX_PER_REQUEST`
- Mail settings: `MAIL_HOST`, `MAIL_USERNAME`, `MAIL_PASSWORD`, `MAIL_FROM`, `MAIL_ENABLED`
- Analytics role bootstrap: `ANALYTICS_DB_USER`, `ANALYTICS_DB_PASSWORD`
- Deploy smoke test: `SMOKE_TEST_EMAIL`, `SMOKE_TEST_PASSWORD`
- Deploy resilience tuning: `DEPLOY_MAX_RETRIES`, `DEPLOY_RETRY_DELAY_SECONDS`, `DEPLOY_DIAG_LOG_TAIL_LINES`

Service-level templates also exist:

- `backend/.env.example`
- `frontend/.env.example`
- `data-engineering/.env.example`

## API Verification

Health:

```bash
curl http://localhost:${API_PORT}/actuator/health
```

Login:

```bash
curl -X POST "http://localhost:${API_PORT}/api/v1/auth/login" \
  -H 'Content-Type: application/json' \
  -d '{"email":"admin@servicehub.local","password":"Admin@Sh2026!"}'
```

If you changed seed/smoke credentials, use values from your `.env`.

## Default Seed Users (Dev)

Created by Flyway migration files under `backend/src/main/resources/db/migration`.

- `admin@servicehub.local` / `Admin@Sh2026!` (ADMIN)
- `it.agent.accra@servicehub.local` / `Agent@Sh2026!` (AGENT)
- `it.agent.takoradi@servicehub.local` / `Agent@Sh2026!` (AGENT)
- `facilities.agent@servicehub.local` / `Agent@Sh2026!` (AGENT)
- `hr.agent@servicehub.local` / `Agent@Sh2026!` (AGENT)
- `hr.agent.kumasi@servicehub.local` / `Agent@Sh2026!` (AGENT)
- `user.accra@servicehub.local` / `User@Sh2026!` (USER)
- `user.takoradi@servicehub.local` / `User@Sh2026!` (USER)

## Useful Commands

Follow API logs:

```bash
docker compose logs -f api
```

Follow all logs:

```bash
docker compose logs -f
```

Check container status:

```bash
docker compose ps
```

## Troubleshooting

- `Docker daemon is not running`
  - Start Docker Desktop/daemon and rerun `./devops/scripts/deploy.sh`.
- API health check fails
  - Run `docker compose logs -f api postgres` and inspect DB connectivity and env values.
- Frontend health check fails
  - Run `docker compose logs -f frontend` and verify `API_PORT`/`FRONTEND_PORT` values.
- Smoke test login fails
  - Ensure DB was initialized and seeded; check API logs and credentials in `.env`.
- Port already in use
  - Change port variables in `.env` and rerun deploy.

## Repository Layout

- `backend/` Spring Boot API
- `frontend/` Next.js frontend
- `data-engineering/` ETL pipeline
- `devops/scripts/` deploy and DB bootstrap scripts
- `qa/` API/UI test scaffolding
- `docker-compose.yml` local orchestration

## Security Notes

- Do not commit `.env`.
- `.env.example` contains placeholders/dev defaults only.
- For shared/staging/prod environments, move secrets to a proper secret manager and avoid static credentials.
