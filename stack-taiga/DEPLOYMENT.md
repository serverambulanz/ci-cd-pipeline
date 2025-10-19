# Taiga Stack Deployment Guide

## Overview
Taiga is an open-source agile project management platform with support for Scrum and Kanban workflows.

**Official Repository**: https://github.com/taigaio/taiga-docker

## Architecture

The Taiga stack consists of 8 services:

1. **taiga-db** - PostgreSQL 12.3 database
2. **taiga-back** - Django REST API backend
3. **taiga-async** - Celery worker for async tasks
4. **taiga-async-rabbitmq** - Message queue for async tasks
5. **taiga-front** - Angular SPA frontend
6. **taiga-events** - WebSocket server for real-time updates
7. **taiga-events-rabbitmq** - Message queue for events
8. **taiga-protected** - Secure file download service
9. **taiga-gateway** - Nginx reverse proxy (exposed via Traefik)

## Prerequisites

- Portainer with access to devops-network
- Traefik running on devops-network
- Entry in `/etc/hosts`: `127.0.0.1 taiga.devops.local`

## Environment Variables

Before deploying, configure these environment variables in Portainer:

### Required Variables

```bash
# PostgreSQL Database
POSTGRES_USER=taiga
POSTGRES_PASSWORD=<generate_secure_password>

# Taiga Secret Key (generate with: python -c 'import secrets; print(secrets.token_hex(32))')
SECRET_KEY=<generate_64_char_hex_string>

# Taiga URL Configuration
TAIGA_SCHEME=http
TAIGA_DOMAIN=taiga.devops.local
WEBSOCKETS_SCHEME=ws
SUBPATH=""

# RabbitMQ Configuration
RABBITMQ_USER=taiga
RABBITMQ_PASS=<generate_secure_password>
RABBITMQ_VHOST=taiga
RABBITMQ_ERLANG_COOKIE=<generate_secure_cookie>

# Email Configuration (optional - console backend for testing)
EMAIL_BACKEND=console
EMAIL_DEFAULT_FROM=taiga@taiga.devops.local
EMAIL_USE_TLS=False
EMAIL_USE_SSL=False
EMAIL_HOST=smtp.example.com
EMAIL_PORT=587
EMAIL_HOST_USER=
EMAIL_HOST_PASSWORD=

# Attachments
ATTACHMENTS_MAX_AGE=360

# Telemetry
ENABLE_TELEMETRY=False
```

### Generate Secure Values

```bash
# Generate SECRET_KEY (64 char hex string)
python3 -c 'import secrets; print(secrets.token_hex(32))'

# Generate passwords
openssl rand -base64 32

# Generate Erlang cookie
openssl rand -base64 24
```

## Deployment Steps

### 1. In Portainer

1. Navigate to **Stacks** → **Add stack**
2. Name: `taiga`
3. Build method: **Git Repository**
4. Repository URL: `https://github.com/serverambulanz/ci-cd-pipeline`
5. Repository reference: `refs/heads/main`
6. Compose path: `stack-taiga/docker-compose.yml`
7. Add environment variables (see above)
8. Deploy the stack

### 2. Verify Deployment

Check that all 8 containers are running:

```bash
docker ps --filter "name=taiga-"
```

Expected output:
```
taiga-db
taiga-back
taiga-async
taiga-async-rabbitmq
taiga-front
taiga-events
taiga-events-rabbitmq
taiga-protected
taiga-gateway
```

### 3. Check Logs

```bash
# Check backend initialization
docker logs taiga-back

# Check database migration
docker logs taiga-db

# Check events server
docker logs taiga-events
```

### 4. Create Admin User

After all services are running, create an admin account:

```bash
docker exec -it taiga-back python manage.py createsuperuser
```

Follow the prompts to set:
- Username
- Email
- Password

## Access Taiga

- **Frontend**: http://taiga.devops.local
- **API**: http://taiga.devops.local/api/
- **Admin**: http://taiga.devops.local/admin/

Login with the superuser credentials you created.

## Post-Deployment Configuration

### 1. Configure Project Settings

1. Login to Taiga
2. Create your first project
3. Configure project settings (Scrum/Kanban, sprints, etc.)

### 2. Email Configuration (Production)

For production use, update these environment variables:

```bash
EMAIL_BACKEND=smtp
EMAIL_HOST=your-smtp-server.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=your-smtp-username
EMAIL_HOST_PASSWORD=your-smtp-password
EMAIL_DEFAULT_FROM=taiga@yourdomain.com
```

Then restart the stack in Portainer.

### 3. HTTPS Setup (Production)

To enable HTTPS via Traefik:

1. Update `.env`:
   ```bash
   TAIGA_SCHEME=https
   WEBSOCKETS_SCHEME=wss
   ```

2. Update Traefik labels in `docker-compose.yml`:
   ```yaml
   labels:
     - "traefik.enable=true"
     - "traefik.http.routers.taiga.rule=Host(`taiga.devops.local`)"
     - "traefik.http.routers.taiga.entrypoints=websecure"
     - "traefik.http.routers.taiga.tls=true"
   ```

3. Redeploy the stack

## Troubleshooting

### Services won't start

Check dependencies:
```bash
# Database should be healthy first
docker inspect taiga-db --format='{{.State.Health.Status}}'

# RabbitMQ should start before backend
docker logs taiga-async-rabbitmq
docker logs taiga-events-rabbitmq
```

### Can't access via Traefik

1. Verify taiga-gateway is on devops-network:
   ```bash
   docker network inspect devops-network | grep taiga-gateway
   ```

2. Check Traefik dashboard for route configuration

3. Verify extra_hosts are working:
   ```bash
   docker exec taiga-back ping -c 1 git.devops.local
   ```

### Database migration errors

If you need to start fresh:

```bash
# Stop and remove stack in Portainer
# Then remove volumes
docker volume rm taiga_taiga-db-data
docker volume rm taiga_taiga-async-rabbitmq-data
docker volume rm taiga_taiga-events-rabbitmq-data

# Redeploy stack
```

### WebSocket connection fails

1. Check events service is running:
   ```bash
   docker logs taiga-events
   ```

2. Verify nginx configuration routes `/events` correctly:
   ```bash
   docker exec taiga-gateway cat /etc/nginx/conf.d/default.conf | grep -A 5 "location /events"
   ```

3. Check WEBSOCKETS_SCHEME matches TAIGA_SCHEME (http→ws, https→wss)

## Integration with Other Services

### Gitea Integration

Taiga supports webhook integration with Git repositories:

1. In Taiga project settings, enable "Gogs" integration (compatible with Gitea)
2. Copy the webhook URL
3. In Gitea repository → Settings → Webhooks → Add webhook
4. Paste Taiga webhook URL
5. Select events to trigger (Push, Pull Request, etc.)

### Woodpecker CI Integration

Link Taiga issues to Woodpecker builds:

1. Use issue tags in commit messages: `#123` references Taiga issue 123
2. Taiga will automatically link commits and show build status if webhooks are configured

## Backup

### Database Backup

```bash
docker exec taiga-db pg_dump -U taiga taiga > taiga-backup-$(date +%Y%m%d).sql
```

### Media Files Backup

```bash
docker run --rm \
  -v taiga_taiga-media-data:/source \
  -v $(pwd):/backup \
  alpine tar czf /backup/taiga-media-$(date +%Y%m%d).tar.gz -C /source .
```

### Restore Database

```bash
cat taiga-backup-20250110.sql | docker exec -i taiga-db psql -U taiga taiga
```

## Resources

- Official Documentation: https://docs.taiga.io/
- GitHub Repository: https://github.com/taigaio/taiga-docker
- Community Forum: https://community.taiga.io/
- API Documentation: https://docs.taiga.io/api.html
