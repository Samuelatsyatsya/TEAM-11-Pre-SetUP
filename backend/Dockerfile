# syntax=docker/dockerfile:1

ARG BACKEND_BUILD_IMAGE
ARG BACKEND_RUNTIME_IMAGE
FROM ${BACKEND_BUILD_IMAGE} AS build

WORKDIR /workspace

COPY pom.xml ./
RUN mvn -B -DskipTests dependency:go-offline

COPY src ./src
RUN mvn -B -DskipTests package

FROM ${BACKEND_RUNTIME_IMAGE} AS runtime

ARG APP_USER
ARG APP_GROUP
ARG APP_HOME
ARG APP_PORT
ARG APP_HEALTHCHECK_HOST
ARG APP_HEALTHCHECK_PATH

WORKDIR ${APP_HOME}

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system ${APP_GROUP} \
    && useradd --system --gid ${APP_GROUP} --home ${APP_HOME} --shell /usr/sbin/nologin ${APP_USER} \
    && chown -R ${APP_USER}:${APP_GROUP} ${APP_HOME}

COPY --from=build /workspace/target/*.jar ${APP_HOME}/app.jar

USER ${APP_USER}

ENV SERVER_PORT=${APP_PORT}
ENV APP_HEALTHCHECK_HOST=${APP_HEALTHCHECK_HOST}
ENV APP_HEALTHCHECK_PATH=${APP_HEALTHCHECK_PATH}
ENV JAVA_TOOL_OPTIONS=""

EXPOSE ${APP_PORT}

ENTRYPOINT ["java", "-jar", "app.jar"]
