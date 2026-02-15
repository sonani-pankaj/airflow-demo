# Airflow Troubleshooting & Configuration Notes

Date: February 14, 2026

---

## Issue: "Ooops! Something bad has happened" Error

### Symptoms

- Airflow web UI showed generic error page at `http://127.0.0.1:8080/auth/login/`
- Error message: "For security reasons detailed information about the error is not logged"

### Root Cause

Missing `SECRET_KEY` configuration. The actual error from logs:

```text
KeyError: 'SECRET_KEY must be set when SESSION_USE_SIGNER=True'
```

### Solution

1. Generated a secret key using Python:

   ```powershell
   python -c "import secrets; print(secrets.token_urlsafe(32))"
   ```

2. Added to `.env` file:

   ```env
   AIRFLOW_SECRET_KEY=JV-QsFoV56_z1TmN8Hd2TzFz2k6r-1UHxHsAZNDFov4
   ```

3. Fixed port conflict in `docker-compose.override.yaml` (removed duplicate port definition)

4. Restarted containers:

   ```powershell
   docker-compose down
   docker-compose up -d
   ```

### How to Check Logs

```powershell
docker-compose logs --tail=100 airflow-apiserver
```

---

## How docker-compose.override.yaml Works

Docker Compose automatically merges files in order:

1. `docker-compose.yaml` (base configuration)
2. `docker-compose.override.yaml` (overrides/additions)

### DEV vs PROD Mode

| Mode     | Command                                        | Files Used        |
|----------|------------------------------------------------|-------------------|
| **DEV**  | `docker-compose up -d`                         | Both files merged |
| **PROD** | `docker-compose -f docker-compose.yaml up -d`  | Base only         |

### Check Current Mode

```powershell
docker inspect airflow-demo-airflow-apiserver-1 --format '{{range .Config.Env}}{{println .}}{{end}}' | Select-String -Pattern "EXPOSE_CONFIG|TEST_CONNECTION"
```

**DEV indicators** (from override):

- `AIRFLOW__CORE__TEST_CONNECTION_ENABLED=true`
- `AIRFLOW__WEBSERVER__EXPOSE_CONFIG=true`
- `AIRFLOW__WEBSERVER__EXPOSE_SWAGGER_UI=true`

**PROD indicators** (base only):

- All above set to `false`

---

## Database Credentials

### Airflow Metadata Database (Internal)

| Setting  | Value                                    |
|----------|------------------------------------------|
| Host     | `postgres` (internal) / `localhost:5432` |
| Database | `airflow`                                |
| User     | `airflow`                                |
| Password | `airflow` (default)                      |

### External Data Warehouse

| Setting  | Value                                             |
|----------|---------------------------------------------------|
| Host     | `postgres-external` (internal) / `localhost:5450` |
| Database | `datawarehouse`                                   |
| User     | `datauser`                                        |
| Password | `datapassword` (default)                          |

### Custom Passwords

Add to `.env` file:

```env
POSTGRES_PASSWORD=your_secure_password
POSTGRES_EXTERNAL_PASSWORD=your_other_password
```

---

## Port 5450 for postgres-external

The port is assigned in `docker-compose.override.yaml` (DEV only):

```yaml
postgres-external:
  ports:
    - "5450:5432"  # Maps host:5450 → container:5432
```

| Mode     | Port Exposed? | Connect From Host                          |
|----------|---------------|--------------------------------------------|
| **DEV**  | Yes, `5450`   | `localhost:5450`                           |
| **PROD** | No            | Only internal via `postgres-external:5432` |

**Why?** Security - in production, the database isn't exposed outside Docker network.

---

## Restarting After airflow.cfg Changes

**Yes, restart is required** for `airflow.cfg` changes to take effect.

### Quick Restart Command

```powershell
docker-compose restart airflow-apiserver airflow-scheduler airflow-dag-processor airflow-triggerer
```

### Which Services Need Restart?

| Change Type                        | Services to Restart                          |
|------------------------------------|----------------------------------------------|
| Web UI settings (`[webserver]`)    | `airflow-apiserver`                          |
| Scheduler settings (`[scheduler]`) | `airflow-scheduler`                          |
| DAG parsing (`[core]`)             | `airflow-dag-processor`, `airflow-scheduler` |
| All/general changes                | All Airflow services                         |

---

## Generating Secret Keys

### AIRFLOW_SECRET_KEY (Flask session signing)

```powershell
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

### AIRFLOW_FERNET_KEY (Encrypts sensitive data)

```powershell
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

### Using openssl

```powershell
openssl rand -base64 32
```

---

## Quick Reference Commands

```powershell
# Check running containers
docker-compose ps

# View logs
docker-compose logs --tail=100 airflow-apiserver

# Restart all services
docker-compose restart

# Full restart (down + up)
docker-compose down && docker-compose up -d

# Start in PROD mode only
docker-compose -f docker-compose.yaml up -d

# Check environment variables
docker inspect airflow-demo-airflow-apiserver-1 --format '{{range .Config.Env}}{{println .}}{{end}}'
```
