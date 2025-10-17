# DefectDojo Stack - Security Findings Management

Zentrale Plattform für Security Vulnerability Management und Reporting.

## Services

- **DefectDojo**: Security Findings Management Platform
- **PostgreSQL**: Metadata Database
- **Redis**: Task Queue & Cache
- **Nginx**: Reverse Proxy (Port 8082)

## Schnellstart

```bash
# 1. Environment konfigurieren
cp .env.example .env
nano .env

# 2. Stack deployen
docker compose up -d

# 3. DefectDojo Login
open http://localhost:8082
# Login: admin / <DEFECTDOJO_ADMIN_PASSWORD aus .env>
```

## URL

- DefectDojo: http://localhost:8082

## Netzwerk

- **External**: `devops-network` (Stack-übergreifend)
- **Internal**: `dojo-internal` (Stack-intern)

## Volumes

Docker-managed Volumes:
- `dojo_postgres`: PostgreSQL Datenbank
- `dojo_media`: Media Files & Uploads

## Environment Variables

Siehe `.env.example`:
- `DEFECTDOJO_DB_PASSWORD`: PostgreSQL Password
- `DEFECTDOJO_SECRET_KEY`: Django Secret Key
- `DEFECTDOJO_ADMIN_PASSWORD`: Admin Account Password

## Features

- ✅ Security Findings Aggregation
- ✅ Vulnerability Tracking
- ✅ Report Generation
- ✅ API Integration für CI/CD
- ✅ Compliance Dashboards

## Integration

DefectDojo empfängt Scan-Ergebnisse von:
- Trivy (Container Vulnerabilities)
- SAST/DAST Tools
- Woodpecker CI Pipeline

## Version

v1.0.0 - Initial Release
