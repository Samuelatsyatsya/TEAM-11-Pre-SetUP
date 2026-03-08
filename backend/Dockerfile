# ServiceHub Backend — Multi-Stage Dockerfile
# Stage 1: Build (Maven + JDK 17)
# Stage 2: Runtime (JRE 17 slim — no build tools in final image)

FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /workspace

# Copy pom.xml first so Maven dependency layers stay cacheable.
COPY pom.xml ./
RUN mvn -B -DskipTests dependency:go-offline

# Copy source code and package.
COPY src ./src
RUN mvn -B -DskipTests package

FROM eclipse-temurin:17-jre-jammy AS runtime

WORKDIR /app

ARG APP_PORT=8080

# Install curl for container health checks and create an unprivileged user.
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system servicehub \
    && useradd --system --gid servicehub --home /app --shell /usr/sbin/nologin servicehub \
    && mkdir -p /data/uploads \
    && chown -R servicehub:servicehub /app /data/uploads

# Copy the Spring Boot fat jar.
COPY --from=build /workspace/target/*.jar /app/app.jar

USER servicehub

ENV SERVER_PORT=${APP_PORT}

EXPOSE ${APP_PORT}

# JAVA_TOOL_OPTIONS is read automatically by the JVM.
ENV JAVA_TOOL_OPTIONS=""

HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
  CMD curl --fail --silent http://localhost:${SERVER_PORT}/actuator/health > /dev/null || exit 1

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
