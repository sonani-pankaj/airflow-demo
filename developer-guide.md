# Airflow Docker Developer Guide

This guide provides essential commands for managing and debugging the Apache Airflow Docker environment.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Starting & Stopping Docker Compose](#starting--stopping-docker-compose)
3. [Container Management](#container-management)
4. [Airflow Commands](#airflow-commands)
5. [Debugging Commands](#debugging-commands)
6. [Health Check Commands](#health-check-commands)
7. [Log Management](#log-management)
8. [Database Commands](#database-commands)
9. [DAG Management](#dag-management)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites

- Docker Desktop installed and running
- Docker Compose v2.x
- PowerShell or Terminal access

---

## Starting & Stopping Docker Compose

### Initialize Airflow (First Time Setup)

```powershell
# Initialize the database and create admin user
docker compose up airflow-init
```

### Start All Services

```powershell
# Start all containers in detached mode (background)
docker compose up -d

# Start all containers with logs visible
docker compose up

# Start specific service only
docker compose up -d airflow-scheduler
```

### Stop All Services

```powershell
# Stop all containers (preserves data)
docker compose down

# Stop all containers and remove volumes (CAUTION: deletes all data)
docker compose down -v

# Stop all containers, remove volumes and images
docker compose down -v --rmi all
```

### Restart Services

```powershell
# Restart all services
docker compose restart

# Restart specific service
docker compose restart airflow-scheduler
docker compose restart airflow-dag-processor
docker compose restart airflow-worker
```

### Pause & Resume Services

```powershell
# Pause all services (freeze containers)
docker compose pause

# Resume all services
docker compose unpause
```

---

## Container Management

### List Running Containers

```powershell
# List all Airflow containers with status
docker ps --filter "name=airflow" --format "table {{.Names}}\t{{.Status}}"

# List all containers (including stopped)
docker ps -a --filter "name=airflow"

# Compact list with container IDs
docker ps --filter "name=airflow" -q
```

### Container Information

```powershell
# Get detailed container info
docker inspect airflow-airflow-scheduler-1

# Get container resource usage
docker stats --no-stream --filter "name=airflow"
```

### Execute Commands in Container

```powershell
# Open bash shell in a container
docker exec -it airflow-airflow-scheduler-1 bash

# Run single command in container
docker exec airflow-airflow-scheduler-1 ls -la /opt/airflow/dags
```

---

## Airflow Commands

### Airflow CLI (Run inside container)

```powershell
# Check Airflow version
docker exec airflow-airflow-scheduler-1 airflow version

# Get Airflow configuration value
docker exec airflow-airflow-scheduler-1 airflow config get-value core executor

# List all configuration
docker exec airflow-airflow-scheduler-1 airflow config list
```

### User Management

```powershell
# Create admin user
docker exec airflow-airflow-apiserver-1 airflow users create `
    --username admin `
    --firstname Admin `
    --lastname User `
    --role Admin `
    --email admin@example.com `
    --password admin

# List users
docker exec airflow-airflow-apiserver-1 airflow users list

# Delete user
docker exec airflow-airflow-apiserver-1 airflow users delete --username <username>
```

### Connection Management

```powershell
# List all connections
docker exec airflow-airflow-scheduler-1 airflow connections list

# Add a new connection
docker exec airflow-airflow-scheduler-1 airflow connections add 'my_conn' `
    --conn-type 'http' `
    --conn-host 'https://example.com'

# Delete connection
docker exec airflow-airflow-scheduler-1 airflow connections delete 'my_conn'
```

### Variable Management

```powershell
# List all variables
docker exec airflow-airflow-scheduler-1 airflow variables list

# Set a variable
docker exec airflow-airflow-scheduler-1 airflow variables set my_key my_value

# Get a variable
docker exec airflow-airflow-scheduler-1 airflow variables get my_key

# Delete a variable
docker exec airflow-airflow-scheduler-1 airflow variables delete my_key
```

---

## Debugging Commands

### Check Job Status

```powershell
# Check if Dag Processor job is running
docker exec airflow-airflow-dag-processor-1 airflow jobs check --job-type DagProcessorJob --hostname $(docker exec airflow-airflow-dag-processor-1 hostname)

# Check if Triggerer job is running
docker exec airflow-airflow-triggerer-1 airflow jobs check --job-type TriggererJob --hostname $(docker exec airflow-airflow-triggerer-1 hostname)

# Check if Scheduler job is running
docker exec airflow-airflow-scheduler-1 airflow jobs check --job-type SchedulerJob --hostname $(docker exec airflow-airflow-scheduler-1 hostname)
```

### Check Health API

```powershell
# Get overall health status (JSON)
docker exec airflow-airflow-apiserver-1 curl -s http://localhost:8080/api/v2/monitor/health

# Check API version
docker exec airflow-airflow-apiserver-1 curl -s http://localhost:8080/api/v2/version

# Check scheduler health endpoint
docker exec airflow-airflow-scheduler-1 curl -s http://localhost:8974/health
```

### Database Debugging

```powershell
# Check database connection
docker exec airflow-airflow-scheduler-1 airflow db check

# Show current database version
docker exec airflow-airflow-scheduler-1 airflow db version

# Reset database (CAUTION: deletes all data)
docker exec airflow-airflow-scheduler-1 airflow db reset --yes
```

### Celery Worker Debugging

```powershell
# Check Celery worker status
docker exec airflow-airflow-worker-1 celery --app airflow.providers.celery.executors.celery_executor.app inspect ping

# List active Celery tasks
docker exec airflow-airflow-worker-1 celery --app airflow.providers.celery.executors.celery_executor.app inspect active

# List registered Celery tasks
docker exec airflow-airflow-worker-1 celery --app airflow.providers.celery.executors.celery_executor.app inspect registered
```

---

## Health Check Commands

### Container Health Status

```powershell
# Check all container health status
docker ps --filter "name=airflow" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check specific container health
docker inspect --format='{{.State.Health.Status}}' airflow-airflow-scheduler-1
docker inspect --format='{{.State.Health.Status}}' airflow-airflow-dag-processor-1
docker inspect --format='{{.State.Health.Status}}' airflow-airflow-worker-1
```

### Service Dependencies

```powershell
# Check Redis connection
docker exec airflow-redis-1 redis-cli ping

# Check PostgreSQL connection
docker exec airflow-postgres-1 pg_isready -U airflow
```

---

## Log Management

### View Container Logs

```powershell
# View last 100 lines of logs
docker logs airflow-airflow-scheduler-1 --tail 100
docker logs airflow-airflow-dag-processor-1 --tail 100
docker logs airflow-airflow-worker-1 --tail 100

# Follow logs in real-time
docker logs -f airflow-airflow-scheduler-1

# View logs with timestamps
docker logs --timestamps airflow-airflow-scheduler-1 --tail 50

# View logs since specific time
docker logs --since 1h airflow-airflow-scheduler-1
docker logs --since 2026-01-24T10:00:00 airflow-airflow-scheduler-1
```

### View All Service Logs (Docker Compose)

```powershell
# View all logs
docker compose logs

# Follow all logs
docker compose logs -f

# View specific service logs
docker compose logs airflow-scheduler
docker compose logs airflow-dag-processor

# View logs with timestamps
docker compose logs --timestamps
```

### Airflow Task Logs

```powershell
# View task logs from CLI
docker exec airflow-airflow-scheduler-1 airflow tasks logs <dag_id> <task_id> <execution_date>

# Example
docker exec airflow-airflow-scheduler-1 airflow tasks logs example_bash_operator runme_0 2026-01-24
```

---

## Database Commands

### PostgreSQL Access

```powershell
# Connect to PostgreSQL
docker exec -it airflow-postgres-1 psql -U airflow -d airflow

# Run SQL query directly
docker exec airflow-postgres-1 psql -U airflow -d airflow -c "SELECT * FROM dag LIMIT 5;"

# List all tables
docker exec airflow-postgres-1 psql -U airflow -d airflow -c "\dt"

# Check DAG runs
docker exec airflow-postgres-1 psql -U airflow -d airflow -c "SELECT dag_id, state, execution_date FROM dag_run ORDER BY execution_date DESC LIMIT 10;"
```

### Database Migration

```powershell
# Upgrade database schema
docker exec airflow-airflow-scheduler-1 airflow db upgrade

# Check pending migrations
docker exec airflow-airflow-scheduler-1 airflow db check-migrations
```

---

## DAG Management

### List and Manage DAGs

```powershell
# List all DAGs
docker exec airflow-airflow-scheduler-1 airflow dags list

# List DAG tasks
docker exec airflow-airflow-scheduler-1 airflow tasks list <dag_id>

# Show DAG tree structure
docker exec airflow-airflow-scheduler-1 airflow tasks list <dag_id> --tree

# Pause a DAG
docker exec airflow-airflow-scheduler-1 airflow dags pause <dag_id>

# Unpause a DAG
docker exec airflow-airflow-scheduler-1 airflow dags unpause <dag_id>
```

### Trigger DAG Runs

```powershell
# Trigger a DAG run
docker exec airflow-airflow-scheduler-1 airflow dags trigger <dag_id>

# Trigger with configuration
docker exec airflow-airflow-scheduler-1 airflow dags trigger <dag_id> --conf '{"key": "value"}'

# Trigger with specific execution date
docker exec airflow-airflow-scheduler-1 airflow dags trigger <dag_id> -e 2026-01-24
```

### Test DAGs and Tasks

```powershell
# Test a specific task (dry run)
docker exec airflow-airflow-scheduler-1 airflow tasks test <dag_id> <task_id> <execution_date>

# Validate DAG file
docker exec airflow-airflow-scheduler-1 python /opt/airflow/dags/<dag_file>.py

# Check for DAG import errors
docker exec airflow-airflow-scheduler-1 airflow dags list-import-errors
```

### Backfill DAGs

```powershell
# Backfill a DAG for date range
docker exec airflow-airflow-scheduler-1 airflow dags backfill <dag_id> `
    --start-date 2026-01-01 `
    --end-date 2026-01-24
```

---

## Troubleshooting

### Common Issues & Solutions

#### 1. Dag Processor Shows Unhealthy in UI

```powershell
# Verify dag processor is actually healthy
docker exec airflow-airflow-apiserver-1 curl -s http://localhost:8080/api/v2/monitor/health

# Check container status
docker ps --filter "name=dag-processor"

# View dag processor logs
docker logs airflow-airflow-dag-processor-1 --tail 100

# Hard refresh browser (Ctrl+F5) - UI may be showing cached data
```

#### 2. DAGs Not Appearing in UI

```powershell
# Check for import errors
docker exec airflow-airflow-scheduler-1 airflow dags list-import-errors

# Verify DAG file permissions
docker exec airflow-airflow-scheduler-1 ls -la /opt/airflow/dags/

# Force DAG reprocessing
docker compose restart airflow-dag-processor
```

#### 3. Tasks Stuck in Queued State

```powershell
# Check worker status
docker exec airflow-airflow-worker-1 celery --app airflow.providers.celery.executors.celery_executor.app inspect active

# Check Redis connection
docker exec airflow-redis-1 redis-cli ping

# Restart worker
docker compose restart airflow-worker
```

#### 4. Database Connection Issues

```powershell
# Check PostgreSQL status
docker exec airflow-postgres-1 pg_isready -U airflow

# Check database logs
docker logs airflow-postgres-1 --tail 50

# Verify connection from Airflow
docker exec airflow-airflow-scheduler-1 airflow db check
```

#### 5. Memory/Resource Issues

```powershell
# Check container resource usage
docker stats --no-stream

# Check Docker disk usage
docker system df

# Clean up unused resources
docker system prune -f
```

#### 6. Container Won't Start

```powershell
# Check container logs for errors
docker logs airflow-airflow-scheduler-1

# Check if ports are in use
netstat -ano | findstr :8080

# Rebuild containers
docker compose build --no-cache
docker compose up -d
```

---

## Environment Variables

Key environment variables defined in `docker-compose.yaml`:

| Variable | Description | Default |
|----------|-------------|---------|
| `AIRFLOW__CORE__EXECUTOR` | Executor type | CeleryExecutor |
| `AIRFLOW__CORE__LOAD_EXAMPLES` | Load example DAGs | true |
| `AIRFLOW__DATABASE__SQL_ALCHEMY_CONN` | Database connection | postgresql+psycopg2://airflow:airflow@postgres/airflow |
| `AIRFLOW__CELERY__BROKER_URL` | Redis broker URL | redis://:@redis:6379/0 |
| `AIRFLOW_UID` | User ID for containers | 50000 |

---

## Quick Reference

| Task | Command |
|------|---------|
| Start all services | `docker compose up -d` |
| Stop all services | `docker compose down` |
| View all logs | `docker compose logs -f` |
| Check health | `docker ps --filter "name=airflow"` |
| Access scheduler shell | `docker exec -it airflow-airflow-scheduler-1 bash` |
| List DAGs | `docker exec airflow-airflow-scheduler-1 airflow dags list` |
| Trigger DAG | `docker exec airflow-airflow-scheduler-1 airflow dags trigger <dag_id>` |

---

## Useful URLs

- **Airflow UI**: http://localhost:8080
- **Default Credentials**: admin / admin
- **Flower (Celery Monitor)**: http://localhost:5555 (if enabled)

---

## test_postgres_external_connection.py

### How to run

- **Go to Airflow UI**: http://localhost:8080
- **Find the DAG**: test_postgres_external_connection

### From CLI

```powershell
docker exec airflow-airflow-scheduler-1 airflow dags trigger test_postgres_external_connection
```
