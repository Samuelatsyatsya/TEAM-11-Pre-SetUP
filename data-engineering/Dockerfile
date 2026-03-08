FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Create an unprivileged runtime user.
RUN groupadd --system servicehub-etl \
    && useradd --system --gid servicehub-etl --home /app --shell /usr/sbin/nologin servicehub-etl

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY config.py etl_pipeline.py ./

USER servicehub-etl

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import os,sys; sys.exit(0 if os.path.exists('/app/etl_pipeline.py') else 1)"

CMD ["python", "etl_pipeline.py"]
