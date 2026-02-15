# Production-optimized Airflow Dockerfile (SLIM)
# Build with: docker build --target production -t airflow-custom:latest .
#
# Image size comparison:
#   apache/airflow:3.0.1 (all providers): ~2.5GB
#   apache/airflow:slim-3.0.1:            ~800MB
#   This image (with postgres only):      ~1GB

ARG AIRFLOW_VERSION=3.0.1
# Use SLIM base image - excludes all providers (saves ~1.5GB)
FROM apache/airflow:slim-${AIRFLOW_VERSION} AS base

# Metadata labels
LABEL maintainer="your-team@example.com"
LABEL org.opencontainers.image.source="https://github.com/your-org/airflow-demo"
LABEL org.opencontainers.image.description="Production Apache Airflow with PostgreSQL"

# Install only required system dependencies (as root)
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER airflow

# Production stage
FROM base AS production

# Install ONLY the providers you need
# This keeps the image small instead of installing all providers
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir \
        apache-airflow-providers-postgres \
        apache-airflow-providers-common-sql \
        airflow-code-editor \
    && rm -rf ~/.cache/pip 2>/dev/null || true

# Verify installation
RUN python -c "import airflow; print(f'Airflow {airflow.__version__} installed successfully')"

# Set environment defaults
ENV AIRFLOW__CORE__LOAD_EXAMPLES=false \
    AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION=true \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -sf http://localhost:8080/health || exit 1

# Development stage with additional tools
FROM base AS development

RUN pip install --no-cache-dir \
    apache-airflow-providers-postgres \
    apache-airflow-providers-common-sql \
    airflow-code-editor \
    pytest \
    pytest-cov \
    black \
    flake8 \
    && rm -rf ~/.cache/pip 2>/dev/null || true
