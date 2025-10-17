# CI Stack - Gitea + Woodpecker

Selbst-gehostete CI/CD-Lösung mit Git-Server und Build-Automation.

## Services

- **Gitea** (Port 3000, SSH 2222): Git-Server + OAuth Provider
- **Woodpecker Server** (Port 8000, 9000): CI/CD Engine
- **Woodpecker Agent**: Build Agent mit Docker-in-Docker

## Schnellstart

```bash
# 1. Environment konfigurieren
cp .env.example .env
nano .env

# 2. Stack deployen
docker compose up -d

# 3. Gitea Setup
open http://localhost:3000
```

## URLs

- Gitea: http://localhost:3000
- Woodpecker: http://localhost:8000

## Netzwerk

- **External**: `devops-network` (Stack-übergreifend)
- **Internal**: `ci-internal` (Stack-intern)

## Volumes

Docker-managed Volumes:
- `gitea_data`: Gitea Daten
- `woodpecker_data`: Woodpecker Daten
- `cargo_cache`: Rust Build Cache
- `rustup_cache`: Rust Toolchain Cache

## Environment Variables

Siehe `.env.example`:
- `WOODPECKER_AGENT_SECRET`: Agent-Authentifizierung
- `GITEA_OAUTH_CLIENT_ID`: OAuth Client ID (nach Gitea Setup)
- `GITEA_OAUTH_CLIENT_SECRET`: OAuth Client Secret (nach Gitea Setup)

## Version

v1.0.0 - Initial Release
