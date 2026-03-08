#!/usr/bin/env bash
set -Eeuo pipefail

# Resolve script and project paths so this works from any current directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
ENV_EXAMPLE="${ROOT_DIR}/.env.example"

# Prefer Docker Compose v2 (`docker compose`), fall back to v1 (`docker-compose`).
COMPOSE_CMD=()
if docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD=("docker" "compose")
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD=("docker-compose")
else
  echo "ERROR: Docker Compose is not installed."
  exit 1
fi
COMPOSE_TEXT="${COMPOSE_CMD[*]}"
CORE_SERVICES=(postgres api frontend mailhog)
MAX_DEPLOY_RETRIES="${DEPLOY_MAX_RETRIES:-3}"
RETRY_DELAY_SECONDS="${DEPLOY_RETRY_DELAY_SECONDS:-8}"
DIAG_LOG_TAIL_LINES="${DEPLOY_DIAG_LOG_TAIL_LINES:-120}"

# Standard log formatter for normal script progress.
log() {
  echo "[deploy] $*"
}

# Standard error formatter that exits immediately.
fail() {
  echo "[deploy] ERROR: $*" >&2
  exit 1
}

require_env() {
  local key="$1"
  if [[ -z "${!key:-}" ]]; then
    fail "Required environment variable is missing: ${key}"
  fi
}

# Poll a URL until it responds or until timeout attempts are exhausted.
wait_for_url() {
  local name="$1"
  local url="$2"
  local attempts="${3:-60}"
  local sleep_secs="${4:-2}"
  local i

  log "Waiting for ${name} at ${url}"
  for ((i=1; i<=attempts; i++)); do
    if curl --silent --fail "${url}" >/dev/null 2>&1; then
      log "${name} is ready."
      return 0
    fi
    sleep "${sleep_secs}"
  done

  return 1
}

# Check required local tooling and Docker daemon availability.
check_prerequisites() {
  # Fast-fail before any container work so onboarding errors are obvious.
  command -v docker >/dev/null 2>&1 || fail "Docker is not installed."
  command -v curl >/dev/null 2>&1 || fail "curl is required but not installed."
  docker info >/dev/null 2>&1 || fail "Docker daemon is not running."
}

# Ensure local runtime configuration exists before startup.
prepare_env() {
  # First-time setup convenience for new team members.
  if [[ ! -f "${ENV_FILE}" ]]; then
    if [[ -f "${ENV_EXAMPLE}" ]]; then
      cp "${ENV_EXAMPLE}" "${ENV_FILE}"
      log "Created .env from .env.example"
    else
      fail ".env.example not found at ${ENV_EXAMPLE}"
    fi
  else
    log ".env already exists; using existing values."
  fi
}

# Load values from .env so health checks and URLs use configured ports.
load_env() {
  local line
  local line_number=0
  local key
  local raw
  local value

  while IFS= read -r line || [[ -n "${line}" ]]; do
    line_number=$((line_number + 1))
    line="${line%$'\r'}"

    [[ "${line}" =~ ^[[:space:]]*$ ]] && continue
    [[ "${line}" =~ ^[[:space:]]*# ]] && continue

    if [[ ! "${line}" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=(.*)$ ]]; then
      fail "Invalid .env entry at line ${line_number}. Use KEY=VALUE format."
    fi

    key="${BASH_REMATCH[1]}"
    raw="${BASH_REMATCH[2]}"

    raw="${raw#"${raw%%[![:space:]]*}"}"
    if [[ "${raw}" =~ ^\"(.*)\"[[:space:]]*$ ]]; then
      value="${BASH_REMATCH[1]}"
    elif [[ "${raw}" =~ ^\'(.*)\'[[:space:]]*$ ]]; then
      value="${BASH_REMATCH[1]}"
    else
      value="${raw%"${raw##*[![:space:]]}"}"
    fi

    printf -v "${key}" '%s' "${value}"
    export "${key}"
  done < "${ENV_FILE}"
}

validate_runtime_env() {
  require_env API_PORT
  require_env FRONTEND_PORT
  require_env MAIL_UI_PORT
  require_env SMOKE_TEST_EMAIL
  require_env SMOKE_TEST_PASSWORD
}

# Basic post-deploy smoke test: authenticate against backend API.
smoke_test_login() {
  local response

  # Validate that auth works using credentials provided in .env.
  response="$(curl --silent --show-error \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"${SMOKE_TEST_EMAIL}\",\"password\":\"${SMOKE_TEST_PASSWORD}\"}" \
    "http://localhost:${API_PORT}/api/v1/auth/login" || true)"

  if [[ "${response}" != *"accessToken"* ]]; then
    log "Login smoke test failed. Response: ${response}"
    return 1
  fi

  log "Login smoke test passed."
}

teardown_stack() {
  log "Tearing down existing stack (idempotent cleanup)..."
  "${COMPOSE_CMD[@]}" down --remove-orphans --timeout 20 >/dev/null 2>&1 || true
}

print_service_health() {
  local service="$1"
  local cid

  cid="$("${COMPOSE_CMD[@]}" ps -q "${service}" 2>/dev/null || true)"
  if [[ -z "${cid}" ]]; then
    log "Service '${service}': no container id found."
    return
  fi

  docker inspect \
    --format "service=${service} state={{.State.Status}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}n/a{{end}} exit={{.State.ExitCode}} restarted={{.RestartCount}}" \
    "${cid}" 2>/dev/null || true
}

dump_diagnostics() {
  log "Collecting failure diagnostics..."
  "${COMPOSE_CMD[@]}" ps || true

  for service in "${CORE_SERVICES[@]}"; do
    print_service_health "${service}" || true
  done

  for service in "${CORE_SERVICES[@]}"; do
    log "---- ${service} logs (tail ${DIAG_LOG_TAIL_LINES}) ----"
    "${COMPOSE_CMD[@]}" logs --tail "${DIAG_LOG_TAIL_LINES}" "${service}" || true
  done
}

detect_flyway_checksum_mismatch() {
  "${COMPOSE_CMD[@]}" logs --tail "${DIAG_LOG_TAIL_LINES}" api 2>/dev/null \
    | grep -q "Migration checksum mismatch"
}

deploy_once() {
  teardown_stack

  log "Starting ServiceHub containers..."
  "${COMPOSE_CMD[@]}" up --build -d "${CORE_SERVICES[@]}" || return 1

  wait_for_url "API health endpoint" "http://localhost:${API_PORT}/actuator/health" 90 2 || return 1
  wait_for_url "Frontend" "http://localhost:${FRONTEND_PORT}" 60 2 || return 1
  smoke_test_login || return 1
}

# Main onboarding flow: validate env, start stack, wait for readiness, smoke test.
main() {
  # 1) Validate local prerequisites.
  check_prerequisites

  # 2) Create .env on first run from the committed template.
  prepare_env
  # 3) Load runtime config from .env.
  load_env
  validate_runtime_env

  # 4) Run compose commands from repository root.
  cd "${ROOT_DIR}"

  # 5) Recreate stack with retries and diagnostics.
  local attempt
  for ((attempt=1; attempt<=MAX_DEPLOY_RETRIES; attempt++)); do
    log "Deployment attempt ${attempt}/${MAX_DEPLOY_RETRIES}"
    if deploy_once; then
      break
    fi

    log "Attempt ${attempt} failed."
    dump_diagnostics

    if detect_flyway_checksum_mismatch; then
      fail "Detected Flyway checksum mismatch. If this is local/dev, reset state with: ${COMPOSE_TEXT} down -v --remove-orphans && ./devops/scripts/deploy.sh"
    fi

    if ((attempt == MAX_DEPLOY_RETRIES)); then
      fail "Deployment failed after ${MAX_DEPLOY_RETRIES} attempts."
    fi

    log "Retrying in ${RETRY_DELAY_SECONDS}s..."
    sleep "${RETRY_DELAY_SECONDS}"
  done

  # 6) Print onboarding success summary and useful follow-up commands.
  cat <<EOF

ServiceHub is ready.
Frontend:  http://localhost:${FRONTEND_PORT}
API:       http://localhost:${API_PORT}/api/v1
Swagger:   http://localhost:${API_PORT}/api/docs
MailHog:   http://localhost:${MAIL_UI_PORT}

Useful commands:
  ${COMPOSE_TEXT} logs -f api
  ${COMPOSE_TEXT} down
EOF
}

# Entrypoint.
main "$@"
