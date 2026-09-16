# Product Catalog — Production-Grade Multi-Container DevOps Project

A full multi-container Product Catalog application demonstrating production-oriented DevOps practices including Docker Compose orchestration, Nginx reverse proxy and load balancing, monitoring, centralized logging, automated PostgreSQL backups, rolling deployment, resource limits, and CI/CD.

This project was developed as part of the Cloud Computing & DevOps internship at Maincrafts Technology.

---

## Architecture

```text
                         ┌─────────────┐
                         │   Browser   │
                         └──────┬──────┘
                                │
                                ▼
                         ┌─────────────┐
                         │    Nginx    │
                         │ Port 80     │
                         │ Reverse     │
                         │ Proxy + LB  │
                         └──────┬──────┘
                                │
                    ┌───────────┴───────────┐
                    ▼                       ▼
             ┌─────────────┐        ┌─────────────────┐
             │  Frontend   │        │ Backend x2      │
             │  Static UI  │        │ Round-Robin LB  │
             └─────────────┘        └────────┬────────┘
                                             │
                              ┌──────────────┴──────────────┐
                              ▼                             ▼
                       ┌─────────────┐               ┌─────────────┐
                       │ PostgreSQL  │               │    Redis    │
                       │     16      │               │      7      │
                       └─────────────┘               └─────────────┘


              Monitoring & Centralized Logging
                     backend-network

       ┌───────────┐       ┌────────────┐
       │ cAdvisor  │──────▶│ Prometheus │
       └───────────┘       └──────┬─────┘
                                  │
                                  ▼
                            ┌───────────┐
                            │  Grafana  │
                            └─────┬─────┘
                                  ▲
                                  │
       ┌───────────┐       ┌──────┴─────┐
       │ Promtail  │──────▶│    Loki    │
       └───────────┘       └────────────┘

# Product Catalog — Production-Grade Multi-Container DevOps Project

A full multi-container application demonstrating production DevOps practices: Docker Compose orchestration, load balancing, monitoring, centralized logging, automated backups, zero-downtime deployment, and CI/CD — built as Task 5 of the Cloud Computing & DevOps internship at Maincrafts Technology.

## Architecture

[paste diagram from above]

## What This Demonstrates

This project intentionally goes beyond a single container (Tasks 1-4) into a coordinated, multi-service system — the kind of architecture used by real companies before adopting Kubernetes.

## Tech Stack

- **Application:** Node.js/Express (backend, 2 load-balanced replicas), static HTML (frontend)
- **Data:** PostgreSQL 16, Redis 7
- **Reverse Proxy:** Nginx (load balancing, gzip, cache headers, multi-path routing)
- **Monitoring:** Prometheus, Grafana, cAdvisor
- **Logging:** Loki, Promtail
- **CI/CD:** GitHub Actions, Docker Hub
- **Orchestration:** Docker Compose

## Running Locally

\`\`\`bash
git clone https://github.com/priyankabommani29-rgb/product-catalog-devops.git
cd product-catalog-devops
# Create .env with required variables (see .env.example if provided, or below)
docker compose up -d --build
\`\`\`

Required `.env` variables:
\`\`\`
DB_HOST=postgres
DB_PORT=5432
DB_USER=admin
DB_PASSWORD=changeme123
DB_NAME=productcatalog
REDIS_HOST=redis
REDIS_PORT=6379
APP_PORT=5000
GRAFANA_PASSWORD=changeme_admin_pass
\`\`\`

## Accessing Services

| Service | URL |
|---|---|
| Application | http://localhost |
| Grafana | http://localhost:3000 |
| Prometheus | http://localhost:9090 |

## Network Architecture

Two segmented Docker networks:
- **frontend-network** — nginx, frontend, backend (public-facing)
- **backend-network** — backend, postgres, redis, monitoring stack (internal only)

`postgres` and `redis` are unreachable from `nginx`/`frontend` directly — verified via container-to-container ping tests (see development notes).

## Load Balancing

Nginx round-robins between two backend replicas (`backend`, `backend2`) via an explicit `upstream` block. Verified via repeated requests showing alternating container hostnames in responses.

## Monitoring

Prometheus scrapes container metrics via cAdvisor. Grafana visualizes CPU/memory usage per container in a saved dashboard.

## Centralized Logging

Promtail collects logs from all containers and ships them to Loki. Queryable in Grafana's Explore view across the entire stack from one interface.

## Backup Automation

\`\`\`bash
bash backup.sh
\`\`\`
Creates a timestamped, gzip-compressed `pg_dumpall` backup, automatically removing backups older than 7 days.

## Zero-Downtime Deployment

\`\`\`bash
bash deploy.sh
\`\`\`
Rolling update: `backend` and `backend2` are updated sequentially (never both down simultaneously), each verified via health check before proceeding. Automatically rolls back to the previous Git-commit-tagged image if a health check fails.

## CI/CD Pipeline

Every push to `main` triggers GitHub Actions to build and push three Docker images (backend, frontend, nginx) to Docker Hub, tagged with both `latest` and the commit SHA. A deployment job is defined and documented but intentionally disabled (`if: false`) — see workflow file for the pattern that would activate it against a provisioned server.

## Security

See [SECURITY.md](./SECURITY.md) for the full checklist.

## Screenshots

[embed the 6 screenshots here]

## Issues Faced & Solutions

- **Load balancing didn't work with `deploy: replicas: 2`:** plain Nginx doesn't dynamically load-balance across Docker's DNS round-robin. Fixed by defining two explicit named services (`backend`, `backend2`) instead.
- **YAML indentation errors merged services into each other repeatedly:** resolved by always verifying with `docker compose config` before building, and checking exact indentation alignment.
- **`curl.exe` appeared to always hit the same backend replica:** was a keep-alive connection reuse artifact, not a real load-balancing failure — confirmed with `--no-keepalive`.
- **Deployment script's `HEAD~1` failed on first deployment:** no previous Git commit existed yet. Fixed by checking `git rev-parse HEAD~1` validity before referencing it.
- **502 Bad Gateway immediately after adding resource limits:** was a startup-timing race condition (Nginx querying before backend fully ready), not an actual memory constraint issue — resolved on retry, confirmed via logs showing no crash/restart.
- **PostgreSQL free-tier resource concerns on target VM:** decided to keep this stack running locally rather than risk under-provisioning a live server.

## Author

**Priyanka B**
GitHub: https://github.com/priyankabommani29-rgb