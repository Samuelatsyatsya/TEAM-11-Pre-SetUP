# syntax=docker/dockerfile:1

ARG FRONTEND_NODE_IMAGE
FROM ${FRONTEND_NODE_IMAGE} AS deps

WORKDIR /app

COPY package.json package-lock.json* yarn.lock* pnpm-lock.yaml* ./

RUN \
  if [ -f yarn.lock ]; then yarn install --frozen-lockfile; \
  elif [ -f package-lock.json ]; then npm ci; \
  elif [ -f pnpm-lock.yaml ]; then corepack enable pnpm && pnpm install --frozen-lockfile; \
  else echo "No lockfile found. Run 'npm install' first." && exit 1; \
  fi

FROM ${FRONTEND_NODE_IMAGE} AS build

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

ARG NEXT_PUBLIC_API_URL
ARG NEXT_TELEMETRY_DISABLED
ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}
ENV NEXT_TELEMETRY_DISABLED=${NEXT_TELEMETRY_DISABLED}

RUN mkdir -p /app/public && npm run build

FROM ${FRONTEND_NODE_IMAGE} AS runtime

ARG APP_PORT
ARG APP_BIND_HOST
ARG APP_USER
ARG APP_GROUP
ARG APP_HOME
ARG FRONTEND_HEALTHCHECK_URL
ARG NEXT_TELEMETRY_DISABLED

WORKDIR ${APP_HOME}

RUN groupadd -r ${APP_GROUP} && useradd -r -g ${APP_GROUP} ${APP_USER}
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

COPY --from=build /app/public ./public
COPY --from=build /app/.next/standalone ./
COPY --from=build /app/.next/static ./.next/static

RUN chown -R ${APP_USER}:${APP_GROUP} ${APP_HOME}

USER ${APP_USER}

EXPOSE ${APP_PORT}

ENV PORT=${APP_PORT}
ENV HOSTNAME=${APP_BIND_HOST}
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=${NEXT_TELEMETRY_DISABLED}
ENV FRONTEND_HEALTHCHECK_URL=${FRONTEND_HEALTHCHECK_URL}

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl --fail --silent "${FRONTEND_HEALTHCHECK_URL}" >/dev/null || exit 1

CMD ["node", "server.js"]
