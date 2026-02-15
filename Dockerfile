# Production-optimized Airflow Dockerfile
# Build with: docker build --target production -t airflow-custom:latest .

ARG AIRFLOW_VERSION=3.1.6
FROM apache/airflow:${AIRFLOW_VERSION} AS base

# Metadata labels
LABEL maintainer="your-team@example.com"
LABEL org.opencontainers.image.source="https://github.com/your-org/airflow-demo"
LABEL org.opencontainers.image.description="Production Apache Airflow with custom dependencies"

# Install system dependencies if needed (as root)
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

# Copy and install Python dependencies
COPY --chown=airflow:0 pyproject.toml README.md /tmp/build/

# Install dependencies with pip best practices
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir airflow-code-editor \
    && pip install --no-cache-dir /tmp/build/ \
    && rm -rf /tmp/build /root/.cache/pip

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
    airflow-code-editor \
    pytest \
    pytest-cov \
    black \
    flake8

COPY --chown=airflow:0 pyproject.toml README.md /tmp/build/
RUN pip install --no-cache-dir /tmp/build/ && rm -rf /tmp/build
