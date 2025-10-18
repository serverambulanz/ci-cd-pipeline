# Taiga Stack - Agile Project Management

**Taiga** ist eine Open-Source Agile/Scrum Projektmanagement-Plattform mit schönem UI und umfangreichen Features.

## 🎯 Features

- ✅ **Kanban Boards** - Visuelles Task Management
- ✅ **Scrum Support** - Sprints, User Stories, Backlog
- ✅ **Issues Tracking** - Bug Tracking & Feature Requests
- ✅ **Wiki** - Team Documentation
- ✅ **Real-time Updates** - WebSocket-basierte Live-Updates
- ✅ **User Management** - Rollen, Permissions, Teams
- ✅ **Integrations** - GitHub, GitLab, Webhooks
- ✅ **Custom Fields** - Erweiterte Metadaten
- ✅ **Timeline** - Projekt-Timeline Visualisierung

---

## 📦 Stack Komponenten

| Service | Image | Port | Beschreibung |
|---------|-------|------|--------------|
| **taiga-gateway** | nginx:1.27-alpine | 80 | Reverse Proxy (→ Traefik) |
| **taiga-front** | taigaio/taiga-front:latest | - | Angular Frontend |
| **taiga-back** | taigaio/taiga-back:latest | 8000 | Django API Backend |
| **taiga-async** | taigaio/taiga-back:latest | - | Celery Worker (Async Tasks) |
| **taiga-events** | taigaio/taiga-events:latest | 8888 | WebSocket Server |
| **taiga-db** | postgres:16-alpine | 5432 | PostgreSQL Database |
| **taiga-rabbitmq** | rabbitmq:3.13-alpine | 5672 | Message Queue |

---

## 🚀 Deployment

### 1. DNS-Eintrag in `/etc/hosts`

```bash
echo "127.0.0.1 taiga.devops.local" | sudo tee -a /etc/hosts
```

### 2. Environment Variables in Portainer

In Portainer → Stacks → Add Stack → Environment Variables:

```env
TAIGA_DB_PASSWORD=<secure-password>
TAIGA_SECRET_KEY=<generate-with-openssl-rand-hex-32>
TAIGA_RABBITMQ_PASSWORD=<secure-password>
```

### 3. Deploy via Portainer

1. **Portainer UI** öffnen
2. **Stacks** → **Add Stack**
3. **Repository**: `https://github.com/yourorg/stacks`
4. **Compose path**: `stack-taiga/docker-compose.yml`
5. **Environment Variables** konfigurieren
6. **Deploy**

---

## 🔧 Erste Schritte

### 1. Admin Account erstellen

Nach dem ersten Deployment:

```bash
docker exec -it taiga-back python manage.py createsuperuser
```

Oder in Portainer → Containers → taiga-back → Console:

```bash
python manage.py createsuperuser
```

**Credentials:**
- Username: `admin`
- Email: `admin@taiga.devops.local`
- Password: `<your-secure-password>`

### 2. Taiga UI öffnen

```
http://taiga.devops.local
```

### 3. Erste Projekt erstellen

1. Login mit Admin-Account
2. **New Project** klicken
3. Template wählen (Kanban / Scrum)
4. Team-Mitglieder einladen

---

## 🔗 Integrationen

### Gitea Integration (via Webhooks)

Taiga unterstützt Gitea nicht nativ, aber über Webhooks:

1. **Taiga** → Project → Settings → Integrations → **Custom Webhooks**
2. **Gitea** → Repository → Settings → Webhooks → **Add Webhook**
3. URL: `http://taiga.devops.local/api/v1/webhooks/custom`

**Payload Template:**
```json
{
  "action": "{{.Action}}",
  "ref": "{{.Ref}}",
  "commits": {{toJson .Commits}},
  "repository": {
    "name": "{{.Repository.Name}}",
    "url": "{{.Repository.HTMLURL}}"
  }
}
```

### Woodpecker CI Integration

Nutzen Sie Taiga Task IDs in Commit Messages:

```bash
git commit -m "TG-123: Implement feature X"
```

Woodpecker kann dann via API Taiga-Tasks updaten.

---

## 📊 Backup & Restore

### Backup

```bash
# Database Backup
docker exec taiga-db pg_dump -U taiga taiga > taiga_backup_$(date +%Y%m%d).sql

# Media Files Backup
docker run --rm -v taiga_media:/data -v $(pwd):/backup alpine \
  tar czf /backup/taiga_media_$(date +%Y%m%d).tar.gz /data
```

### Restore

```bash
# Database Restore
cat taiga_backup_20251018.sql | docker exec -i taiga-db psql -U taiga taiga

# Media Files Restore
docker run --rm -v taiga_media:/data -v $(pwd):/backup alpine \
  tar xzf /backup/taiga_media_20251018.tar.gz -C /data
```

---

## 🔐 Security

### Secrets

Alle Secrets werden in Portainer verwaltet:
- `TAIGA_DB_PASSWORD` - PostgreSQL Passwort
- `TAIGA_SECRET_KEY` - Django Secret Key (min. 32 Zeichen)
- `TAIGA_RABBITMQ_PASSWORD` - RabbitMQ Passwort

### Secret Key generieren

```bash
openssl rand -hex 32
```

### Public Registration

Standardmäßig aktiviert (`PUBLIC_REGISTER_ENABLED=true`).

**Für Production:** In `docker-compose.yml` deaktivieren:
```yaml
- PUBLIC_REGISTER_ENABLED=false
```

---

## 📈 Monitoring

### Health Checks

Alle kritischen Services haben Health Checks:
- ✅ `taiga-db` - PostgreSQL Ready Check
- ✅ `taiga-rabbitmq` - RabbitMQ Ping

### Logs

Via Dozzle (logs.devops.local) verfügbar:
```
DOZZLE_FILTER=name=taiga
```

---

## 🐛 Troubleshooting

### Problem: "Cannot connect to database"

**Lösung:**
```bash
# Check Database Status
docker exec taiga-db pg_isready -U taiga

# Check Logs
docker logs taiga-db
```

### Problem: WebSocket Connection failed

**Lösung:**
```bash
# Check Events Service
docker logs taiga-events

# Check RabbitMQ
docker exec taiga-rabbitmq rabbitmq-diagnostics ping
```

### Problem: Static Files nicht geladen

**Lösung:**
```bash
# Collect Static Files
docker exec taiga-back python manage.py collectstatic --noinput
```

---

## 🔄 Updates

```bash
# In Portainer:
Stacks → stack-taiga → "Pull and redeploy"

# Oder manuell:
docker compose pull
docker compose up -d
```

---

## 📚 Dokumentation

- **Official Docs:** https://docs.taiga.io/
- **API Docs:** https://docs.taiga.io/api.html
- **Community:** https://community.taiga.io/

---

## 🎨 URL

**Taiga UI:** http://taiga.devops.local

**Default Login:**
- Username: `admin` (nach `createsuperuser`)
- Password: `<your-password>`

---

**Deployment:** Ready for Portainer
**Stack:** Taiga v6.7+
**Database:** PostgreSQL 16
**Updated:** 2025-10-18
