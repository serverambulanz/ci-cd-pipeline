# Traefik Migration Guide

Migrations-Anleitung für den Wechsel von Direct Port Mapping zu Traefik Reverse Proxy.

## 📋 Übersicht

### Vorher (Direct Port Mapping)
```
Host Ports → Container Ports
3000      → Gitea
7050      → Woodpecker
5000      → Harbor
8081      → Trivy
8888      → Dozzle
9443      → Portainer
8000      → Portainer Edge
```

### Nachher (Traefik Reverse Proxy)
```
Host Port 80 → Traefik → [git.devops.local, ci.devops.local, ...]
    2222 → Gitea SSH (direct)
    9000 → Woodpecker gRPC (direct)
    9443 → Portainer HTTPS (optional direct)
    8000 → Portainer Edge (direct)
    8080 → Traefik Dashboard (direct)
```

---

## 🚀 Migrations-Schritte

### Phase 1: Vorbereitung (5 Min)

#### 1.1 macOS /etc/hosts konfigurieren

```bash
# Domains für Traefik Routing hinzufügen
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

# Verify
ping -c 1 git.devops.local  # Sollte 127.0.0.1 antworten
```

#### 1.2 Änderungen auf GitHub committen

⚠️ **WICHTIG**: Erst committen, dann deployen (da Portainer von Git deployed)!

```bash
cd /Volumes/DockerData/stacks

# Git Status prüfen
git status

# Alle Änderungen committen
git add .
git commit -m "Add Traefik reverse proxy and update all stacks for Traefik integration"
git push origin main
```

---

### Phase 2: Traefik Deployment (2 Min)

#### 2.1 Proxy Stack deployen

**Via Portainer UI**:
1. **Stacks** → **Add Stack**
2. **Name**: `stack-proxy`
3. **Build method**: Git Repository
4. **Repository URL**: `https://github.com/serverambulanz/ci-cd-pipeline`
5. **Repository reference**: `refs/heads/main`
6. **Compose path**: `stack-proxy/docker-compose.yml`
7. **Deploy the stack**

#### 2.2 Traefik Verify

```bash
# Container prüfen
export DOCKER_HOST="unix:///Volumes/DockerData/colima/default/docker.sock"
docker ps | grep traefik

# Dashboard öffnen
open http://traefik.devops.local:8080

# HTTP Test
curl -v http://traefik.devops.local:8080
```

**Erwartetes Ergebnis**: Traefik Dashboard erreichbar ✅

---

### Phase 3: CI Stack Migration (5 Min)

#### 3.1 CI Stack neu deployen

**Via Portainer UI**:
1. **Stacks** → Bestehenden `ci-stack` oder `stack-ci` auswählen
2. **Update the stack**
   - ✅ **Re-pull image and redeploy** aktivieren
   - ✅ **Prune services** aktivieren (entfernt alte Container)
3. **Update**

Portainer holt sich automatisch die neuen Änderungen von GitHub!

#### 3.2 Verify CI Stack

```bash
# Container prüfen
docker ps | grep -E "(gitea|woodpecker)"

# Services über Traefik testen
curl -I http://git.devops.local
curl -I http://ci.devops.local

# Browser öffnen
open http://git.devops.local
open http://ci.devops.local
```

**Erwartetes Ergebnis**:
- ✅ Gitea erreichbar über `http://git.devops.local`
- ✅ Woodpecker erreichbar über `http://ci.devops.local`
- ✅ SSH weiterhin auf Port 2222

#### 3.3 Gitea OAuth Config anpassen (falls bereits konfiguriert)

Falls Woodpecker OAuth bereits in Gitea eingerichtet ist:

1. **Gitea** → Settings → Applications → OAuth2 Applications
2. OAuth Application für Woodpecker bearbeiten
3. **Redirect URI** ändern:
   - ALT: `http://localhost:7050/authorize`
   - NEU: `http://ci.devops.local/authorize`
4. Save

---

### Phase 4: Utils Stack Deployment (3 Min)

⚠️ **Utils Stack sollte VOR Registry Stack deployed werden** (Trivy für Harbor)

#### 4.1 Utils Stack deployen

**Via Portainer UI**:
1. **Stacks** → **Add Stack**
2. **Name**: `stack-utils`
3. **Build method**: Git Repository
4. **Repository URL**: `https://github.com/serverambulanz/ci-cd-pipeline`
5. **Repository reference**: `refs/heads/main`
6. **Compose path**: `stack-utils/docker-compose.yml`
7. **Environment variables** (optional):
   ```
   TRIVY_GITHUB_TOKEN=<your_github_token_optional>
   ```
8. **Deploy the stack**

#### 4.2 Verify Utils Stack

```bash
# Services testen
curl http://trivy.devops.local/healthz
curl http://logs.devops.local

# Browser öffnen
open http://logs.devops.local  # Dozzle Log Viewer
```

**Erwartetes Ergebnis**:
- ✅ Dozzle zeigt Logs aller Container
- ✅ Trivy API erreichbar

---

### Phase 5: Registry Stack Deployment (5 Min)

#### 5.1 Registry Stack deployen

**Via Portainer UI**:
1. **Stacks** → **Add Stack**
2. **Name**: `stack-registry`
3. **Build method**: Git Repository
4. **Repository URL**: `https://github.com/serverambulanz/ci-cd-pipeline`
5. **Repository reference**: `refs/heads/main`
6. **Compose path**: `stack-registry/docker-compose.yml`
7. **Environment variables**:
   ```
   HARBOR_CORE_SECRET=4e4f6468aa8716dc377a980ab9074db2
   HARBOR_JOBSERVICE_SECRET=a90ef335880c0effbd08efa73e33ea22
   HARBOR_REGISTRY_SECRET=31382c9bbb1e01bc8d593627e469df74
   HARBOR_REGISTRY_PASSWORD=90d32c41430ec91722197d05f0f5b82d
   HARBOR_DB_PASSWORD=d37e7462ddbd2666b261470855330640
   TRIVY_GITHUB_TOKEN=<optional>
   ```
8. **Deploy the stack**

⏱️ **Hinweis**: Harbor braucht ~2-3 Minuten zum Starten (viele Services)

#### 5.2 Verify Registry Stack

```bash
# Container Status prüfen
docker ps | grep harbor

# Harbor testen
curl -I http://registry.devops.local

# Browser öffnen
open http://registry.devops.local
```

**Erwartetes Ergebnis**:
- ✅ Harbor UI erreichbar
- ✅ Login: `admin` / `Harbor12345`
- ⚠️ **SOFORT Passwort ändern!**

#### 5.3 Harbor Post-Setup

1. **Passwort ändern**: Admin → Change Password
2. **Projekt erstellen**: z.B. "dev", "staging", "production"
3. **Image Push Test**:
   ```bash
   # Docker Login
   docker login registry.devops.local
   # User: admin
   # Password: <new_password>

   # Test Image pushen
   docker tag alpine:latest registry.devops.local/dev/alpine:test
   docker push registry.devops.local/dev/alpine:test
   ```

---

### Phase 6: Verification & Cleanup (3 Min)

#### 6.1 Alle Services prüfen

```bash
# Alle Container
export DOCKER_HOST="unix:///Volumes/DockerData/colima/default/docker.sock"
docker ps --format "table {{.Names}}\t{{.Status}}"

# Erwartete Container:
# - traefik
# - portainer
# - gitea
# - woodpecker-server
# - woodpecker-agent
# - trivy-server
# - dozzle
# - harbor-db
# - harbor-redis
# - harbor-core
# - harbor-portal
# - harbor-registry
# - harbor-registryctl
# - harbor-jobservice
# - harbor-nginx
# - harbor-trivy
```

#### 6.2 Traefik Dashboard prüfen

```bash
open http://traefik.devops.local:8080
```

**Im Dashboard sollten sichtbar sein**:
- **HTTP Routers**: gitea, woodpecker, harbor, trivy, dozzle
- **Services**: Alle Backend Services
- **Entrypoints**: web (Port 80)

#### 6.3 URL-Übersicht

Alle Services sollten erreichbar sein:

| Service | URL | Status |
|---------|-----|--------|
| Traefik Dashboard | http://traefik.devops.local:8080 | ✅ |
| Portainer | https://localhost:9443 | ✅ |
| Gitea | http://git.devops.local | ✅ |
| Gitea SSH | ssh://git@localhost:2222 | ✅ |
| Woodpecker | http://ci.devops.local | ✅ |
| Harbor | http://registry.devops.local | ✅ |
| Dozzle Logs | http://logs.devops.local | ✅ |
| Trivy API | http://trivy.devops.local | ✅ |

---

## 🔧 Troubleshooting

### Problem: Service nicht erreichbar (404 Not Found)

**Diagnose**:
```bash
# 1. Domain auflösung prüfen
ping git.devops.local  # Muss 127.0.0.1 sein

# 2. Traefik Dashboard prüfen
open http://traefik.devops.local:8080
# → Routers → Service sollte da sein

# 3. Container prüfen
docker ps | grep <service>
docker logs <service>

# 4. Traefik Logs prüfen
docker logs traefik
```

**Lösungen**:
- ✅ `/etc/hosts` Eintrag fehlt → hinzufügen
- ✅ DNS Cache leeren: `sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder`
- ✅ Container nicht im `devops-network` → docker-compose.yml prüfen
- ✅ Label `traefik.enable=true` fehlt → docker-compose.yml prüfen

### Problem: Connection Refused

```bash
# Ist Traefik running?
docker ps | grep traefik

# Ist Port 80 gemappt?
docker port traefik

# Ist Service im gleichen Netzwerk?
docker network inspect devops-network
```

### Problem: Gitea OAuth funktioniert nicht mehr

**Lösung**: Redirect URI in Gitea OAuth Config anpassen:
1. Gitea → Settings → Applications → OAuth2
2. Redirect URI: `http://ci.devops.local/authorize`
3. Save

### Problem: Harbor Push/Pull funktioniert nicht

**Diagnose**:
```bash
# Docker Login Test
docker login registry.devops.local

# Harbor nginx Logs
docker logs harbor-nginx

# Traefik Router prüfen
curl -v http://registry.devops.local/v2/
```

**Lösung**: Harbor `EXT_ENDPOINT` muss `http://registry.devops.local` sein (bereits konfiguriert)

---

## 📊 Port-Übersicht nach Migration

### Exponierte Ports (auf macOS Host)

| Port | Service | Protokoll | Zweck |
|------|---------|-----------|-------|
| 80 | Traefik | HTTP | **Alle Web Services** |
| 443 | Traefik | HTTPS | Zukünftig für TLS |
| 8080 | Traefik | HTTP | Dashboard |
| 2222 | Gitea | SSH | Git SSH Access |
| 9000 | Woodpecker | gRPC | Agent Kommunikation |
| 8000 | Portainer | HTTP | Edge Agent |
| 9443 | Portainer | HTTPS | Management UI |

**Reduzierung: 8+ Ports → 7 Ports** (alle Web-Services über Port 80!)

### Interne Kommunikation (nur devops-network)

| Service | Port | Nur intern |
|---------|------|------------|
| Gitea HTTP | 3000 | ✅ |
| Woodpecker HTTP | 8000 | ✅ |
| Harbor nginx | 8080 | ✅ |
| Trivy | 8080 | ✅ |
| Dozzle | 8080 | ✅ |

---

## 🎯 Rollback Plan (falls nötig)

Falls die Migration Probleme macht:

### Schneller Rollback

```bash
# 1. Traefik Stack löschen
# Portainer UI → Stacks → stack-proxy → Remove

# 2. CI Stack auf alte Version zurücksetzen
cd /Volumes/DockerData/stacks
git log --oneline  # Commit vor Migration finden
git revert <commit-hash>
git push origin main

# 3. CI Stack in Portainer updaten
# Portainer → Stacks → stack-ci → Update

# 4. /etc/hosts Einträge optional entfernen
sudo nano /etc/hosts
# DevOps Stack Zeilen löschen
```

---

## ✅ Success Criteria

Migration ist erfolgreich wenn:

- ✅ Alle Services über `*.devops.local` erreichbar
- ✅ Traefik Dashboard zeigt alle Router
- ✅ Gitea OAuth funktioniert mit neuer URL
- ✅ Harbor Push/Pull funktioniert
- ✅ Dozzle zeigt alle Container Logs
- ✅ SSH zu Gitea funktioniert (Port 2222)
- ✅ Nur noch Port 80 für Web-Services (statt 5+)

---

## 🚀 Next Steps nach erfolgreicher Migration

### Optional: HTTPS/TLS aktivieren

Für Production mit echter Domain:

```yaml
# traefik docker-compose.yml erweitern
command:
  - "--certificatesresolvers.letsencrypt.acme.email=your@email.com"
  - "--certificatesresolvers.letsencrypt.acme.storage=/certs/acme.json"
  - "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web"

# Services Labels erweitern
labels:
  - "traefik.http.routers.gitea-secure.rule=Host(`git.example.com`)"
  - "traefik.http.routers.gitea-secure.entrypoints=websecure"
  - "traefik.http.routers.gitea-secure.tls.certresolver=letsencrypt"
```

### Optional: BasicAuth Middleware

Für zusätzliche Sicherheit:

```bash
# Password Hash generieren
htpasswd -nB admin

# Label hinzufügen
labels:
  - "traefik.http.middlewares.auth.basicauth.users=admin:$$apr1$$..."
  - "traefik.http.routers.myservice.middlewares=auth"
```

### Optional: Rate Limiting

```yaml
labels:
  - "traefik.http.middlewares.ratelimit.ratelimit.average=100"
  - "traefik.http.routers.myservice.middlewares=ratelimit"
```

---

## 📝 Migration Checklist

```
☐ Phase 1: Vorbereitung
  ☐ /etc/hosts konfiguriert
  ☐ Änderungen committed und gepusht

☐ Phase 2: Traefik
  ☐ Proxy Stack deployed
  ☐ Dashboard erreichbar

☐ Phase 3: CI Stack
  ☐ Stack updated
  ☐ Gitea über git.devops.local erreichbar
  ☐ Woodpecker über ci.devops.local erreichbar
  ☐ OAuth angepasst (falls nötig)

☐ Phase 4: Utils Stack
  ☐ Stack deployed
  ☐ Dozzle über logs.devops.local erreichbar
  ☐ Trivy über trivy.devops.local erreichbar

☐ Phase 5: Registry Stack
  ☐ Stack deployed
  ☐ Harbor über registry.devops.local erreichbar
  ☐ Admin Passwort geändert
  ☐ Projekt erstellt
  ☐ Image Push Test erfolgreich

☐ Phase 6: Verification
  ☐ Alle Services erreichbar
  ☐ Traefik Dashboard zeigt alle Router
  ☐ Keine Port-Konflikte

✅ Migration abgeschlossen!
```

---

**Estimated Total Time**: ~25 Minuten

**Downtime**: ~5 Minuten pro Stack (während Update)

**Viel Erfolg! 🚀**
