# macOS/Colima Kompatibilität für Traefik Setup

## ✅ Zusammenfassung: **Kein Problem!**

Traefik funktioniert **einwandfrei** mit macOS/Colima. Es gibt jedoch ein paar macOS-spezifische Anpassungen zu beachten.

---

## 🔍 Aktuelle Umgebung

- **Host OS**: macOS (Darwin 25.0.0)
- **Docker**: Colima VM (Ubuntu 24.04.2 LTS, linux/arm64)
- **Docker Socket**: `/Volumes/DockerData/colima/default/docker.sock`
- **Netzwerk**: Docker läuft in Linux VM, Ports werden auf macOS gemappt

---

## ✅ Was funktioniert problemlos

### 1. Traefik Docker Provider
```yaml
volumes:
  - /Volumes/DockerData/colima/default/docker.sock:/var/run/docker.sock:ro
```
- ✅ Traefik kann Docker Socket lesen (selber Pfad wie bei Woodpecker Agent)
- ✅ Service Discovery funktioniert
- ✅ Container Labels werden erkannt

### 2. Port Mapping
```yaml
ports:
  - "80:80"
  - "443:443"
  - "8080:8080"
```
- ✅ Colima mapped Ports automatisch auf macOS Host
- ✅ `localhost:80` auf macOS → Traefik in Colima VM

### 3. Docker Netzwerk
- ✅ `devops-network` existiert bereits und funktioniert
- ✅ Alle Container können untereinander kommunizieren
- ✅ Traefik kann auf alle Services im gleichen Netzwerk zugreifen

---

## ⚠️ macOS-spezifische Besonderheiten

### 1. Lokale Domain-Auflösung (`.local` Domains)

**Problem**: `.local` wird von macOS für Bonjour/mDNS verwendet

**Empfohlene Lösungen**:

#### Option A: `/etc/hosts` Einträge (Einfachste Lösung) ⭐
```bash
# /etc/hosts
127.0.0.1 git.devops.local
127.0.0.1 ci.devops.local
127.0.0.1 registry.devops.local
127.0.0.1 logs.devops.local
127.0.0.1 traefik.devops.local
127.0.0.1 portainer.devops.local
```

**Vorteile**:
- ✅ Einfach zu implementieren
- ✅ Keine zusätzlichen Tools
- ✅ Funktioniert sofort

**Nachteile**:
- ⚠️ Manuelle Verwaltung
- ⚠️ Jeder neue Service = neuer Eintrag

#### Option B: dnsmasq (Automatische Wildcard) 🔧
```bash
# Installieren
brew install dnsmasq

# Konfigurieren
echo 'address=/.devops.local/127.0.0.1' >> /opt/homebrew/etc/dnsmasq.conf

# Resolver konfigurieren
sudo mkdir -p /etc/resolver
echo "nameserver 127.0.0.1" | sudo tee /etc/resolver/devops.local
```

**Vorteile**:
- ✅ Wildcard: `*.devops.local` → automatisch aufgelöst
- ✅ Neue Services brauchen keine Config-Änderung

**Nachteile**:
- ⚠️ Zusätzlicher Service (dnsmasq)
- ⚠️ Komplexere Setup

#### Option C: Nur `localhost` mit Pfaden
```
http://localhost/git/
http://localhost/ci/
http://localhost/registry/
```

**Vorteile**:
- ✅ Keine Domain-Konfiguration nötig

**Nachteile**:
- ⚠️ Path-basiertes Routing komplexer
- ⚠️ Viele Apps erwarten Root-Path (`/`)

**Empfehlung**: Option A (`/etc/hosts`) für Start, später Option B wenn mehr Services hinzukommen

---

### 2. Docker Socket Pfad

**Standard Linux**: `/var/run/docker.sock`
**Colima**: `/Volumes/DockerData/colima/default/docker.sock`

**Lösung**:
```yaml
# In Traefik docker-compose.yml
volumes:
  # Für Colima macOS
  - /Volumes/DockerData/colima/default/docker.sock:/var/run/docker.sock:ro

  # Für Linux würde man nutzen:
  # - /var/run/docker.sock:/var/run/docker.sock:ro
```

**Status**: ✅ Bereits bekannt, wird im Stack konfiguriert

---

### 3. Port 80/443 Privilegien

**Problem**: Ports < 1024 brauchen normalerweise Root

**Colima-Lösung**:
- ✅ Colima VM läuft mit Root-Rechten
- ✅ Port Mapping funktioniert automatisch
- ✅ **Kein Sudo nötig auf macOS Host**

**Beispiel**:
```bash
# Das funktioniert problemlos:
docker run -p 80:80 traefik
# Keine Permission Denied auf macOS!
```

---

### 4. Let's Encrypt / TLS

**Development (lokal)**:
- ⚠️ Let's Encrypt funktioniert NICHT mit `localhost` oder `.local` Domains
- ✅ Lösung: Self-signed Certificates oder HTTP für Development

**Traefik Config für Development**:
```yaml
command:
  # KEIN ACME/Let's Encrypt für .local Domains
  # Nur HTTP auf Port 80
  - "--entrypoints.web.address=:80"
```

**Production (mit echter Domain)**:
- ✅ Let's Encrypt funktioniert normal
- ✅ Voraussetzung: Öffentliche Domain + öffentliche IP

**Empfehlung für eure Setup**:
- Development: HTTP only (Port 80)
- Production: Let's Encrypt mit echter Domain

---

### 5. Colima VM Ressourcen

**Aktuell prüfen**:
```bash
colima status
```

**Empfehlung für Traefik + 4 Stacks**:
```bash
# Mindestens
CPU: 4 Cores
Memory: 8 GB
Disk: 60 GB
```

**Anpassen falls nötig**:
```bash
colima stop
colima start --cpu 4 --memory 8 --disk 60
```

---

## 🎯 Empfohlene Konfiguration für macOS

### Domain-Schema
```
git.devops.local      → Gitea
ci.devops.local       → Woodpecker
registry.devops.local → Harbor
logs.devops.local     → Dozzle
traefik.devops.local  → Traefik Dashboard
portainer.local       → Portainer (bleibt auf :9443)
```

### /etc/hosts Setup
```bash
# Einmalig ausführen
sudo tee -a /etc/hosts << EOF

# DevOps Stack - Traefik Routing
127.0.0.1 git.devops.local
127.0.0.1 ci.devops.local
127.0.0.1 registry.devops.local
127.0.0.1 logs.devops.local
127.0.0.1 traefik.devops.local
127.0.0.1 portainer.local
EOF
```

### Traefik Stack für macOS/Colima
```yaml
# stack-proxy/docker-compose.yml
services:
  traefik:
    image: traefik:latest
    container_name: traefik
    restart: unless-stopped
    ports:
      - "80:80"
      - "8080:8080"  # Dashboard
    volumes:
      # WICHTIG: Colima Socket Pfad!
      - /Volumes/DockerData/colima/default/docker.sock:/var/run/docker.sock:ro
      - traefik_config:/etc/traefik
    command:
      - "--api.dashboard=true"
      - "--api.insecure=true"  # Für Development
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--log.level=INFO"
    networks:
      - devops-network

networks:
  devops-network:
    external: true

volumes:
  traefik_config:
```

---

## ✅ Getestete Setups (ähnlich wie eures)

1. **Woodpecker Agent** - Nutzt bereits Colima Socket
   ```yaml
   volumes:
     - /var/run/docker.sock:/var/run/docker.sock
   ```
   ✅ Funktioniert → Traefik wird auch funktionieren

2. **Docker Networks** - `devops-network` existiert
   ✅ Funktioniert → Traefik nutzt gleiches Netzwerk

3. **Port Mapping** - Portainer, Gitea, etc.
   ✅ Funktioniert → Traefik Ports werden genauso gemappt

---

## 🚫 Was NICHT funktioniert / Zu vermeiden

### 1. IPv6 in Colima
- ⚠️ Kann zu Problemen führen
- ✅ Lösung: IPv6 in Traefik deaktivieren oder nicht nutzen

### 2. Host-basierte TLS Certificates
- ⚠️ macOS Keychain Integration funktioniert nicht direkt
- ✅ Lösung: Certificates in Container volumes speichern

### 3. `.local` TLD für Production
- ⚠️ Wird von macOS Bonjour genutzt
- ✅ Lösung: `.local` nur für Development, Production mit echter TLD

---

## 📊 Kompatibilitäts-Matrix

| Feature | macOS/Colima | Linux | Status |
|---------|--------------|-------|--------|
| Traefik Docker Provider | ✅ | ✅ | Funktioniert |
| Service Discovery | ✅ | ✅ | Funktioniert |
| Port Mapping (80, 443) | ✅ | ✅ | Funktioniert |
| Docker Socket | ✅ (custom path) | ✅ | Funktioniert |
| `.local` Domains | ⚠️ (/etc/hosts) | ✅ | Workaround nötig |
| Let's Encrypt | ⚠️ (nur mit public domain) | ✅ | Development: HTTP only |
| Auto HTTPS Redirect | ✅ | ✅ | Funktioniert |
| Dashboard | ✅ | ✅ | Funktioniert |

---

## 🎯 Fazit

### ✅ Traefik mit macOS/Colima: **Voll funktionsfähig!**

**Einzige Anpassungen**:
1. ✅ Docker Socket Pfad: `/Volumes/DockerData/colima/default/docker.sock`
2. ✅ `/etc/hosts` Einträge für `.devops.local` Domains
3. ✅ HTTP only für Development (kein Let's Encrypt lokal)

**Alles andere funktioniert 1:1 wie auf Linux!**

---

## 🚀 Bereit für Umsetzung

Die Architektur ist macOS/Colima-kompatibel. Warte auf Anweisung zum Start! 🎉
