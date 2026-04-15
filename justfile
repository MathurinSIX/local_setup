# Local stack: Traefik + PostgreSQL + MinIO. Run from this directory.

default:
    @just --list

# Copy `.env.example` to `.env` if `.env` is missing (does not overwrite).
init-env:
    test -f .env || cp .env.example .env

# Start stack in the background (ensures shared Traefik network exists first).
up: init-env
    docker network inspect traefik-public >/dev/null 2>&1 || docker network create traefik-public
    docker compose up -d

# Stop and remove containers (keeps named volumes).
down:
    docker compose down

# Stop and remove containers and volumes (wipes Postgres + MinIO data).
down-volumes:
    docker compose down -v

# Follow service logs; pass service names to limit (e.g. `just logs postgres`).
logs *services:
    docker compose logs -f {{ services }}

# Restart one or more services (e.g. `just restart postgres`). With no names, restarts every service in the compose project.
restart *services:
    docker compose restart {{ services }}

# Container status.
ps:
    docker compose ps

# Pull images from the registry only (does not restart containers).
pull:
    docker compose pull

# Rebuild local images if any and recreate running containers (does not pull from the registry).
refresh: init-env
    docker network inspect traefik-public >/dev/null 2>&1 || docker network create traefik-public
    docker compose up -d --build --force-recreate
