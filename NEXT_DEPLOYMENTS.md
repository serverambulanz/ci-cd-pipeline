# Nächste Stack Deployments

Die folgenden Stacks müssen noch über Portainer deployt werden.

## ✅ Status

- [x] **CI Stack** - Deployed und läuft (Gitea + Woodpecker)
- [ ] **Registry Stack** - Bereit zum Deployment (Harbor)
- [ ] **Utils Stack** - Bereit zum Deployment (Trivy + Dozzle)
- [ ] **DefectDojo Stack** - Optional

---

## 2. Registry Stack (Harbor) - READY TO DEPLOY

### Portainer Deployment

**Stacks → Add Stack → Git Repository**

```yaml
Name: stack-registry
Build method: Git Repository

Repository URL: https://github.com/serverambulanz/ci-cd-pipeline
Repository reference: refs/heads/main
Compose path: stack-registry/docker-compose.yml
```

### Environment Variables

```bash
HARBOR_CORE_SECRET=<generiert mit openssl rand -hex 16>
HARBOR_JOBSERVICE_SECRET=<generiert mit openssl rand -hex 16>
HARBOR_REGISTRY_SECRET=<generiert mit openssl rand -hex 16>
HARBOR_REGISTRY_PASSWORD=<generiert mit openssl rand -hex 16>
HARBOR_DB_PASSWORD=<generiert mit openssl rand -hex 16>
TRIVY_GITHUB_TOKEN=<optional - GitHub Token für höheres Rate Limit>
```

### Secrets generieren

```bash
# Alle Secrets auf einmal generieren
echo "HARBOR_CORE_SECRET=$(openssl rand -hex 16)"
echo "HARBOR_JOBSERVICE_SECRET=$(openssl rand -hex 16)"
echo "HARBOR_REGISTRY_SECRET=$(openssl rand -hex 16)"
echo "HARBOR_REGISTRY_PASSWORD=$(openssl rand -hex 16)"
echo "HARBOR_DB_PASSWORD=$(openssl rand -hex 16)"
```

### Nach Deployment

1. **Harbor UI öffnen**: http://localhost:5000
2. **Login**: admin / Harbor12345
3. **SOFORT Passwort ändern!**
4. **Projekt erstellen**: z.B. "dev", "staging", "production"
5. **Image Push testen**:
   ```bash
   docker tag alpine:latest localhost:5000/dev/alpine:test
   docker login localhost:5000
   docker push localhost:5000/dev/alpine:test
   ```

### Services

- Harbor Portal (Web UI): Port 5000
- PostgreSQL: Internal
- Redis: Internal
- Trivy Adapter: Internal (Vulnerability Scanner)
- 9 Services total

---

## 3. Utils Stack (Trivy + Dozzle) - READY TO DEPLOY

### Portainer Deployment

**Stacks → Add Stack → Git Repository**

```yaml
Name: stack-utils
Build method: Git Repository

Repository URL: https://github.com/serverambulanz/ci-cd-pipeline
Repository reference: refs/heads/main
Compose path: stack-utils/docker-compose.yml
```

### Environment Variables (Optional)

```bash
TRIVY_GITHUB_TOKEN=<optional - GitHub Token für höheres Rate Limit>
```

Wenn kein GitHub Token verwendet wird, kann das Feld leer bleiben.

### Nach Deployment

1. **Dozzle Logs**: http://localhost:8888
   - Real-time Log Viewer für alle Container
   - Kein Login erforderlich

2. **Trivy Server**: http://localhost:8081
   - API für Vulnerability Scanning
   - Health Check: `curl http://localhost:8081/healthz`

### Trivy CLI Usage

```bash
# Trivy Server konfigurieren
export TRIVY_SERVER=http://localhost:8081

# Image scannen
trivy image alpine:latest

# Filesystem scannen
trivy fs /path/to/code

# Secrets scannen
trivy fs --scanners secret .
```

---

## 4. DefectDojo Stack (Optional)

Später deployen, wenn Security Testing benötigt wird.

---

## Deployment Reihenfolge (Empfohlen)

1. ✅ **CI Stack** - Bereits deployed
2. **Utils Stack** - Zuerst deployen (für Trivy + Logs)
3. **Registry Stack** - Danach deployen (nutzt Trivy für Scanning)

Der Utils Stack sollte zuerst deployed werden, da:
- Dozzle sofort Logs aller Container zeigt
- Trivy Server für Harbor's Vulnerability Scanning bereitsteht

---

## Verification nach allen Deployments

```bash
# Alle Container prüfen
export DOCKER_HOST="unix:///Volumes/DockerData/colima/default/docker.sock"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Alle Netzwerke prüfen
docker network ls

# Alle Volumes prüfen
docker volume ls
```

### Erwartete Container (wenn alle deployed)

```
portainer              - Portainer Management
gitea                  - CI Stack
woodpecker-server      - CI Stack
woodpecker-agent       - CI Stack
trivy-server           - Utils Stack
dozzle                 - Utils Stack
harbor-db              - Registry Stack
harbor-redis           - Registry Stack
harbor-core            - Registry Stack
harbor-portal          - Registry Stack
harbor-registry        - Registry Stack
harbor-registryctl     - Registry Stack
harbor-jobservice      - Registry Stack
nginx                  - Registry Stack
trivy-adapter          - Registry Stack
```

---

## URLs Übersicht (nach allen Deployments)

- **Portainer**: https://localhost:9443
- **Gitea**: http://localhost:3000
- **Woodpecker CI**: http://localhost:7050
- **Harbor Registry**: http://localhost:5000
- **Dozzle Logs**: http://localhost:8888
- **Trivy Server**: http://localhost:8081

---

## Nächster Schritt

**Deploy Utils Stack zuerst**, dann Registry Stack!
