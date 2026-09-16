# Security Checklist

## Implemented

- [x] Least-privilege database credentials via `.env`, never hardcoded
- [x] `.env` excluded from version control (`.gitignore`)
- [x] Network segmentation — `postgres`/`redis`/`backend` isolated on `backend-network`, unreachable from `frontend-network`
- [x] PostgreSQL and Redis ports not exposed to the host — internal network access only
- [x] Backend containers run as a non-root user (`appuser`)
- [x] Docker Hub credentials stored as GitHub Secrets, never in code
- [x] SSH-based deployment uses a dedicated key, separate from personal AWS credentials
- [x] Backup files excluded from Git (`backups/` in `.gitignore`) — dumps contain hashed credentials

## Consciously Deferred (documented, not implemented)

- [ ] Docker image vulnerability scanning (e.g., Docker Scout, Trivy) — not run in this project's CI pipeline; would be a natural next addition
- [ ] HTTPS/TLS termination at the Nginx layer — this project runs over HTTP only; a production deployment would add a certificate (e.g., via Let's Encrypt/Certbot) at the reverse proxy
- [ ] Rate limiting on the Nginx reverse proxy — not configured; would help mitigate abuse/DDoS in a real production deployment
- [ ] Rootless Docker daemon — containers run as non-root, but the Docker daemon itself runs with standard (root) privileges on the host
- [ ] Secrets management via a dedicated vault (e.g., HashiCorp Vault, AWS Secrets Manager) — currently using `.env` files, adequate for this project's scope but not enterprise-grade