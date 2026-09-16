# Performance Report

## Resource Allocation

| Service | CPU Limit | Memory Limit | Rationale |
|---|---|---|---|
| backend / backend2 | 0.5 | 256M | Node.js baseline + request handling; verified sufficient under normal load |
| postgres | 0.5 | 512M | Database needs more headroom for query processing and caching |
| redis | 0.25 | 128M | In-memory cache, lightweight for this dataset size |
| frontend | 0.25 | 64M | Static file serving only, minimal footprint |
| nginx | 0.25 | 64M | Reverse proxy, low overhead |
| Monitoring stack (Prometheus, Grafana, Loki) | Unrestricted | Unrestricted | Deliberately left unconstrained — single-instance services with variable, unpredictable memory needs (scrape volume, log ingestion, dashboard queries); an OOM-kill here has no failover, unlike backend replicas |

## Optimizations Implemented

- **Docker layer caching** — Dockerfiles order `COPY package*.json` + `RUN npm install` before `COPY . .`, so code-only changes skip dependency reinstallation on rebuild
- **Minimal base images** — `node:20-alpine` and `nginx:alpine` throughout, keeping image sizes small
- **Gzip compression** — enabled at the Nginx layer for text-based responses (HTML, CSS, JS, JSON), verified via response headers
- **Cache headers** — static assets served with 7-day cache expiry, reducing repeat-request load
- **Redis caching layer** — `GET /products` results cached for 30 seconds, verified via cache hit/miss testing, reducing direct database load under repeated requests
- **Load balancing** — two backend replicas share request load via Nginx round-robin, verified with alternating `servedBy` responses

## Known Limitation Discovered During Testing

A brief 502 Bad Gateway occurred immediately after applying resource limits — root-caused to a startup-timing race condition (Nginx receiving a request before the freshly restarted backend was ready), not an actual memory constraint. This is exactly the gap `depends_on` alone doesn't solve, and why `healthcheck.sh` (used in the deployment script) retries with delay rather than checking once immediately.

## Not Benchmarked (Honest Scope Note)

Formal load testing (e.g., with a tool like `k6` or `ab`) was not performed — this report documents configuration choices and their rationale rather than measured throughput/latency under simulated load. A logical next step for this project.