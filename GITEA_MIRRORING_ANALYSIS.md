# Gitea Branch Mirroring mit GitHub/GitLab - Analyse

## 🎯 Szenario

**Ziel**: GitHub/GitLab soll sich Code von lokalem Gitea holen (Pull/Mirror)

```
Gitea (lokal)  →  [Push Mirror]  →  GitHub/GitLab (extern)
    ↑
    └─ Primary Source of Truth
```

---

## ⚠️ Problem: Lokales Setup vs. Externe Services

### Aktuelles Setup
```
macOS Host (Entwicklungsmaschine)
    ↓
Colima VM (Docker)
    ↓
Gitea Container (git.devops.local)
    ↓
127.0.0.1:3000 (nur lokal erreichbar)
```

### Was GitHub/GitLab braucht
```
Öffentlich erreichbare URL
    ↓
https://git.example.com (öffentliche IP/Domain)
    ↓
Gitea API + Git Protocol
```

---

## 🚫 Kritisches Problem: **Nicht von extern erreichbar!**

### Warum es NICHT funktioniert (aktuell)

#### 1. Lokale IP/Domain
```bash
# Gitea URL aktuell
http://git.devops.local  # Nur in /etc/hosts auf DEINEM Mac
http://localhost:3000     # Nur auf deinem Mac
http://127.0.0.1:3000    # Nur auf deinem Mac
```

**Problem**:
- ❌ GitHub/GitLab Server können `git.devops.local` NICHT auflösen
- ❌ `127.0.0.1` ist für GitHub/GitLab deren eigener localhost
- ❌ Keine öffentliche IP/Domain

#### 2. Kein Inbound-Zugriff
```
GitHub/GitLab (Internet)
    ↓
    ❌ Keine Route zu deinem Mac
    ↓
Deine Fritz!Box/Router (NAT)
    ↓
Dein Mac (private IP: 192.168.x.x)
    ↓
Colima VM (bridge network)
    ↓
Gitea Container
```

**Problem**:
- ❌ Keine öffentliche IP
- ❌ Keine Portweiterleitung (NAT)
- ❌ Keine Firewall-Regeln

#### 3. Mirror Direction
```
# Was du willst (Push Mirror von Gitea)
Gitea → GitHub/GitLab  ✅ Funktioniert!

# Was du NICHT willst (Pull Mirror von GitHub/GitLab)
Gitea ← GitHub/GitLab  ❌ Braucht öffentlichen Zugriff
```

---

## ✅ Lösung: **Push Mirror statt Pull Mirror**

### Push Mirror (Gitea → GitHub/GitLab)

**Wie es funktioniert**:
1. Code wird zu Gitea gepusht
2. Gitea pusht automatisch zu GitHub/GitLab
3. **Gitea initiiert die Verbindung** (outbound)

**Gitea Konfiguration**:
```
Repo Settings → Mirror Settings → Push Mirror
    - Remote Git URL: https://github.com/user/repo.git
    - Username: dein-github-user
    - Password/Token: ghp_xxxxxxxxxxxxx
    - Sync on Commit: ✅
    - Branches: main, develop, etc.
```

**Vorteile**:
- ✅ Keine öffentliche IP nötig
- ✅ Gitea macht ausgehende Verbindung zu GitHub
- ✅ Funktioniert hinter NAT/Firewall
- ✅ Automatisch bei jedem Commit

**Nachteile**:
- ⚠️ Gitea muss GitHub/GitLab erreichen können (Internetverbindung)
- ⚠️ Credentials in Gitea speichern (Token)

---

## 🔄 Gitea Mirror Arten

### 1. Push Mirror (Gitea → Extern) ✅ **EMPFOHLEN**

```yaml
Direction: Outbound
Gitea ist Master → Synchronisiert zu GitHub/GitLab

Voraussetzungen:
- ✅ Internetverbindung von Gitea
- ✅ GitHub/GitLab Token
- ❌ KEINE öffentliche IP nötig
```

**Use Case**: Backup, CI/CD auf GitHub Actions/GitLab CI zusätzlich zu Woodpecker

### 2. Pull Mirror (Gitea ← Extern) ✅ Funktioniert auch!

```yaml
Direction: Inbound
GitHub/GitLab ist Master → Gitea holt sich Updates

Gitea Konfiguration:
- Migrate → Mirror from GitHub/GitLab
- Gitea pollt regelmäßig GitHub API
```

**Vorteile**:
- ✅ Gitea initiiert Verbindung (outbound)
- ✅ Keine öffentliche IP nötig
- ✅ Gitea holt sich Updates selbst

**Use Case**: Mirror von öffentlichen Repos für lokale CI/CD

### 3. Bidirektionales Mirror ⚠️ KOMPLIZIERT

**Problem**: Merge-Konflikte, Race Conditions
**Nicht empfohlen** für Production

---

## 🎯 Empfohlene Architekturen

### Architektur 1: Push Mirror (Einfach) ⭐

```
Developer
    ↓ git push
Gitea (lokal)
    ↓ auto push mirror
GitHub/GitLab (extern)
    ↓ (optional)
GitHub Actions / GitLab CI
```

**Workflow**:
1. Entwickler pusht zu Gitea (`git.devops.local`)
2. Gitea triggert:
   - Woodpecker CI (lokal) ✅
   - Push Mirror zu GitHub ✅
3. GitHub/GitLab hat aktuellen Code
4. Optional: GitHub Actions für externe CI/CD

**Vorteile**:
- ✅ Keine öffentliche IP nötig
- ✅ Gitea ist Source of Truth
- ✅ Automatisches Backup zu GitHub/GitLab
- ✅ Beste Integration mit Woodpecker

### Architektur 2: Dual-Remote (Manuell)

```
Developer
    ↓ git push origin (Gitea)
    ↓ git push github (GitHub)
Gitea (lokal) + GitHub/GitLab (extern)
```

**Git Config**:
```bash
git remote add origin http://git.devops.local/user/repo.git
git remote add github https://github.com/user/repo.git

# Push zu beiden
git push origin main
git push github main
```

**Vorteile**:
- ✅ Volle Kontrolle
- ✅ Kein automatisches Mirror

**Nachteile**:
- ⚠️ Manuelles doppeltes Pushen

### Architektur 3: Öffentliches Gitea (Advanced) 🌐

**Für Production/Team-Setup**:

```
Internet
    ↓
Öffentliche Domain (git.example.com)
    ↓
Cloudflare Tunnel / ngrok / VPS
    ↓
Dein Gitea (lokal)
```

**Technologien**:
- **Cloudflare Tunnel**: Kostenlos, kein Port-Forwarding nötig
- **ngrok**: Tunneling Service
- **WireGuard VPN + VPS**: Reverse Proxy über VPS

**Dann funktioniert**:
- ✅ GitHub/GitLab kann Gitea erreichen
- ✅ Pull Mirror möglich
- ✅ Webhooks von GitHub zu Gitea

**Komplexität**: Hoch, nur für Production sinnvoll

---

## 🛠️ Traefik Impact auf Git Mirroring

### Git Operations über Traefik

```
Git Client
    ↓ HTTP(S)
Traefik (Port 80/443)
    ↓ Routing: git.devops.local
Gitea (Port 3000, intern)
```

**Status**: ✅ **Kein Problem!**

**Warum**:
- ✅ Traefik routet HTTP(S) transparent
- ✅ Git HTTP(S) Protocol funktioniert über Reverse Proxy
- ✅ Gitea erkennt korrekte URLs (X-Forwarded-* Headers)

**Traefik Config für Gitea**:
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.gitea.rule=Host(`git.devops.local`)"
  - "traefik.http.services.gitea.loadbalancer.server.port=3000"

  # Wichtig für Git HTTP(S)
  - "traefik.http.middlewares.gitea-headers.headers.customrequestheaders.X-Forwarded-Proto=http"
  - "traefik.http.routers.gitea.middlewares=gitea-headers"
```

### Git SSH (Port 2222)

**Problem**: SSH ist kein HTTP → Traefik kann's nicht routen (standardmäßig)

**Lösung**: SSH Port bleibt direkt exponiert
```yaml
# Gitea docker-compose.yml
ports:
  - "2222:22"  # SSH bleibt außerhalb von Traefik
# KEIN Port 3000 mehr nötig (nur intern via Traefik)
```

**Git Remote URLs**:
```bash
# HTTP(S) über Traefik
git clone http://git.devops.local/user/repo.git

# SSH direkt (bypass Traefik)
git clone ssh://git@git.devops.local:2222/user/repo.git
```

---

## 📊 Mirror Szenarien

### Szenario 1: Gitea → GitHub (Push Mirror) ✅

**Setup**:
```
1. Gitea Repo: http://git.devops.local/team/project
2. GitHub Repo: https://github.com/team/project
3. Gitea: Mirror Settings → Push to GitHub
```

**Funktionalität**:
- ✅ Jeder Push zu Gitea → auto push zu GitHub
- ✅ Gitea = Source of Truth
- ✅ GitHub = Backup + optional CI/CD

**Traefik**: Kein Impact, funktioniert

### Szenario 2: GitHub → Gitea (Pull Mirror) ✅

**Setup**:
```
1. GitHub Repo: https://github.com/external/lib
2. Gitea: New Migration → Mirror from GitHub
3. Gitea pollt GitHub API (5min Intervall)
```

**Funktionalität**:
- ✅ Gitea holt sich Updates von GitHub
- ✅ Lokale Kopie für CI/CD
- ✅ Kein GitHub API Rate Limit für Builds

**Traefik**: Kein Impact, funktioniert

### Szenario 3: GitHub → Gitea (Webhook) ❌

**Setup**:
```
GitHub Webhook → http://git.devops.local/api/webhook
```

**Problem**:
- ❌ GitHub kann `git.devops.local` nicht erreichen
- ❌ Lokale Domain, keine öffentliche IP

**Lösung**:
- ✅ Pull Mirror statt Webhook (Gitea pollt)
- ✅ Oder: Cloudflare Tunnel für öffentlichen Zugriff

---

## 🎯 Empfehlung für euer Setup

### Development/Lokal Setup (jetzt)

**Architektur**: Push Mirror von Gitea zu GitHub/GitLab

```
Code Development
    ↓
Gitea (git.devops.local via Traefik)
    ├─ Woodpecker CI (lokal) ✅
    └─ Push Mirror → GitHub ✅
         └─ (optional) GitHub Actions
```

**Konfiguration**:
1. ✅ Gitea über Traefik erreichbar (intern)
2. ✅ Push Mirror zu GitHub einrichten
3. ✅ GitHub Token in Gitea hinterlegen
4. ✅ Auto-Sync on Commit aktivieren

**Vorteile**:
- ✅ Keine öffentliche IP nötig
- ✅ Funktioniert mit Traefik
- ✅ Automatisches Backup
- ✅ Kann GitHub Actions zusätzlich nutzen

### Production/Team Setup (später)

**Falls externe Kollegen auf Gitea zugreifen müssen**:

**Option A: Cloudflare Tunnel** (Empfohlen)
```bash
# Kostenlos, kein Port-Forwarding
cloudflared tunnel create gitea
cloudflared tunnel route dns gitea git.example.com
cloudflared tunnel run gitea
```

**Option B: VPS Reverse Proxy**
```
VPS (öffentliche IP)
    ↓ WireGuard VPN
Dein Netzwerk
    ↓
Gitea
```

---

## ✅ Fazit

### Funktioniert mit aktuellem Setup (Traefik + lokal):

1. ✅ **Gitea → GitHub/GitLab (Push Mirror)** - EMPFOHLEN
   - Gitea ist Master
   - Auto-Push zu GitHub/GitLab
   - Kein öffentlicher Zugriff nötig

2. ✅ **GitHub/GitLab → Gitea (Pull Mirror)**
   - GitHub ist Master
   - Gitea holt sich Updates
   - Kein öffentlicher Zugriff nötig

### Funktioniert NICHT mit lokalem Setup:

3. ❌ **GitHub/GitLab → Gitea (Push/Webhook)**
   - Bräuchte öffentlichen Zugriff
   - Lösung: Cloudflare Tunnel oder VPS

### Traefik Impact:

- ✅ Git HTTP(S) funktioniert über Traefik
- ✅ Git SSH bleibt auf Port 2222 (direkt)
- ✅ Mirror Push von Gitea funktioniert
- ✅ Mirror Pull von Gitea funktioniert

**Keine Probleme mit Traefik und Mirroring!** 🎉

---

## 🚀 Nächste Schritte

1. Traefik Setup wie geplant durchführen
2. Gitea über `git.devops.local` erreichbar machen
3. Push Mirror zu GitHub/GitLab einrichten (optional)
4. Testen: Push zu Gitea → Auto-Push zu GitHub

**Bereit für weitere Anweisungen!**
