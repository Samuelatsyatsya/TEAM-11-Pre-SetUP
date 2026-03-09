# syntax=docker/dockerfile:1

ARG DATA_ENGINEERING_PYTHON_IMAGE
FROM ${DATA_ENGINEERING_PYTHON_IMAGE}

ARG ETL_WORKDIR
ARG ETL_USER
ARG ETL_GROUP
ARG ETL_ENTRYPOINT

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    ETL_ENTRYPOINT=${ETL_ENTRYPOINT}

WORKDIR ${ETL_WORKDIR}

RUN groupadd --system ${ETL_GROUP} \
    && useradd --system --gid ${ETL_GROUP} --home ${ETL_WORKDIR} --shell /usr/sbin/nologin ${ETL_USER}

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY config.py etl_pipeline.py ./

USER ${ETL_USER}

CMD ["sh", "-c", "python ${ETL_ENTRYPOINT}"]
