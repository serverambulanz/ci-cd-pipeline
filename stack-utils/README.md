# Utils Stack - Trivy Server + Dozzle

Hilfsdienste für Vulnerability Scanning und Log-Monitoring.

## Services

- **Trivy Server** (Port 8081): Standalone Vulnerability Scanner
- **Dozzle** (Port 8888): Real-time Docker Log Viewer

## Schnellstart

```bash
# 1. Environment konfigurieren (optional)
cp .env.example .env
nano .env

# 2. Stack deployen
docker compose up -d

# 3. Zugriff
open http://localhost:8888  # Dozzle Logs
curl http://localhost:8081/healthz  # Trivy Health
```

## URLs

- Trivy Server: http://localhost:8081
- Dozzle Logs: http://localhost:8888

## Netzwerk

- **External**: `devops-network` (Stack-übergreifend)

## Volumes

Docker-managed Volumes:
- `trivy_cache`: Vulnerability Database Cache

## Environment Variables

Siehe `.env.example`:
- `TRIVY_GITHUB_TOKEN`: GitHub Token (optional, erhöht Rate Limit)

## Trivy CLI Usage

```bash
# Scan über Server
export TRIVY_SERVER=http://localhost:8081
trivy image alpine:latest

# Filesystem Scan
trivy fs /path/to/code

# Secrets Scan
trivy fs --scanners secret .
```

## Dozzle Features

- ✅ Real-time Log Streaming
- ✅ Multi-Container Support
- ✅ Search & Filter
- ✅ Container Stats
- ✅ Dark Mode

## Version

v1.0.0 - Initial Release
