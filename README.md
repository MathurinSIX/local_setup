# local_setup

This repository holds a **local Docker-based setup** so you can run **other tools and services** on your machine with a small, repeatable stack: a reverse proxy, a relational database, and object storage.

Use it when you want shared infrastructure (for example Traefik in front of containers, Postgres for apps, MinIO for S3-style buckets) without installing those components directly on the host.

## What is in the stack

- **Traefik** — published host ports: HTTP **80** and HTTPS **443**. Routes to backends use the Docker provider and a small file provider for the dashboard.
- **PostgreSQL** — published on the host as **`localhost:POSTGRES_PORT`** (default **5432**), mapped straight to the database container (not through Traefik). From another container on **`traefik-public`**, use host **`postgres`** and port **5432**. Many apps can share that server; each uses its own `dbname` (create with `CREATE DATABASE` or your tooling). Local clients often need `sslmode=disable` in the URL.
- **MinIO** — S3 API at **`http://minio.<TRAEFIK_DOMAIN>/`** and console at **`http://minio-console.<TRAEFIK_DOMAIN>/`** (e.g. `http://minio.localhost/` and `http://minio-console.localhost/`), both **only** via Traefik on port **80**. Use the MinIO client (`mc`) against the S3 hostname.

See `docker-compose.yml` for images, ports, and `restart: on-failure` on the long-running services.

## Quick start

1. Copy the environment template and edit values (especially passwords) if you are not only experimenting locally:

   ```bash
   cp .env.example .env
   ```

2. Ensure the shared Traefik network exists, then start the stack:

   ```bash
   docker network inspect traefik-public >/dev/null 2>&1 || docker network create traefik-public
   docker compose up -d
   ```

3. If host ports are already taken (common: `5432`, `80`), set overrides in `.env` — see `.env.example` for `POSTGRES_PORT` and `TRAEFIK_DOMAIN`.

Traefik listens on port **80** for HTTP routing (including the dashboard at `http://127.0.0.1/dashboard/` and the API under `/api/`). Example Postgres URL from the host: `postgresql://USER:PASSWORD@127.0.0.1:5432/DBNAME?sslmode=disable` (adjust user, password, db, and `POSTGRES_PORT` from `.env`).

## Using with **risk-control** (or other Compose apps)

Compose treats **`traefik-public` as an external network** (see `docker-compose.yml`), so Docker must already have that network—no “created by compose” mismatch and no `WARN … exists but was not created by compose`.

1. Create the network if needed: `docker network create traefik-public` (risk-control’s `just up` also creates it when missing).
2. Start this stack: `docker compose up -d` from this directory so Traefik (and anything else here) joins `traefik-public`.
3. In **risk-control** `.env`, set Traefik entrypoints to match this proxy: `TRAEFIK_ENTRYPOINT_HTTP=web`, `TRAEFIK_ENTRYPOINT_HTTPS=websecure`, and keep `TRAEFIK_DOCKER_NETWORK=traefik-public`.
4. Run `just up` in risk-control so app containers join the same network; Traefik discovers them via the Docker provider.

HTTP entrypoints here are named **`web`** and **`websecure`** (not `http`/`https`).

## Troubleshooting

### Every virtual host returns Traefik’s plain-text “404 page not found”

On **Docker Engine 29+**, older Traefik builds used a Docker HTTP client API version that the engine rejects, so the **Docker provider never loads** and no routes appear from container labels. Logs repeat `Failed to retrieve information of the docker client and server host`. This stack uses **Traefik v3.6+**, which negotiates the API version; run `docker compose pull traefik && docker compose up -d` here after upgrading this repo.

## Environment variables

All variables used by Compose are documented with defaults in **`.env.example`**. None are strictly required for a first run; Compose supplies defaults in `docker-compose.yml` when a variable is unset.
