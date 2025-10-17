# Portainer Deployment Guide

Alle Stacks werden über Portainer direkt aus Git deployed.

## 🚀 Quick Start

1. Öffne Portainer: https://localhost:9443
2. Login (falls noch nicht eingerichtet: Admin Account erstellen)
3. Wähle "local" Environment
4. Gehe zu **Stacks** → **Add stack**

## 📋 Stack Deployment (4x wiederholen)

### Stack 1: CI Stack (Gitea + Woodpecker)

**Name:** `ci-stack`

**Build method:** ☑️ Repository

**Repository URL:** 
```
https://github.com/serverambulanz/ci-cd-pipeline
```

**Repository reference:** `refs/heads/main`

**Compose path:** 
```
stack-ci/docker-compose.yml
```

**Environment variables:**
```
WOODPECKER_AGENT_SECRET=<generiere mit: openssl rand -hex 32>
GITEA_OAUTH_CLIENT_ID=placeholder
GITEA_OAUTH_CLIENT_SECRET=placeholder
```

*(OAuth Credentials werden nach Gitea Setup ersetzt)*

---

### Stack 2: Registry Stack (Harbor)

**Name:** `registry-stack`

**Build method:** ☑️ Repository

**Repository URL:** 
```
https://github.com/serverambulanz/ci-cd-pipeline
```

**Repository reference:** `refs/heads/main`

**Compose path:** 
```
stack-registry/docker-compose.yml
```

**Environment variables:**
```
HARBOR_CORE_SECRET=<openssl rand -hex 16>
HARBOR_JOBSERVICE_SECRET=<openssl rand -hex 16>
HARBOR_REGISTRY_SECRET=<openssl rand -hex 16>
HARBOR_REGISTRY_PASSWORD=<openssl rand -hex 16>
HARBOR_DB_PASSWORD=<openssl rand -hex 16>
TRIVY_GITHUB_TOKEN=
```

---

### Stack 3: DefectDojo Stack

**Name:** `dojo-stack`

**Build method:** ☑️ Repository

**Repository URL:** 
```
https://github.com/serverambulanz/ci-cd-pipeline
```

**Repository reference:** `refs/heads/main`

**Compose path:** 
```
stack-dojo/docker-compose.yml
```

**Environment variables:**
```
DEFECTDOJO_DB_PASSWORD=<openssl rand -hex 16>
DEFECTDOJO_SECRET_KEY=<openssl rand -hex 32>
DEFECTDOJO_ADMIN_PASSWORD=<openssl rand -hex 16>
```

---

### Stack 4: Utils Stack (Trivy + Dozzle)

**Name:** `utils-stack`

**Build method:** ☑️ Repository

**Repository URL:** 
```
https://github.com/serverambulanz/ci-cd-pipeline
```

**Repository reference:** `refs/heads/main`

**Compose path:** 
```
stack-utils/docker-compose.yml
```

**Environment variables:**
```
TRIVY_GITHUB_TOKEN=
```

*(Optional - kann leer bleiben)*

---

## 🔐 Secrets generieren

Führe lokal aus:
```bash
openssl rand -hex 32  # Für 32-Byte Secrets
openssl rand -hex 16  # Für 16-Byte Secrets
```

Oder nutze das Script:
```bash
cd /Volumes/DockerData/stacks
./scripts/generate-secrets.sh
```

## ✅ Nach dem Deployment

### 1. Gitea Setup
1. Öffne http://localhost:3000
2. Initial Configuration durchführen
3. Admin Account erstellen

### 2. OAuth für Woodpecker
1. Gitea → Settings → Applications
2. Create OAuth2 Application
   - Name: `Woodpecker CI`
   - Redirect: `http://localhost:8000/authorize`
3. Client ID + Secret kopieren

### 3. CI Stack aktualisieren
1. Portainer → Stacks → `ci-stack`
2. **Editor** Tab
3. Scrolle zu **Environment variables**
4. Ersetze:
   ```
   GITEA_OAUTH_CLIENT_ID=<echte_id>
   GITEA_OAUTH_CLIENT_SECRET=<echtes_secret>
   ```
5. **Update the stack** (unten rechts)
6. Warte 20 Sekunden
7. Teste: http://localhost:8000

### 4. Harbor Setup
1. Öffne http://localhost:5000
2. Login: `admin` / `Harbor12345`
3. **SOFORT Passwort ändern!**
4. Erstelle Project: `server-onboarding`
5. Aktiviere "Scan on push"

### 5. DefectDojo Setup (optional)
1. Öffne http://localhost:8082
2. Login: `admin` / `<DEFECTDOJO_ADMIN_PASSWORD>`
3. Product & Engagement erstellen

## 📊 Stack Management in Portainer

### Stack Status prüfen
Portainer → Stacks → Übersicht aller Stacks

### Stack Logs ansehen
Portainer → Stacks → Stack auswählen → Logs Icon

### Stack neu starten
Portainer → Stacks → Stack auswählen → Stop → Start

### Stack aktualisieren (Git Pull)
Portainer → Stacks → Stack auswählen → **Pull and redeploy**
*(Zieht neueste Changes aus GitHub und deployed neu)*

### Container einzeln verwalten
Portainer → Containers → Container auswählen
- Logs ansehen
- Shell öffnen
- Neu starten
- Stoppen

## 🔄 Workflow: Code-Update → Deployment

1. Ändere `docker-compose.yml` lokal
2. Committe zu Git:
   ```bash
   cd /Volumes/DockerData/stacks
   git add stack-ci/docker-compose.yml
   git commit -m "Update CI stack configuration"
   git push origin main
   ```
3. In Portainer: Stack → **Pull and redeploy**
4. ✅ Fertig! Neue Config ist deployed

## 🌐 Service URLs

Nach Deployment verfügbar:

| Service | URL | Default Login |
|---------|-----|---------------|
| Portainer | https://localhost:9443 | (selbst gesetzt) |
| Gitea | http://localhost:3000 | (im Setup erstellen) |
| Woodpecker | http://localhost:8000 | OAuth via Gitea |
| Harbor | http://localhost:5000 | admin / Harbor12345 |
| DefectDojo | http://localhost:8082 | admin / (aus .env) |
| Trivy | http://localhost:8081 | - |
| Dozzle | http://localhost:8888 | - |

## 🐛 Troubleshooting

### Stack startet nicht
1. Portainer → Stacks → Stack auswählen
2. Prüfe **Logs** Tab
3. Prüfe **Environment variables** - alle gesetzt?

### Network Error
```bash
docker network create devops-network
```
Dann Stack neu deployen in Portainer.

### OAuth funktioniert nicht
1. In Gitea: OAuth App prüfen (Redirect URL korrekt?)
2. In Portainer: CI Stack → Environment variables prüfen
3. Stack neu starten

## 💡 Best Practices

✅ **Secrets Management:** Nur in Portainer Environment Variables, NIE in Git  
✅ **Git als Source of Truth:** Alle Änderungen über Git  
✅ **Pull and Redeploy:** Nutze Portainer Git-Integration für Updates  
✅ **Monitoring:** Nutze Dozzle für zentrale Log-Ansicht  
✅ **Backups:** Portainer kann Stack-Configs exportieren  

## 🎯 Nächste Schritte

1. ✅ Alle 4 Stacks in Portainer deployen
2. ✅ Gitea konfigurieren
3. ✅ Woodpecker OAuth einrichten
4. ✅ Harbor konfigurieren
5. ✅ Erste Pipeline erstellen
6. ✅ Harbor Scan-on-Push testen
7. 🔜 DefectDojo Integration
8. 🔜 Security Gates implementieren

---

**Repository:** https://github.com/serverambulanz/ci-cd-pipeline

**Support:** Prüfe Stack READMEs in `stack-*/README.md`
