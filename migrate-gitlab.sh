#!/bin/bash
# Gitea → GitLab CE Migration Script
# Migriert 7 Repositories und konfiguriert GitLab + Woodpecker

set -e

# =============================================
# Configuration
# =============================================
GITLAB_DOMAIN="git.devops.local"
CI_DOMAIN="ci.devops.local"
BACKUP_DIR="/Volumes/DockerData/backups"
STACKS_DIR="/Volumes/DockerData/stacks"

# Repositories zum Migrieren
REPOS=(
    "panel-forge-backend"
    "panel-forge-plugins"
    "panel-forge-auth"
    "panel-forge-gui"
    "panel-forge-agents"
    "panel-forge-license"
    "panel-forge-backend.wiki"
)

# Colors für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================
# Helper Functions
# =============================================
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# =============================================
# Prerequisites Check
# =============================================
check_prerequisites() {
    log_info "Prüfe Voraussetzungen..."

    # Prüfe ob Docker läuft
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker läuft nicht!"
        exit 1
    fi

    # Prüfe ob devops-network existiert
    if ! docker network ls | grep -q "devops-network"; then
        log_warning "devops-network existiert nicht - wird erstellt..."
        docker network create devops-network
    fi

    # Prüfe ob GitLab Stack Verzeichnis existiert
    if [ ! -d "$STACKS_DIR/stack-gitlab" ]; then
        log_error "GitLab Stack Verzeichnis nicht gefunden!"
        exit 1
    fi

    log_success "Voraussetzungen erfüllt"
}

# =============================================
# Step 1: Gitea stoppen und Final Backup
# =============================================
backup_gitea() {
    log_info "Step 1: Finale Gitea Sicherung..."

    # Gitea stoppen
    log_info "Stoppe Gitea..."
    docker compose -f $STACKS_DIR/stack-ci/docker-compose.yml down gitea

    # Finale Sicherung
    BACKUP_NAME="gitea-final-backup-$(date +%Y%m%d-%H%M%S)"
    log_info "Erstelle finale Sicherung: $BACKUP_NAME"

    docker cp gitea:/data/gitea "$BACKUP_DIR/$BACKUP_NAME"
    docker cp gitea:/data/git/repositories" "$BACKUP_DIR/repositories-$BACKUP_NAME"

    log_success "Finale Sicherung abgeschlossen: $BACKUP_NAME"
}

# =============================================
# Step 2: GitLab CE deployen
# =============================================
deploy_gitlab() {
    log_info "Step 2: Deploy GitLab CE..."

    cd "$STACKS_DIR/stack-gitlab"

    # Environment erstellen falls nicht vorhanden
    if [ ! -f ".env" ]; then
        log_info "Erstelle .env Datei..."
        cp .env.example .env

        # Generiere Passwörter
        POSTGRES_PASSWORD=$(openssl rand -base64 32)
        GITLAB_ROOT_PASSWORD=$(openssl rand -base64 32)

        sed -i '' "s/dein-postgres-passwort-hier/$POSTGRES_PASSWORD/" .env
        sed -i '' "s/dein-gitlab-admin-passwort-hier/$GITLAB_ROOT_PASSWORD/" .env

        log_info "Passwörter generiert:"
        log_info "  PostgreSQL: $POSTGRES_PASSWORD"
        log_info "  GitLab Root: $GITLAB_ROOT_PASSWORD"
    fi

    # GitLab deployen
    log_info "Starte GitLab CE..."
    docker compose up -d

    log_info "Warte auf GitLab Initialisierung (ca. 5-10 Minuten)..."

    # Warte bis GitLab bereit ist
    for i in {1..30}; do
        if curl -s http://localhost/-/health >/dev/null 2>&1; then
            log_success "GitLab ist bereit!"
            break
        fi

        if [ $i -eq 30 ]; then
            log_error "GitLab startet nicht innerhalb von 5 Minuten!"
            log_info "Prüfe Logs mit: docker logs -f gitlab"
            exit 1
        fi

        echo -n "."
        sleep 10
    done
    echo

    # Zeige Admin Password
    if [ -f ".env" ]; then
        grep GITLAB_ROOT_PASSWORD .env
    fi
}

# =============================================
# Step 3: Woodpecker neu starten mit GitLab
# =============================================
restart_woodpecker() {
    log_info "Step 3: Starte Woodpecker mit GitLab Integration..."

    cd "$STACKS_DIR/stack-ci"

    # Environment für Woodpecker aktualisieren
    if [ ! -f ".env" ]; then
        cp .env.example .env

        # Generiere Woodpecker Secret
        WOODPECKER_AGENT_SECRET=$(openssl rand -hex 32)
        sed -i '' "s/dein-woodpecker-agent-secret-hier/$WOODPECKER_AGENT_SECRET/" .env

        log_info "Woodpecker Agent Secret: $WOODPECKER_AGENT_SECRET"
    fi

    # Woodpecker neu starten
    log_info "Starte Woodpecker Server + Agent..."
    docker compose up -d woodpecker-server woodpecker-agent

    # Warte bis Woodpecker bereit ist
    sleep 30

    if curl -s http://localhost:8000 >/dev/null 2>&1; then
        log_success "Woodpecker ist erreichbar unter: http://$CI_DOMAIN"
    else
        log_warning "Woodpecker startet möglicherweise noch - prüfe logs: docker logs woodpecker-server"
    fi
}

# =============================================
# Step 4: Repositories migrieren
# =============================================
migrate_repositories() {
    log_info "Step 4: Migriere ${#REPOS[@]} Repositories..."

    cd /tmp

    for repo in "${REPOS[@]}"; do
        log_info "Migriere Repository: $repo"

        # Repository klonen
        if [ -d "$repo.git" ]; then
            rm -rf "$repo.git"
        fi

        git clone --mirror ssh://git@$GITLAB_DOMAIN:2222/server-ambulanz/$repo.git

        if [ -d "$repo.git" ]; then
            cd "$repo.git"

            # GitLab Remote hinzufügen
            git remote add gitlab ssh://git@$GITLAB_DOMAIN:2222/server-ambulanz/$repo.git

            # Push zu GitLab
            git push --mirror gitlab

            log_success "✅ $repo migriert"
            cd ..
        else
            log_error "❌ Konnte $repo nicht klonen"
        fi
    done
}

# =============================================
# Step 5: GitLab OAuth für Woodpecker einrichten
# =============================================
setup_oauth() {
    log_info "Step 5: OAuth Setup für Woodpecker..."

    echo ""
    log_info "📋 OAuth Setup Steps:"
    echo ""
    echo "1. Öffne GitLab: http://$GITLAB_DOMAIN"
    echo "2. Login als 'root' mit Passwort aus .env"
    echo "3. Gehe zu: Admin Area → Applications → New Application"
    echo "4. Konfiguration:"
    echo "   - Name: Woodpecker CI"
    echo "   - Redirect URI: http://$CI_DOMAIN/authorize"
    echo "   - Scopes: read_api, read_user, read_repository, api, write_repository"
    echo ""
    echo "5. Kopiere Application ID und Secret"
    echo "6. Aktualisiere $STACKS_DIR/stack-ci/.env:"
    echo "   GITLAB_OAUTH_CLIENT_ID=<deine-app-id>"
    echo "   GITLAB_OAUTH_CLIENT_SECRET=<dein-app-secret>"
    echo ""
    echo "7. Starte Woodpecker neu:"
    echo "   cd $STACKS_DIR/stack-ci && docker compose restart woodpecker-server"
    echo ""

    read -p "Drücke ENTER wenn OAuth eingerichtet ist..."
}

# =============================================
# Step 6: GitLab Cloud Integration
# =============================================
setup_cloud_integration() {
    log_info "Step 6: GitLab Cloud Integration..."

    echo ""
    log_info "📋 GitLab Cloud Integration:"
    echo ""
    echo "Für jedes Repository:"
    echo "1. GitLab Project → Settings → Repository → Mirroring"
    echo "2. Repository URL: https://gitlab.com/your-org/your-project.git"
    echo "3. Direction: Push"
    echo "4. Authentication: Deploy Token erstellen"
    echo ""
    echo "Oder manuell mit Git remotes:"
    echo ""
    echo "cd /path/to/repo"
    echo "git remote add gitlab-cloud https://gitlab.com/your-org/your-project.git"
    echo "git push gitlab-cloud master"
    echo ""
}

# =============================================
# Verification
# =============================================
verify_migration() {
    log_info "Step 7: Verification..."

    echo ""
    log_info "🔍 Checking Services:"

    # GitLab Check
    if curl -s http://$GITLAB_DOMAIN/-/health >/dev/null 2>&1; then
        log_success "✅ GitLab CE: http://$GITLAB_DOMAIN"
    else
        log_error "❌ GitLab CE nicht erreichbar"
    fi

    # Woodpecker Check
    if curl -s http://$CI_DOMAIN >/dev/null 2>&1; then
        log_success "✅ Woodpecker CI: http://$CI_DOMAIN"
    else
        log_warning "⚠️  Woodpecker CI noch nicht erreichbar"
    fi

    # Repository Check
    log_info "📊 Repository Count in GitLab:"
    # Hier könnte man die GitLab API nutzen um Repositories zu zählen

    echo ""
    log_success "Migration abgeschlossen!"
    echo ""
    echo "📋 Nächste Schritte:"
    echo "1. OAuth für Woodpecker einrichten (siehe Step 5)"
    echo "2. CI/CD Pipelines testen"
    echo "3. GitLab Cloud Integration einrichten (siehe Step 6)"
    echo ""
    echo "🔗 URLs:"
    echo "- GitLab: http://$GITLAB_DOMAIN"
    echo "- Woodpecker: http://$CI_DOMAIN"
    echo ""
}

# =============================================
# Main Execution
# =============================================
main() {
    echo ""
    log_info "🚀 Gitea → GitLab CE Migration"
    log_info "Migriere ${#REPOS[@]} Repositories zu GitLab CE"
    echo ""

    # Safety check
    read -p "Dies wird Gitea ersetzen. Fortfahren? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Migration abgebrochen."
        exit 0
    fi

    # Execute migration steps
    check_prerequisites
    backup_gitea
    deploy_gitlab
    restart_woodpecker
    migrate_repositories
    setup_oauth
    setup_cloud_integration
    verify_migration

    log_success "🎉 Migration erfolgreich abgeschlossen!"
}

# Execute main function
main "$@"