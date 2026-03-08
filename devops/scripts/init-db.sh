#!/usr/bin/env bash
set -Eeuo pipefail

# This script runs inside the postgres container on first database initialization.
# It creates a read-only analytics role using credentials passed via environment.

: "${POSTGRES_DB:?POSTGRES_DB is required}"
: "${ANALYTICS_DB_USER:?ANALYTICS_DB_USER is required}"
: "${ANALYTICS_DB_PASSWORD:?ANALYTICS_DB_PASSWORD is required}"

psql -v ON_ERROR_STOP=1 \
  --username "${POSTGRES_USER}" \
  --dbname "${POSTGRES_DB}" \
  --set=analytics_user="${ANALYTICS_DB_USER}" \
  --set=analytics_password="${ANALYTICS_DB_PASSWORD}" \
  --set=target_db="${POSTGRES_DB}" <<'SQL'
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = :'analytics_user') THEN
        EXECUTE format(
            'CREATE ROLE %I WITH LOGIN PASSWORD %L',
            :'analytics_user',
            :'analytics_password'
        );
    END IF;
END
$$;

GRANT CONNECT ON DATABASE :"target_db" TO :"analytics_user";
GRANT USAGE ON SCHEMA public TO :"analytics_user";
GRANT SELECT ON ALL TABLES IN SCHEMA public TO :"analytics_user";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO :"analytics_user";

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
SQL
