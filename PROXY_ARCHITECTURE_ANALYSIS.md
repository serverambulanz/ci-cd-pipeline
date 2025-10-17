# Proxy Architecture Analysis

## 📊 Aktueller Status

### Netzwerk-Setup
- **devops-network**: External bridge network (172.20.0.0/16)
  - Aktuell: Portainer, Gitea, Woodpecker Server, Woodpecker Agent
- **ci-internal**: Stack-spezifisch für CI-Stack

### Aktuell exponierte Ports (Host → Container)

| Service | Ports | Funktion |
|---------|-------|----------|
| **Portainer** | 9443 (HTTPS), 8000 (Edge Agent) | Management UI |
| **Gitea** | 3000 (HTTP), 2222 (SSH) | Git Server + Web UI |
| **Woodpecker** | 7050 (HTTP), 9000 (gRPC Agent) | CI/CD Web UI + Agent Kommunikation |
| **Harbor** | 5000 (HTTP) | Container Registry (noch nicht deployed) |
| **Dozzle** | 8888 (HTTP) | Log Viewer (noch nicht deployed) |
| **Trivy** | 8081 (HTTP) | Vulnerability Scanner API (noch nicht deployed) |
| **DefectDojo** | 8082 (HTTP) | Security Testing (optional) |

**Total: 8+ öffentlich exponierte Ports**

---

## ✅ Vorteile Reverse Proxy Architektur

### Sicherheit
- ✅ **Nur 2-3 Ports exponiert** (80, 443, ggf. 22 für Git SSH)
- ✅ **Zentrale TLS/SSL Terminierung** (Let's Encrypt Integration)
- ✅ **Kein direkter Container-Zugriff** von außen
- ✅ **WAF Integration möglich** (Web Application Firewall)

### Management
- ✅ **Zentrale Routing-Konfiguration**
- ✅ **Subdomain/Path-basiertes Routing**
  - `git.local` → Gitea
  - `ci.local` → Woodpecker
  - `registry.local` → Harbor
  - `logs.local` → Dozzle
- ✅ **Automatische Service Discovery** (bei Traefik via Labels)
- ✅ **Load Balancing** möglich

### Monitoring & Observability
- ✅ **Zentrale Access Logs**
- ✅ **Request Metrics** (Traefik Dashboard)
- ✅ **Health Checks** auf Proxy-Ebene

---

## 🔄 Traefik vs Nginx Proxy Manager

### Traefik ⭐ (Empfehlung)

**Vorteile:**
- ✅ **Docker-native**: Automatische Service Discovery via Labels
- ✅ **Zero-Config**: Services registrieren sich selbst
- ✅ **Let's Encrypt Integration**: Automatische SSL-Zertifikate
- ✅ **Dashboard**: Übersicht aller Routes & Services
- ✅ **Metrics**: Prometheus Integration
- ✅ **Hot Reload**: Keine Restarts bei Config-Änderungen
- ✅ **Middleware**: Rate Limiting, Headers, Auth, Redirects

**Nachteile:**
- ⚠️ Komplexere Konfiguration (Labels in docker-compose.yml)
- ⚠️ Lernkurve bei komplexen Setups

**Beispiel Config:**
```yaml
services:
  gitea:
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.gitea.rule=Host(`git.local`)"
      - "traefik.http.services.gitea.loadbalancer.server.port=3000"
    # KEINE ports: mehr nötig!
```

---

### Nginx Proxy Manager 🎨

**Vorteile:**
- ✅ **Grafische Oberfläche**: Einfache Web-UI für Routing
- ✅ **Let's Encrypt Integration**: GUI-basiert
- ✅ **Access Lists**: IP-basierte Zugriffskontrolle
- ✅ **Custom Locations**: Flexible Routing-Regeln
- ✅ **SSL Management**: Zertifikate hochladen/verwalten

**Nachteile:**
- ⚠️ Manuelle Konfiguration pro Service (kein Auto-Discovery)
- ⚠️ Keine Prometheus Metrics
- ⚠️ Weniger flexibel bei komplexen Routing-Szenarien

---

## 🎯 Empfehlung: **Traefik**

### Warum Traefik?
1. **GitOps-Workflow**: Routing via Labels in docker-compose.yml → alles versioniert
2. **Automatisierung**: Neue Services werden automatisch erkannt
3. **Portainer-Kompatibel**: Labels funktionieren perfekt mit Portainer Stacks
4. **Weniger Overhead**: Keine separate UI-Konfiguration nötig
5. **DevOps-Philosophie**: Infrastructure as Code

---

## 📐 Ziel-Architektur mit Traefik

```
Internet/Host
    ↓
[Traefik Proxy]
  - Port 80 (HTTP)
  - Port 443 (HTTPS)
  - Port 8080 (Dashboard)
    ↓
devops-network (internal)
    ├─ Portainer (9443 → nur für Traefik Dashboard Zugriff via reverse proxy)
    ├─ Gitea (3000 → intern)
    ├─ Woodpecker (8000 → intern)
    ├─ Harbor (80 → intern)
    ├─ Dozzle (8080 → intern)
    └─ Trivy (8080 → intern)
```

### Routing Schema
| Service | URL | Interner Port |
|---------|-----|---------------|
| Traefik Dashboard | http://traefik.local:8080 | 8080 |
| Portainer | https://portainer.local | 9443 |
| Gitea | https://git.local | 3000 |
| Woodpecker | https://ci.local | 8000 |
| Harbor | https://registry.local | 80 |
| Dozzle | https://logs.local | 8080 |
| Trivy | https://trivy.local | 8080 |

### Git SSH Access
- **Gitea SSH bleibt exponiert**: Port 2222 (kein HTTP/HTTPS Proxy möglich)
- Alternative: Traefik TCP Router (komplexer)

---

## 🚀 Migrations-Plan

### Phase 1: Traefik Stack erstellen
- [ ] `stack-proxy/docker-compose.yml` mit Traefik
- [ ] Traefik Dashboard aktivieren
- [ ] Let's Encrypt Staging konfigurieren

### Phase 2: Bestehende Stacks anpassen
- [ ] CI Stack: Labels hinzufügen, Ports entfernen
- [ ] Registry Stack: Labels hinzufügen
- [ ] Utils Stack: Labels hinzufügen

### Phase 3: Testing & Rollout
- [ ] Lokale DNS konfigurieren (`/etc/hosts`)
- [ ] Services über Traefik testen
- [ ] Alte Port-Mappings entfernen

### Phase 4: Security Hardening
- [ ] HTTPS Redirect aktivieren
- [ ] Let's Encrypt Production
- [ ] BasicAuth für sensible Services

---

## ⚠️ Wichtige Überlegungen

### 1. Portainer Zugriff
**Problem**: Portainer braucht 9443 für Management-UI
**Lösung**:
- Option A: Portainer auch über Traefik (https://portainer.local)
- Option B: Portainer Port 9443 weiterhin exponiert (Management-Tool)

### 2. Woodpecker Agent Kommunikation
**Problem**: Agent braucht Port 9000 (gRPC) zum Server
**Lösung**:
- Port 9000 bleibt intern (nur im devops-network)
- Kein Proxy nötig (interne Kommunikation)

### 3. Harbor Registry
**Problem**: Docker Push/Pull braucht direkten Registry-Zugriff
**Lösung**:
- Traefik kann Docker Registry Protokoll routen
- `registry.local` → Harbor (funktioniert transparent)

### 4. Development Domain
**Lokal**:
```bash
# /etc/hosts
127.0.0.1 git.local ci.local registry.local logs.local traefik.local portainer.local
```

**Produktiv**: Echte Domain mit DNS (z.B. `devops.example.com`)

---

## 📊 Netzwerk-Architektur

### Aktuell (Multi-Port)
```
Host:3000 → Gitea
Host:7050 → Woodpecker
Host:5000 → Harbor
Host:8888 → Dozzle
Host:9443 → Portainer
```

### Mit Traefik (Unified Access)
```
Host:80/443 → Traefik → [git.local, ci.local, registry.local, ...]
Host:2222 → Gitea SSH (direkt)
Host:9443 → Portainer (optional direkt)
```

---

## 🎯 Nächste Schritte

1. **Entscheidung bestätigen**: Traefik oder NPM?
2. **Proxy Stack erstellen**: `stack-proxy/docker-compose.yml`
3. **Migrations-Strategie**: Schritt für Schritt oder Big Bang?
4. **Domain-Schema**: Welche `.local` Domains?

**Warte auf Anweisungen für Umsetzung.**
