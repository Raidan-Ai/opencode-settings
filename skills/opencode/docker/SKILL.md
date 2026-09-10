---
name: docker
description: Containerization, multi-stage builds, docker-compose, container networking, security hardening, debugging, and production optimization. Activate for any Dockerfile authoring, docker compose orchestration, container networking, image optimization, or container debugging task.
---

# Docker Skill

## Purpose
Provides comprehensive Docker containerization capabilities: multi-stage Dockerfiles, docker-compose orchestration, container networking, security hardening, image optimization, and production debugging. Enables building minimal, secure, and maintainable container images for any application stack.

## When to Activate
- Writing or optimizing Dockerfiles (multi-stage, multi-platform)
- Authoring docker-compose.yml files (app + database + cache stacks)
- Debugging container issues (logs, exec, inspect, networking)
- Optimizing image size (layer caching, slimming, multi-stage)
- Container security (non-root, read-only, capabilities)
- Container networking (bridges, volumes, health checks)
- CI/CD container builds (buildx, registry push)

## Core Knowledge

### Multi-Stage Build (Node.js)
```dockerfile
# ── Stage 1: Build ──
FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts
COPY . .
RUN npm run build

# ── Stage 2: Production ──
FROM node:20-alpine AS production
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
WORKDIR /app
COPY --from=builder --chown=appuser:appgroup /app/dist ./dist
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:appgroup /app/package.json ./
USER appuser
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1
CMD ["node", "dist/index.js"]
```

### Multi-Stage Build (Python)
```dockerfile
# ── Stage 1: Build ──
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ── Stage 2: Production ──
FROM python:3.12-slim AS production
RUN groupadd -r appgroup && useradd -r -g appgroup appuser
WORKDIR /app
COPY --from=builder /install /usr/local
COPY --chown=appuser:appgroup . .
USER appuser
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Docker Compose (App + DB + Redis)
```yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      target: production
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/appdb
      - REDIS_URL=redis://redis:6379
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - frontend
      - backend
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: "1.0"

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: appdb
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d appdb"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - backend

  redis:
    image: redis:7-alpine
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    volumes:
      - redisdata:/data
    networks:
      - backend

volumes:
  pgdata:
  redisdata:

networks:
  frontend:
  backend:
```

### .dockerignore
```
.git
.gitignore
node_modules
.env
.env.*
*.md
docker-compose*.yml
Dockerfile*
.dockerignore
__pycache__
.pytest_cache
.venv
*.pyc
dist
build
coverage
.nyc_output
```

### Container Security Patterns
```dockerfile
# Read-only root filesystem
RUN addgroup -S app && adduser -S app -G app
USER app
# docker run --read-only --tmpfs /tmp:rw,noexec,nosuid

# Drop all capabilities, add only needed ones
# docker run --cap-drop ALL --cap-add NET_BIND_SERVICE

# No new privileges
# docker run --security-opt=no-new-privileges:true
```

### Container Networking
```bash
# Create custom bridge network
docker network create --driver bridge app-net

# Connect containers to network
docker network connect app-net my-container

# DNS resolution between containers (compose default)
# Container name = DNS hostname inside the network

# Expose internal port without publishing
EXPOSE 8000  # Informational only

# Publish to host
docker run -p 3000:3000 app  # host:container

# Bind to specific interface
docker run -p 127.0.0.1:3000:3000 app
```

## Workflow

### 1. Build and Validate Image
```bash
# Build with target stage
docker build --target production -t myapp:latest .

# Validate compose file
docker compose config

# Run and verify health
docker compose up -d
docker compose ps
docker compose logs app
```

### 2. Debugging Containers
```bash
# View logs (follow)
docker logs -f <container>

# Execute into running container
docker exec -it <container> /bin/sh

# Inspect container details
docker inspect <container>

# Check resource usage
docker stats <container>

# Inspect networking
docker network inspect bridge

# Copy files from container
docker cp <container>:/app/logs ./logs

# View container filesystem changes
docker diff <container>
```

### 3. Image Size Optimization
```bash
# Check image size
docker images myapp

# Analyze image layers
docker history myapp:latest

# Multi-stage: only copy artifacts from builder
# Use alpine or slim base images
# Combine RUN commands to reduce layers
# Clean up in same layer: RUN apt-get install -y pkg && rm -rf /var/lib/apt/lists/*

# Remove dangling images
docker image prune -f
```

### 4. Production Hardening
```bash
# Run with all security options
docker run -d \
  --read-only \
  --tmpfs /tmp:rw,noexec,nosuid \
  --cap-drop ALL \
  --cap-add NET_BIND_SERVICE \
  --security-opt no-new-privileges:true \
  --user 1000:1000 \
  --memory 512m \
  --cpus 1.0 \
  --restart unless-stopped \
  myapp:latest
```

## Tools
```bash
# Docker Engine
docker --version
docker compose version

# Build tools (multi-platform)
docker buildx create --use
docker buildx build --platform linux/amd64,linux/arm64 -t myapp .

# Image scanning
docker scout cves myapp:latest

# Cleanup
docker system prune -af --volumes
```

### MCP Integration
```json
{
  "mcpServers": {
    "docker": {
      "command": "npx",
      "args": ["-y", "docker-mcp"],
      "description": "Docker container management MCP server",
      "tools": ["list_containers", "exec_in_container", "view_logs"]
    }
  }
}
```

## Best Practices
1. **Multi-stage builds always**: Separate build dependencies from runtime image
2. **Alpine or slim base**: `node:20-alpine`, `python:3.12-slim` over full images
3. **Non-root user**: Create and switch to non-root user in Dockerfile
4. **Layer ordering**: Copy dependency files first (package.json, requirements.txt) for cache hits
5. **Health checks**: Define HEALTHCHECK in Dockerfile or compose for orchestration
6. **Read-only rootfs**: Use `--read-only` with tmpfs for writable temp directories
7. **Compose depends_on**: Use `condition: service_healthy` for startup ordering
8. **Pin versions**: Base image tags (not `latest`), package versions in lockfiles
9. **Resource limits**: Set memory/CPU limits in compose or run commands
10. **Clean up**: Run `docker system prune` regularly, use `.dockerignore` to exclude dev files

## Anti-patterns
- ❌ Running containers as root in production
- ❌ Using `latest` tag without pinning (unpredictable builds)
- ❌ Not using multi-stage builds (bloated images with build tools)
- ❌ `COPY . .` before dependency install (breaks layer cache)
- ❌ Storing secrets in Dockerfiles or images (use env vars or Docker secrets)
- ❌ No health checks (orchestration can't detect unhealthy containers)
- ❌ Using `docker run` without resource limits (OOM kills)
- ❌ Building on production servers (build in CI, push to registry)
- ❌ Leaving dangling images and volumes (disk waste)

## Verification

### Unit Tests
```bash
# Validate Dockerfile syntax
docker build --check .

# Validate compose file
docker compose config

# Test image builds successfully
docker build --target production -t myapp:test .

# Verify non-root user
docker run --rm myapp:test whoami
# Expected: appuser (not root)

# Verify health check works
docker run -d --name test-health myapp:test
sleep 35  # Wait for first health check
docker inspect --format='{{.State.Health.Status}}' test-health
# Expected: healthy

# Verify read-only rootfs
docker run --rm --read-only myapp:test touch /test 2>&1
# Expected: Read-only file system
```

### Integration Checks
```bash
# Full stack startup
docker compose up -d
docker compose ps  # All services "Up (healthy)"

# Service connectivity
docker compose exec app ping db
docker compose exec app ping redis

# Cleanup
docker compose down -v
```

## Examples

### Complete Production Dockerfile (Python FastAPI)
```dockerfile
FROM python:3.12-slim AS builder
WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-slim AS production
RUN groupadd -r app && useradd -r -g app -d /app -s /sbin/nologin app
WORKDIR /app
COPY --from=builder /install /usr/local
COPY --chown=app:app ./src ./src
COPY --chown=app:app ./migrations ./migrations
USER app
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
```

### Complete docker-compose.yml (Full Stack)
```yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      target: production
    ports:
      - "8000:8000"
    env_file: .env
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - backend
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: "1.0"

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - backend
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    command: redis-server --maxmemory 128mb --maxmemory-policy allkeys-lru
    volumes:
      - redisdata:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - backend
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./certs:/etc/nginx/certs:ro
    depends_on:
      - app
    networks:
      - backend
    restart: unless-stopped

volumes:
  pgdata:
  redisdata:

networks:
  backend:
```

### Dockerfile Build Argument Pattern
```dockerfile
# Build with: docker build --build-arg NODE_ENV=production -t myapp .
ARG NODE_ENV=production
FROM node:20-alpine AS builder
ARG NODE_ENV
ENV NODE_ENV=$NODE_ENV
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts
COPY . .
RUN npm run build
```
