# GitLab CE Stack

**Replace Gitea with GitLab CE** for enhanced CI/CD integration with GitLab Cloud.

## 🎯 Purpose

- **Replace Gitea** with GitLab Community Edition
- **Keep same domain**: `git.devops.local`
- **Enable Woodpecker OAuth** with GitLab
- **Integrate with GitLab Cloud** for production workflows

## 🚀 Quick Start

```bash
# 1. Environment konfigurieren
cd /Volumes/DockerData/stacks/stack-gitlab
cp .env.example .env
# .env anpassen (mindestens POSTGRES_PASSWORD!)

# 2. GitLab deployen
docker compose up -d

# 3. Warte auf Initialisierung (5-10 Minuten)
docker logs -f gitlab

# 4. Woodpecker OAuth einrichten
# → siehe Woodpecker Migration unten
```

## 📋 Services

| Service | Container | Purpose | URL |
|---------|-----------|---------|-----|
| **GitLab CE** | gitlab | Git Server & CI/CD | http://git.devops.local |
| **PostgreSQL** | gitlab-postgres | Database | Internal |
| **Redis** | gitlab-redis | Cache/Queue | Internal |

## 🔧 Initial Setup

### 1. GitLab Admin Account

Nach ca. 5-10 Minuten ist GitLab erreichbar:

1. **Open**: http://git.devops.local
2. **Login**: `root`
3. **Password**: Aus den Logs oder `.env` Variable

```bash
# Password aus Logs lesen
docker exec gitlab grep 'Password:' /etc/gitlab/initial_root_password
```

### 2. Woodpecker OAuth Setup

In GitLab OAuth App erstellen:

1. **Admin Area** → **Applications** → **New Application**
2. **Name**: `Woodpecker CI`
3. **Redirect URI**: `http://ci.devops.local/authorize`
4. **Scopes**: `read_api`, `read_user`, `read_repository`, `api`, `write_repository`
5. **Copy**: Application ID und Secret

## 🔄 Woodpecker Migration

### Aktuelle Gitea Konfiguration:
```yaml
WOODPECKER_GITEA=true
WOODPECKER_GITEA_URL=http://git.devops.local
WOODPECKER_GITEA_CLIENT=${GITEA_OAUTH_CLIENT_ID}
WOODPECKER_GITEA_SECRET=${GITEA_OAUTH_CLIENT_SECRET}
```

### Neue GitLab Konfiguration:
```yaml
WOODPECKER_GITLAB=true
WOODPECKER_GITLAB_URL=http://git.devops.local
WOODPECKER_GITLAB_CLIENT=${GITLAB_OAUTH_CLIENT_ID}
WOODPECKER_GITLAB_SECRET=${GITLAB_OAUTH_CLIENT_SECRET}
```

## 📦 Repository Migration

### Option 1: GitLab Import Tool
1. GitLab Project → **New Project**
2. **Import project** → **GitLab**
3. **Repository URL**: `http://git.devops.local/server-ambulanz/repo.git`
4. **Authentication**: Gitea Token erstellen

### Option 2: Manual Push
```bash
# Alle Repositories migrieren
cd /tmp
for repo in panel-forge-backend panel-forge-plugins panel-forge-auth panel-forge-gui panel-forge-agents panel-forge-license panel-forge-backend.wiki; do
  git clone --mirror git@git.devops.local:server-ambulanz/$repo.git
  cd $repo.git
  git remote add gitlab git@git.devops.local:server-ambulanz/$repo.git
  git push --mirror gitlab
  cd ..
done
```

## 🔗 GitLab Cloud Integration

### 1. Remote hinzufügen
```bash
cd /path/to/repo
git remote add gitlab git@gitlab.com:your-org/your-project.git
```

### 2. Branch Strategy
```bash
# Local development (testing/dev)
git push origin testing

# Push to Cloud (master)
git push gitlab master
```

### 3. Mirroring Setup
GitLab Project → **Settings** → **Repository** → **Mirroring**
- **Repository URL**: `https://gitlab.com/your-org/your-project.git`
- **Direction**: Push
- **Authentication**: Deploy Token

## 📊 Resource Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **GitLab CE** | 4GB RAM, 2 CPU | 8GB RAM, 4 CPU |
| **PostgreSQL** | 512MB RAM, 1 CPU | 1GB RAM, 2 CPU |
| **Redis** | 256MB RAM, 0.5 CPU | 512MB RAM, 1 CPU |
| **Total** | **5GB RAM, 3.5 CPU** | **9.5GB RAM, 7 CPU** |

## 🔍 Health Checks

```bash
# GitLab Status
docker exec gitlab gitlab-rails status

# Database Status
docker exec gitlab-postgres pg_isready -U gitlab

# Redis Status
docker exec gitlab-redis redis-cli ping
```

## 🚨 Important Notes

- **Domain remains same**: `git.devops.local`
- **SSH Port unchanged**: `2222`
- **Woodpecker compatible**: OAuth migration only
- **Backup created**: Gitea data saved in `/Volumes/DockerData/backups/`

## 🆚 Gitea vs GitLab CE

| Feature | Gitea | GitLab CE |
|---------|-------|-----------|
| **Resource Usage** | Low (1GB RAM) | High (8GB RAM) |
| **CI/CD** | Basic Actions | Advanced GitLab CI |
| **Issue Tracking** | Basic | Advanced |
| **Security** | Basic | Advanced |
| **GitLab Cloud Sync** | Manual | Native |
| **Setup Complexity** | Simple | Complex |

## 📝 Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_PASSWORD` | Required | PostgreSQL password |
| `GITLAB_ROOT_PASSWORD` | Auto-generated | Admin password |
| `GITLAB_BACKUP_SCHEDULE` | `0 2 * * *` | Daily 2 AM backup |
| `GITLAB_BACKUP_RETENTION` | `7` | Days to keep |

## 🔄 Backup & Recovery

```bash
# Backup erstellen
docker exec gitlab gitlab-backup create

# Backup wiederherstellen
docker exec gitlab gitlab-backup restore BACKUP=timestamp
```

---

**Next**: Deploy GitLab CE, then migrate Woodpecker OAuth configuration.