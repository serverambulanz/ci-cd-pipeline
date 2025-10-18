# DevOps Stack Repositories

Modulare Docker-Compose Stacks mit separater Git-Versionierung.

## Stack Übersicht

| Stack | Services | Domain | Repository |
|-------|----------|--------|------------|
| **Proxy** | Traefik | traefik.devops.local | `stack-proxy/` |
| **CI/CD** | Gitea, Woodpecker | git.devops.local, ci.devops.local | `stack-ci/` |
| **Registry** | Harbor, PostgreSQL, Redis, Trivy | registry.devops.local | `stack-registry/` |
| **Security** | DefectDojo, PostgreSQL, Redis | dojo.devops.local | `stack-dojo/` |
| **Utils** | Trivy Server, Dozzle | trivy.devops.local, logs.devops.local | `stack-utils/` |
| **Dashboard** | Homarr | dashboard.devops.local | `stack-dashboard/` |
| **Project Mgmt** | Taiga, PostgreSQL, RabbitMQ | taiga.devops.local | `stack-taiga/` |
| **IaC** | OpenTofu, Atlantis | atlantis.devops.local | `stack-opentofu/` |

## Deployment

### Option A: Alle Stacks deployen

```bash
cd /Volumes/DockerData/stacks

# CI Stack
cd stack-ci && docker compose up -d && cd ..

# Registry Stack
cd stack-registry && docker compose up -d && cd ..

# DefectDojo Stack
cd stack-dojo && docker compose up -d && cd ..

# Utils Stack
cd stack-utils && docker compose up -d && cd ..
```

### Option B: Einzelner Stack

```bash
cd /Volumes/DockerData/stacks/stack-ci
docker compose up -d
```

## Netzwerk

Alle Stacks nutzen:
- **devops-network** (external, shared)
- **{stack}-internal** (internal, isolated)

Network muss existieren:
```bash
docker network create devops-network
```

## Git-Struktur

Jeder Stack ist ein eigenständiges Git-Repository:

```
/Volumes/DockerData/stacks/
├── stack-ci/              # Git Repo 1
│   ├── .git/
│   ├── docker-compose.yml
│   ├── .env.example
│   └── README.md
│
├── stack-registry/        # Git Repo 2
│   ├── .git/
│   ├── docker-compose.yml
│   ├── .env.example
│   └── README.md
│
├── stack-dojo/            # Git Repo 3
│   ├── .git/
│   ├── docker-compose.yml
│   ├── .env.example
│   └── README.md
│
└── stack-utils/           # Git Repo 4
    ├── .git/
    ├── docker-compose.yml
    ├── .env.example
    └── README.md
```

## Versionierung

Jeder Stack kann unabhängig versioniert werden:

```bash
cd stack-ci
git tag v1.0.1
git log --oneline

cd ../stack-registry
git tag v2.0.0
git log --oneline
```

## Environment Variables

Jeder Stack hat ein `.env.example`:

```bash
cd stack-ci
cp .env.example .env
nano .env
```

**WICHTIG**: `.env` Files NIE ins Git committen!

## Service URLs

Nach Deployment erreichbar (via Traefik):

- **Traefik Dashboard**: http://traefik.devops.local
- **Gitea**: http://git.devops.local
- **Woodpecker CI**: http://ci.devops.local
- **Harbor Registry**: http://registry.devops.local
- **DefectDojo**: http://dojo.devops.local
- **Trivy Server**: http://trivy.devops.local
- **Dozzle Logs**: http://logs.devops.local
- **Homarr Dashboard**: http://dashboard.devops.local
- **Taiga**: http://taiga.devops.local
- **Atlantis**: http://atlantis.devops.local

**DNS-Setup erforderlich** (in `/etc/hosts`):
```bash
127.0.0.1 traefik.devops.local git.devops.local ci.devops.local
127.0.0.1 registry.devops.local logs.devops.local trivy.devops.local
127.0.0.1 dashboard.devops.local taiga.devops.local atlantis.devops.local
```

## Vorteile dieser Struktur

✅ **Unabhängige Versionierung**: Jeder Stack hat eigene Git-History  
✅ **Isolierte Updates**: Stack-Updates ohne andere zu beeinflussen  
✅ **Reproduzierbar**: Exakte Versions-Tags pro Stack  
✅ **Modular**: Stacks können einzeln deployed werden  
✅ **Übersichtlich**: Klare Trennung der Komponenten  

## Next Steps

1. GitHub Repositories erstellen (optional)
2. Remotes hinzufügen: `git remote add origin <url>`
3. Pushen: `git push -u origin main`
4. Tags pushen: `git push --tags`
