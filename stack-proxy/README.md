# Proxy Stack - Traefik

Reverse Proxy und Load Balancer für alle DevOps Services.

## Services

- **Traefik** (Port 80, 443, 8080): Reverse Proxy + Dashboard

## Schnellstart

```bash
# 1. /etc/hosts konfigurieren (siehe unten)
sudo nano /etc/hosts

# 2. Stack via Portainer deployen
# Portainer → Stacks → Add Stack → Git Repository
# URL: https://github.com/serverambulanz/ci-cd-pipeline
# Path: stack-proxy/docker-compose.yml

# 3. Traefik Dashboard öffnen
open http://traefik.devops.local:8080
```

## URLs

- **Traefik Dashboard**: http://traefik.devops.local:8080
- **Alle Services**: Über Port 80 (HTTP)

## macOS /etc/hosts Setup

⚠️ **WICHTIG**: Vor dem Deployment ausführen!

```bash
# Einmalig alle DevOps Domains hinzufügen
sudo tee -a /etc/hosts << 'EOF'

# DevOps Stack - Traefik Routing
127.0.0.1 traefik.devops.local
127.0.0.1 portainer.devops.local
127.0.0.1 git.devops.local
127.0.0.1 ci.devops.local
127.0.0.1 registry.devops.local
127.0.0.1 logs.devops.local
127.0.0.1 trivy.devops.local
EOF
```

**Verify**:
```bash
ping traefik.devops.local  # Sollte 127.0.0.1 anzeigen
```

## Netzwerk

- **External**: `devops-network` (Stack-übergreifend)

## Volumes

Docker-managed Volumes:
- `traefik_config`: Traefik Konfiguration
- `traefik_certs`: SSL/TLS Zertifikate (zukünftig)

## Wie Traefik funktioniert

### 1. Service Discovery

Traefik scannt automatisch alle Docker Container im `devops-network` und sucht nach Labels:

```yaml
# Beispiel Service
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.myservice.rule=Host(`myservice.devops.local`)"
  - "traefik.http.services.myservice.loadbalancer.server.port=8000"
```

### 2. Routing

```
Browser: http://git.devops.local
    ↓
Traefik (Port 80)
    ↓ Prüft Host Header: git.devops.local
    ↓ Findet Router mit Rule: Host(`git.devops.local`)
    ↓ Leitet an Service weiter
    ↓
Gitea Container (Port 3000, intern)
```

### 3. Vorteile

- ✅ **Kein Port-Mapping** mehr nötig für Services
- ✅ **Automatische Registrierung** via Labels
- ✅ **Zentrale Entry Point**: Nur Port 80/443
- ✅ **Hot Reload**: Neue Services werden sofort erkannt
- ✅ **Dashboard**: Übersicht aller Routes

## Services Integration

Nach Traefik Deployment müssen andere Stacks angepasst werden:

### Portainer (optional)

Portainer kann auch über Traefik geroutet werden, bleibt aber auf :9443 erreichbar.

```bash
# Portainer Container Labels hinzufügen
docker stop portainer
docker rm portainer

# Neu starten mit Labels (siehe MIGRATION_GUIDE.md)
```

### Andere Stacks

- **CI Stack**: Gitea + Woodpecker → Labels hinzufügen, Ports entfernen
- **Registry Stack**: Harbor → Labels hinzufügen
- **Utils Stack**: Dozzle + Trivy → Labels hinzufügen

Siehe `TRAEFIK_MIGRATION_GUIDE.md` für Details.

## Monitoring

### Dashboard

```bash
# Traefik Dashboard
open http://traefik.devops.local:8080

# Zeigt:
# - Alle Router (Routing Rules)
# - Alle Services (Backend Targets)
# - Alle Middlewares
# - Health Checks
# - Metrics
```

### Prometheus Metrics

```bash
# Metrics Endpoint
curl http://traefik.devops.local:8080/metrics

# Integration mit Prometheus möglich
```

### Access Logs

```bash
# Logs im Container
docker logs traefik

# Access Log (alle HTTP Requests)
docker exec traefik cat /var/log/traefik/access.log
```

## Troubleshooting

### Service wird nicht geroutet

```bash
# 1. Prüfen ob Service im devops-network ist
docker network inspect devops-network

# 2. Prüfen ob traefik.enable=true gesetzt
docker inspect <container> | grep traefik.enable

# 3. Traefik Dashboard prüfen
open http://traefik.devops.local:8080
# → Routers → Service sollte dort erscheinen

# 4. Traefik Logs prüfen
docker logs traefik
```

### 404 Not Found

```bash
# Domain in /etc/hosts vorhanden?
cat /etc/hosts | grep devops.local

# DNS Cache leeren (macOS)
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

# Traefik Router Rule prüfen
# Host Matching ist case-sensitive!
```

### Connection Refused

```bash
# Ist Traefik Container running?
docker ps | grep traefik

# Ist Port 80 gemappt?
docker port traefik

# Ist Backend Service erreichbar?
docker exec traefik wget -O- http://<service>:<port>
```

## Features

- ✅ Automatische Service Discovery
- ✅ HTTP/HTTPS Load Balancing
- ✅ Dashboard & Monitoring
- ✅ Prometheus Metrics
- ✅ Access Logs
- ✅ Health Checks
- ✅ Hot Reload
- ✅ Middleware Support (Auth, Rate Limiting, Headers, etc.)

## Zukünftige Erweiterungen

### Let's Encrypt (Production)

```yaml
command:
  - "--certificatesresolvers.letsencrypt.acme.email=your@email.com"
  - "--certificatesresolvers.letsencrypt.acme.storage=/certs/acme.json"
  - "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web"
```

### BasicAuth Middleware

```yaml
labels:
  - "traefik.http.middlewares.auth.basicauth.users=admin:$$apr1$$..."
  - "traefik.http.routers.myservice.middlewares=auth"
```

### Rate Limiting

```yaml
labels:
  - "traefik.http.middlewares.ratelimit.ratelimit.average=100"
  - "traefik.http.routers.myservice.middlewares=ratelimit"
```

## Version

v1.0.0 - Initial Release
