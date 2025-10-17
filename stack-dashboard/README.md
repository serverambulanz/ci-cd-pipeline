# Dashboard Stack - Homarr

Modern Dashboard & Homepage für alle DevOps Services.

## Services

- **Homarr** (Port 7575 → via Traefik): Dashboard mit Widgets, Docker Integration, Multi-Board Support

## Schnellstart

```bash
# 1. Environment konfigurieren (optional)
cp .env.example .env
nano .env  # Admin Passwort ändern

# 2. Stack via Portainer deployen
# Portainer → Stacks → Add Stack → Git Repository
# URL: https://github.com/serverambulanz/ci-cd-pipeline
# Path: stack-dashboard/docker-compose.yml

# 3. Dashboard öffnen
open http://dashboard.devops.local
```

## URL

⚠️ **Requires Traefik Proxy Stack** (stack-proxy)

- Homarr Dashboard: http://dashboard.devops.local (via Traefik)

## Netzwerk

- **External**: `devops-network` (Stack-übergreifend)

## Volumes

Docker-managed Volumes:
- `homarr_configs`: Dashboard Konfiguration & Boards
- `homarr_data`: Persistent Data (Bookmarks, Settings, etc.)
- `homarr_icons`: Custom Icons

## Default Login

⚠️ **WICHTIG: Nach erstem Login ändern!**

```
Username: admin
Password: admin (oder was in .env gesetzt wurde)
```

**Nach Login**:
1. Settings → Users → Change Password
2. Neue Benutzer anlegen (optional)

## Features

### ✅ Multi-Board Support

Erstelle mehrere Dashboards/Seiten:
- **DevOps Board**: Gitea, Woodpecker, Harbor, Traefik
- **Monitoring Board**: Dozzle, System Stats, Container Status
- **Tools Board**: Portainer, Trivy, Utilities

**Boards erstellen**:
1. Dashboard öffnen
2. Settings (⚙️) → Boards
3. "Add Board" → Name eingeben → Save
4. Tabs oben zum Wechseln zwischen Boards

### ✅ Docker Integration

Homarr zeigt automatisch Docker Container:
- Container Status (Running/Stopped)
- Start/Stop Buttons
- Resource Usage
- Container Logs (Link zu Dozzle)

**Docker Widget hinzufügen**:
1. Edit Mode aktivieren (✏️)
2. "Add Widget" → "Docker"
3. Container auswählen → Save

### ✅ Service Widgets

Native Integrationen für:
- **Gitea**: Repo Count, Recent Commits
- **Woodpecker CI**: Build Status, Recent Builds
- **Portainer**: Container Stats
- **System**: CPU, RAM, Disk, Network

**App/Service hinzufügen**:
1. Edit Mode aktivieren (✏️)
2. "Add App" → Service-Typ wählen
3. Config:
   - Name: Gitea
   - URL: http://git.devops.local
   - Integration: Gitea
   - API Token: (optional, für Stats)
4. Save

### ✅ Weitere Widgets

- **Weather**: Wetter Widget
- **Calendar**: iCal Integration
- **RSS Feed**: News/Feeds
- **iFrame**: Beliebige Websites einbetten (z.B. Traefik Dashboard)
- **Clock/Date**: Uhrzeit & Datum
- **Search**: Schnellsuche (Google, DuckDuckGo, etc.)

## Beispiel Board Setup

### Board 1: "DevOps"

```
+------------------+------------------+------------------+
|   Gitea          |   Woodpecker     |   Harbor         |
|   git.devops.    |   ci.devops.     |   registry.dev   |
|   [Gitea Widget] |   [Build Status] |   [Registry]     |
+------------------+------------------+------------------+
|   Traefik        |   Portainer      |   Dozzle         |
|   Dashboard      |   Management     |   Logs           |
+------------------+------------------+------------------+
|   Docker Container Status Widget                      |
|   [Running: 15] [Stopped: 2]                          |
+-------------------------------------------------------+
```

### Board 2: "Monitoring"

```
+---------------------------+---------------------------+
|   System Stats Widget     |   Docker Stats Widget     |
|   CPU: 45%                |   Containers: 15          |
|   RAM: 8.2/16 GB          |   Images: 42              |
|   Disk: 120/500 GB        |   Volumes: 25             |
+---------------------------+---------------------------+
|   Traefik Dashboard (iFrame)                          |
|   [Embedded: traefik.devops.local:8080]               |
+-------------------------------------------------------+
|   Dozzle Logs (iFrame)                                |
|   [Embedded: logs.devops.local]                       |
+-------------------------------------------------------+
```

### Board 3: "Tools"

```
+------------------+------------------+------------------+
|   Trivy          |   Bookmarks      |   Notes          |
|   Vulnerability  |   [Bookmark Mgr] |   [Sticky Notes] |
+------------------+------------------+------------------+
```

## DevOps Services Setup Guide

### 1. Gitea Integration

```yaml
App Name: Gitea
URL: http://git.devops.local
Icon: gitea (auto)
Integration Type: Gitea

# Optional für Stats:
API Token: <Gitea Token>
API URL: http://git.devops.local/api/v1
```

**Gitea Token erstellen**:
1. Gitea → Settings → Applications → Generate Token
2. Scope: `read:repository, read:user`
3. Token in Homarr App Config einfügen

### 2. Woodpecker CI Integration

```yaml
App Name: Woodpecker CI
URL: http://ci.devops.local
Icon: woodpecker (oder custom)
Integration Type: Custom (kein natives Widget)

# Falls API gewünscht:
API URL: http://ci.devops.local/api
```

### 3. Harbor Registry

```yaml
App Name: Harbor
URL: http://registry.devops.local
Icon: harbor
Integration Type: Custom
```

### 4. Traefik Dashboard (iFrame Widget)

```yaml
Widget Type: iFrame
URL: http://traefik.devops.local:8080
Height: 600px
Refresh: 30s
```

### 5. Dozzle Logs (iFrame Widget)

```yaml
Widget Type: iFrame
URL: http://logs.devops.local
Height: 500px
Refresh: 10s
```

### 6. Docker Container Widget

```yaml
Widget Type: Docker
Show: All Containers
Filter: None
Actions: Show Start/Stop buttons
```

### 7. System Stats Widget

```yaml
Widget Type: System Stats
Show: CPU, RAM, Disk, Network
Update Interval: 5s
```

## Customization

### Themes

**Built-in Themes**:
- Light Mode
- Dark Mode (default)
- Custom CSS

**Theme ändern**:
1. Settings → Appearance
2. Theme wählen
3. Oder Custom CSS: Settings → Custom CSS

### Custom Icons

Icons in `/app/public/icons` ablegen:

```bash
# Icon hochladen
docker cp my-icon.png homarr:/app/public/icons/

# In App Config nutzen
Icon URL: /icons/my-icon.png
```

### Layout

**Drag & Drop**:
- Edit Mode aktivieren (✏️)
- Widgets per Drag & Drop verschieben
- Grid-System (responsive)

**Grid Settings**:
- Settings → Layout
- Columns: 3, 4, 6, oder 12
- Spacing anpassen

## Multi-User Setup

### Benutzer erstellen

1. Settings → Users
2. "Add User"
3. Username, Password, Role
4. Permissions setzen

**Rollen**:
- **Admin**: Volle Rechte
- **User**: Read + eigene Boards
- **Guest**: Read-only

### Per-Board Permissions

1. Board Settings
2. "Permissions"
3. User/Rolle zuweisen
4. Read/Write/Admin

## API Integration

### Homarr API nutzen

```bash
# API Endpoint
http://dashboard.devops.local/api

# Beispiel: Apps abrufen
curl http://dashboard.devops.local/api/apps

# Beispiel: Docker Container
curl http://dashboard.devops.local/api/docker/containers
```

**API Token**:
1. Settings → API
2. Generate Token
3. Header: `Authorization: Bearer <token>`

## Backup & Restore

### Backup

```bash
# Configs sichern
docker cp homarr:/app/data/configs ./homarr-backup/

# Oder Volume backup
docker run --rm -v homarr_configs:/data -v $(pwd):/backup alpine tar czf /backup/homarr-backup.tar.gz /data
```

### Restore

```bash
# Volume restore
docker run --rm -v homarr_configs:/data -v $(pwd):/backup alpine tar xzf /backup/homarr-backup.tar.gz -C /
```

## Troubleshooting

### Dashboard nicht erreichbar

```bash
# Container Status
export DOCKER_HOST="unix:///Volumes/DockerData/colima/default/docker.sock"
docker ps | grep homarr

# Logs prüfen
docker logs homarr

# Traefik Router prüfen
open http://traefik.devops.local:8080
# → HTTP → Routers → homarr@docker
```

### Docker Integration funktioniert nicht

**Prüfen**:
1. Docker Socket gemounted? `docker inspect homarr | grep docker.sock`
2. Permissions? Container muss Socket lesen können
3. Homarr Settings → Docker → "Enable Docker Integration"

### Widgets laden nicht

**Lösungen**:
1. Browser Cache leeren
2. Homarr neu starten: `docker restart homarr`
3. Config reset: Settings → Advanced → "Reset Config"

## Performance

**Ressourcen**:
- CPU: ~5% idle, ~15% unter Last
- RAM: ~150-300 MB
- Disk: ~100 MB (ohne Icons/Data)

**Optimierung**:
- Widget Refresh Intervals erhöhen
- Weniger Docker Container überwachen
- iFrame Widgets sparsam nutzen

## Security

### Best Practices

1. **Admin Passwort ändern** (sofort nach erstem Login!)
2. **Auth aktivieren**: Settings → Authentication → Enable
3. **HTTPS** (später via Traefik + Let's Encrypt)
4. **API Token** für externe Zugriffe
5. **Read-only Docker Socket** (bereits konfiguriert: `:ro`)

### Reverse Proxy Security

Mit Traefik später erweiterbar:
- BasicAuth Middleware
- IP Whitelist
- Rate Limiting

## Version

v1.0.0 - Initial Release (Homarr latest)

## Links

- **Homarr Docs**: https://homarr.dev/docs
- **GitHub**: https://github.com/ajnart/homarr
- **Integrations**: https://homarr.dev/docs/integrations

---

**Viel Spaß mit deinem DevOps Dashboard! 🎨🚀**
