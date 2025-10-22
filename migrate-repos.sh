#!/bin/bash
# Repository Migration Script: Gitea → GitLab CE
# Migriert alle 7 Repositories mit voller Historie

set -e

# =============================================
# Configuration
# =============================================
GITLAB_DOMAIN="git.devops.local"
BACKUP_REPOS_DIR="/Volumes/DockerData/backups/repositories-backup-20251022-053251"
TEMP_DIR="/tmp/gitlab-migration"

# Repository List aus Backup
REPOS=(
    "panel-forge-backend"
    "panel-forge-plugins"
    "panel-forge-auth"
    "panel-forge-gui"
    "panel-forge-agents"
    "panel-forge-license"
    "panel-forge-backend.wiki"
)

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# =============================================
# Setup
# =============================================
setup() {
    log_info "Bereite Migration vor..."

    # Temp directory erstellen
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"

    # Prüfe ob GitLab erreichbar ist
    if ! curl -s http://$GITLAB_DOMAIN/-/health >/dev/null 2>&1; then
        log_error "GitLab nicht erreichbar unter http://$GITLAB_DOMAIN"
        exit 1
    fi

    log_success "Setup abgeschlossen"
}

# =============================================
# GitLab Project Setup
# =============================================
create_gitlab_projects() {
    log_info "Erstelle GitLab Projects..."

    # Admin Token holen (manuell erstellen nötig)
    echo ""
    log_warning "⚠️  GitLab Admin Token benötigt!"
    echo ""
    echo "1. Öffne http://$GITLAB_DOMAIN"
    echo "2. Login als root"
    echo "3. Gehe zu: User Settings → Access Tokens"
    echo "4. Token erstellen mit Scopes: api, write_repository"
    echo "5. Token hier eintragen:"
    echo ""
    read -p "GitLab Admin Token: " GITLAB_TOKEN

    if [ -z "$GITLAB_TOKEN" ]; then
        log_error "Kein Token angegeben!"
        exit 1
    fi

    # GitLab Group erstellen (falls nicht vorhanden)
    log_info "Erstelle GitLab Group: server-ambulanz"

    GROUP_RESPONSE=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
        --header "Content-Type: application/json" \
        --data '{
            "name": "server-ambulanz",
            "path": "server-ambulanz",
            "visibility": "private"
        }' \
        "http://$GITLAB_DOMAIN/api/v4/groups" || echo "group_exists")

    # Projects erstellen
    for repo in "${REPOS[@]}"; do
        log_info "Erstelle Project: $repo"

        # GitLab Project über API erstellen
        PROJECT_RESPONSE=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
            --header "Content-Type: application/json" \
            --data "{
                \"name\": \"$repo\",
                \"path\": \"$repo\",
                \"namespace_id\": $(echo $GROUP_RESPONSE | grep -o '"id":[0-9]*' | cut -d':' -f2 | head -1),
                \"visibility\": \"private\",
                \"initialize_with_readme\": false
            }" \
            "http://$GITLAB_DOMAIN/api/v4/projects/" || echo "project_exists")

        if echo "$PROJECT_RESPONSE" | grep -q '"id"'; then
            log_success "✅ Project $repo erstellt"
        else
            log_warning "⚠️  Project $repo existiert bereits"
        fi
    done
}

# =============================================
# Repository Migration
# =============================================
migrate_repositories() {
    log_info "Migriere Repositories..."

    for repo in "${REPOS[@]}"; do
        log_info "Migriere: $repo"

        # Backup Repository klonen
        REPO_BACKUP="$BACKUP_REPOS_DIR/server-ambulanz/$repo.git"

        if [ ! -d "$REPO_BACKUP" ]; then
            log_error "❌ Backup nicht gefunden: $REPO_BACKUP"
            continue
        fi

        # Repository klonen
        if [ -d "$repo" ]; then
            rm -rf "$repo"
        fi

        git clone "$REPO_BACKUP" "$repo"

        if [ ! -d "$repo" ]; then
            log_error "❌ Konnte $repo nicht klonen"
            continue
        fi

        cd "$repo"

        # GitLab Remote hinzufügen
        git remote add gitlab ssh://git@$GITLAB_DOMAIN:2222/server-ambulanz/$repo.git

        # Teste SSH Verbindung
        if ! ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no git@$GITLAB_DOMAIN -p 2222 2>/dev/null; then
            log_warning "⚠️  SSH Verbindung zu GitLab nicht möglich - versuche HTTP"

            # Fallback zu HTTP mit Token
            git remote set-url gitlab http://root:$GITLAB_TOKEN@$GITLAB_DOMAIN/server-ambulanz/$repo.git
        fi

        # Push alle Branches und Tags
        log_info "  Push Branches..."
        git push --all gitlab 2>/dev/null || log_warning "  ⚠️  Branch push fehlgeschlagen"

        log_info "  Push Tags..."
        git push --tags gitlab 2>/dev/null || log_warning "  ⚠️  Tag push fehlgeschlagen"

        cd ..
        log_success "✅ $repo migriert"
    done
}

# =============================================
# Verification
# =============================================
verify_migration() {
    log_info "Verifiziere Migration..."

    echo ""
    log_info "📊 Migration Results:"
    echo ""

    for repo in "${REPOS[@]}"; do
        # Prüfe ob Projekt in GitLab existiert
        PROJECT_CHECK=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
            "http://$GITLAB_DOMAIN/api/v4/projects/server-ambulanz%2F$repo" || echo "not_found")

        if echo "$PROJECT_CHECK" | grep -q '"id"'; then
            PROJECT_ID=$(echo "$PROJECT_CHECK" | grep -o '"id":[0-9]*' | cut -d':' -f2 | head -1)
            COMMITS=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
                "http://$GITLAB_DOMAIN/api/v4/projects/$PROJECT_ID/repository/commits?per_page=1" | \
                grep -o '"total_count":[0-9]*' | cut -d':' -f2 || echo "0")

            log_success "✅ $repo: $COMMITS commits"
        else
            log_error "❌ $repo: nicht gefunden"
        fi
    done

    echo ""
    log_success "Migration abgeschlossen!"
    echo ""
    log_info "🔗 Project URLs:"
    echo ""
    for repo in "${REPOS[@]}"; do
        echo "- $repo: http://$GITLAB_DOMAIN/server-ambulanz/$repo"
    done
    echo ""
}

# =============================================
# SSH Key Setup Helper
# =============================================
setup_ssh_keys() {
    log_info "SSH Key Setup für GitLab..."
    echo ""
    echo "1. SSH Key erstellen (falls nicht vorhanden):"
    echo "   ssh-keygen -t ed25519 -C \"git@gitlab.local\" -f ~/.ssh/gitlab_ed25519"
    echo ""
    echo "2. Public Key zu GitLab hinzufügen:"
    echo "   cat ~/.ssh/gitlab_ed25519.pub"
    echo "   → In GitLab: User Settings → SSH Keys → Add Key"
    echo ""
    echo "3. SSH Config ergänzen (~/.ssh/config):"
    echo "   Host git.devops.local"
    echo "       HostName git.devops.local"
    echo "       Port 2222"
    echo "       User git"
    echo "       IdentityFile ~/.ssh/gitlab_ed25519"
    echo "       StrictHostKeyChecking no"
    echo ""
    echo "4. Teste Verbindung:"
    echo "   ssh -T git@git.devops.local"
    echo ""

    read -p "SSH Keys konfiguriert? (Enter zum fortsetzen)"
}

# =============================================
# Main Execution
# =============================================
main() {
    echo ""
    log_info "🔄 Repository Migration: Gitea → GitLab CE"
    log_info "Migriere ${#REPOS[@]} Repositories"
    echo ""

    # SSH Key Setup
    setup_ssh_keys

    # Setup
    setup

    # GitLab Projects erstellen
    create_gitlab_projects

    # Repositories migrieren
    migrate_repositories

    # Verification
    verify_migration

    # Cleanup
    rm -rf "$TEMP_DIR"

    log_success "🎉 Repository Migration abgeschlossen!"
    echo ""
    log_info "📋 Nächste Schritte:"
    echo "1. Woodpecker OAuth in GitLab einrichten"
    echo "2. CI/CD Pipelines testen"
    echo "3. GitLab Cloud Integration einrichten"
    echo ""
}

# Execute
main "$@"