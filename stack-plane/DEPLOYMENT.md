# Plane Stack - Deployment Guide

## Overview
Plane is a modern, open-source project management platform that provides issue tracking, sprint planning, and roadmap visualization with a beautiful UI.

**Access URL**: http://project.devops.local

## Architecture
- **plane-db**: PostgreSQL 15 database
- **plane-redis**: Redis 7.2 for caching and queues
- **plane-minio**: MinIO S3-compatible object storage
- **plane-web**: Next.js frontend
- **plane-api**: Django REST API backend
- **plane-worker**: Celery background task worker
- **plane-beat**: Celery scheduler
- **plane-proxy**: Nginx gateway with Traefik integration

## Pre-Deployment: Generate Secrets

Run these commands to generate secure values:

```bash
# PostgreSQL Password
echo "POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d '/+=' | cut -c1-32)"

# Django Secret Key
echo "SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_hex(50))')"

# MinIO Root Password
echo "MINIO_ROOT_PASSWORD=$(openssl rand -base64 32 | tr -d '/+=' | cut -c1-32)"
```

## Deployment in Portainer

### 1. Create Stack
1. Navigate to **Stacks** → **Add Stack**
2. Name: `stack-plane`
3. Build method: **Git Repository**
4. Repository URL: Your Git repository URL
5. Repository reference: `refs/heads/main`
6. Compose path: `stack-plane/docker-compose.yml`

### 2. Configure Environment Variables
Add these environment variables in Portainer:

**Required:**
- `POSTGRES_USER` = `plane`
- `POSTGRES_PASSWORD` = *[generated password]*
- `SECRET_KEY` = *[generated Django secret key]*
- `MINIO_ROOT_USER` = `plane-minio`
- `MINIO_ROOT_PASSWORD` = *[generated MinIO password]*

**Optional (Email Configuration):**
- `EMAIL_HOST` = *[your SMTP server]*
- `EMAIL_PORT` = `587`
- `EMAIL_HOST_USER` = *[SMTP username]*
- `EMAIL_HOST_PASSWORD` = *[SMTP password]*
- `EMAIL_USE_TLS` = `1`
- `DEFAULT_FROM_EMAIL` = `noreply@project.devops.local`

**Security:**
- `ENABLE_SIGNUP` = `1` (allow user registration) or `0` (admin-only)

### 3. Deploy
1. Click **Deploy the stack**
2. Wait for all containers to start (may take 2-3 minutes)
3. Check container logs for any errors

## Post-Deployment: Initial Setup

### 1. Create MinIO Bucket
The `plane` bucket must be created in MinIO:

```bash
# Access MinIO container
docker exec -it plane-minio sh

# Create bucket using MinIO client
mc alias set local http://localhost:9000 plane-minio <MINIO_ROOT_PASSWORD>
mc mb local/plane
mc anonymous set download local/plane
exit
```

### 2. Run Database Migrations
```bash
# Run Django migrations
docker exec -it plane-api python manage.py migrate

# Create superuser account (interactive)
docker exec -it plane-api python manage.py createsuperuser
```

### 3. Access Plane
1. Open browser: http://project.devops.local
2. Sign up for a new account OR
3. Log in with the superuser account created above

## Verification

### Check Service Health
```bash
# Check all containers are running
docker ps | grep plane

# Check API health
curl http://project.devops.local/api/health/

# Check Traefik routing
curl -H "Host: project.devops.local" http://localhost/
```

### Access MinIO Console (Optional)
MinIO management console is available at:
- Internal: http://plane-minio:9001
- Use credentials: `plane-minio` / `<MINIO_ROOT_PASSWORD>`

## Troubleshooting

### Container won't start
```bash
# Check logs
docker logs plane-api
docker logs plane-web
docker logs plane-proxy

# Check database connection
docker exec plane-db pg_isready -U plane
```

### Web UI shows blank page
- Verify `NEXT_PUBLIC_API_BASE_URL` matches your domain
- Check browser console for CORS errors
- Verify plane-api is accessible: `curl http://plane-api:8000/api/`

### File uploads fail
- Verify MinIO bucket was created
- Check plane-minio logs: `docker logs plane-minio`
- Verify `AWS_S3_BUCKET_NAME` is set to `plane`

### Background tasks not running
- Check worker logs: `docker logs plane-worker`
- Check beat logs: `docker logs plane-beat`
- Verify Redis is accessible: `docker exec plane-redis redis-cli ping`

## Maintenance

### Backup Database
```bash
docker exec plane-db pg_dump -U plane plane > plane_backup_$(date +%Y%m%d).sql
```

### Backup MinIO Data
```bash
docker run --rm \
  --volumes-from plane-minio \
  -v $(pwd):/backup \
  alpine tar czf /backup/plane_minio_$(date +%Y%m%d).tar.gz /data
```

### Update Plane
1. Pull latest images: `docker-compose pull`
2. Restart stack in Portainer
3. Run migrations: `docker exec plane-api python manage.py migrate`

## Security Recommendations

1. **Disable signup** after initial setup: Set `ENABLE_SIGNUP=0`
2. **Use strong passwords** for all services
3. **Enable email** for password resets and notifications
4. **Regular backups** of database and MinIO storage
5. **Monitor logs** for suspicious activity

## Resources

- Official Documentation: https://docs.plane.so/
- GitHub Repository: https://github.com/makeplane/plane
- Community Discord: https://discord.com/invite/A92xrEGCge
