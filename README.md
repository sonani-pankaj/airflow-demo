# Copy and configure secrets
cp .env.example .env
# Edit .env with strong passwords and keys

# Production (explicit file)
docker-compose -f docker-compose.yaml up -d

# Development (auto-loads override)
docker-compose up -d