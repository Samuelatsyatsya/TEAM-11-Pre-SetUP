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

CMD ["python", "etl_pipeline.py"]
