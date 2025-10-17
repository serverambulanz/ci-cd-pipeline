# DevOps Stack Repositories

Modulare Docker-Compose Stacks mit separater Git-Versionierung.

## Stack Übersicht

| Stack | Services | Ports | Repository |
|-------|----------|-------|------------|
| **CI** | Gitea, Woodpecker | 3000, 2222, 8000, 9000 | `stack-ci/` |
| **Registry** | Harbor, PostgreSQL, Redis, Trivy | 5000 | `stack-registry/` |
| **DefectDojo** | DefectDojo, PostgreSQL, Redis | 8082 | `stack-dojo/` |
| **Utils** | Trivy Server, Dozzle | 8081, 8888 | `stack-utils/` |

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

Nach Deployment erreichbar:

- Portainer: https://localhost:9443
- Gitea: http://localhost:3000
- Woodpecker: http://localhost:8000
- Harbor: http://localhost:5000
- DefectDojo: http://localhost:8082
- Trivy: http://localhost:8081
- Dozzle: http://localhost:8888

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
