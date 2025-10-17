# Registry Stack - Harbor

Enterprise Container Registry mit Vulnerability Scanning und Image Management.

## Services

- **Harbor Core**: Registry Management
- **Harbor Portal**: Web UI
- **Harbor Registry**: Container Image Storage
- **PostgreSQL**: Metadata Database
- **Redis**: Cache Layer
- **Trivy Adapter**: Vulnerability Scanner
- **Nginx**: Reverse Proxy (Port 5000)

## Schnellstart

```bash
# 1. Environment konfigurieren
cp .env.example .env
nano .env

# 2. Stack deployen
docker compose up -d

# 3. Harbor Login
open http://localhost:5000
# Default: admin / Harbor12345 (SOFORT ÄNDERN!)
```

## URL

⚠️ **Requires Traefik Proxy Stack** (stack-proxy)

- Harbor: http://registry.devops.local (via Traefik)

## Netzwerk

- **External**: `devops-network` (Stack-übergreifend)
- **Internal**: `registry-internal` (Stack-intern)

## Volumes

Docker-managed Volumes:
- `harbor_db`: PostgreSQL Datenbank
- `harbor_redis`: Redis Cache
- `harbor_registry`: Image Storage
- `harbor_nginx_config`: Nginx Konfiguration
- `harbor_trivy_cache`: Vulnerability DB
- ... weitere Harbor Volumes

## Environment Variables

Siehe `.env.example`:
- `HARBOR_CORE_SECRET`: Core Service Secret
- `HARBOR_JOBSERVICE_SECRET`: Job Service Secret
- `HARBOR_REGISTRY_SECRET`: Registry Secret
- `HARBOR_REGISTRY_PASSWORD`: Registry Password
- `HARBOR_DB_PASSWORD`: PostgreSQL Password
- `TRIVY_GITHUB_TOKEN`: GitHub Token (optional, für höheres Rate Limit)

## Features

- ✅ Vulnerability Scanning (Trivy)
- ✅ Scan-on-Push Policy
- ✅ Image Signing (bereit für Cosign)
- ✅ Projekt-basierte Organisation
- ✅ RBAC & Access Control

## Version

v1.0.0 - Initial Release (Harbor v2.11.0)
