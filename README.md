# ServiceHub Monorepo (Base Setup)

Base project scaffold with a minimal backend and supporting local infrastructure.

## Components

- `backend/`: Spring Boot base API starter
- `frontend/`: Next.js app (existing UI workspace)
- `data-engineering/`: ETL workspace
- `devops/scripts/`: automation scripts
- `docker-compose.yml`: local orchestration

## Quick Start

1. Create env file:

```bash
cp .env.example .env
```

2. Start containers:

```bash
docker compose up --build -d
```

3. Verify backend:

```bash
curl http://localhost:${API_PORT}/actuator/health
curl http://localhost:${API_PORT}/api/v1
curl http://localhost:${API_PORT}/api/v1/ping
```

## Configuration

- All Docker/Compose runtime values are read from `.env`.
- No project runtime constants are hard-coded in Dockerfiles or `docker-compose.yml`.
- Update `.env` for ports, image tags, memory/CPU limits, and service behavior.

## Notes

- The backend is intentionally stripped to a minimal foundation for new feature development.
- Previous business features (auth, ticket workflow, SLA, notifications, etc.) were removed.
