# GitLab CI/CD → Woodpecker CI Migration Guide

**Datum:** 2025-10-18
**Original:** `.gitlab-ci.yml` (Server Onboarding Monorepo)
**Ziel:** `.woodpecker.yml` für Woodpecker CI v3.10.0+

---

## 📋 Übersicht

Diese Migration konvertiert eine komplexe GitLab CI/CD Pipeline für ein Rust Monorepo mit:
- **Multi-Package Builds** (shared-management, management-service, bootstrap-agent)
- **Environment-basierter Workflow** (testing → dev → production)
- **Artifact Publishing** zu AWS CodeArtifact + Scaleway S3
- **Terraform Cloud Deployments**
- **Comprehensive Security Checks**

---

## 🔄 Wichtige Unterschiede: GitLab CI vs. Woodpecker CI

### 1. **Workflow Rules**

**GitLab CI:**
```yaml
workflow:
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH =~ /^(testing|dev|master|main)$/'
      changes:
        - packages/**/*.rs
```

**Woodpecker CI:**
```yaml
when:
  - event: [push, pull_request, cron]
    branch: [testing, dev, master, main]
    path:
      include:
        - 'packages/**/*.rs'
      exclude:
        - '**/*.md'
```

**Unterschiede:**
- Woodpecker nutzt `when` statt `workflow.rules`
- `event` ersetzt `$CI_PIPELINE_SOURCE`
- Path filtering ist direkter in Woodpecker

---

### 2. **Job Dependencies**

**GitLab CI:**
```yaml
build-lambda:
  needs:
    - detect-changes
    - test
```

**Woodpecker CI:**
```yaml
steps:
  build-lambda:
    depends_on: [detect-changes, test]
```

**Unterschiede:**
- `needs` → `depends_on`
- Jobs sind in Woodpecker `steps` innerhalb einer Pipeline

---

### 3. **Environment Variables & Secrets**

**GitLab CI:**
```yaml
variables:
  CARGO_HOME: "$CI_PROJECT_DIR/.cargo"

# Secrets via GitLab UI definiert
```

**Woodpecker CI:**
```yaml
steps:
  test:
    environment:
      CARGO_HOME: /root/.cargo
    secrets: [scaleway_access_key, tfc_api_token]
```

**Unterschiede:**
- Environment variables direkt im Step
- Secrets müssen explizit deklariert werden
- Secrets werden in Woodpecker UI/Gitea konfiguriert

---

### 4. **Conditional Execution**

**GitLab CI:**
```yaml
rules:
  - if: '$BOOTSTRAP_AGENT_CHANGED == "true"'
    when: on_success
  - when: never
```

**Woodpecker CI:**
```yaml
when:
  - event: push
    branch: testing
    evaluate: 'BOOTSTRAP_AGENT_CHANGED == "true"'
```

**Unterschiede:**
- `evaluate` für dynamische Bedingungen
- Simpler Syntax in Woodpecker
- Kein `when: never` nötig (implizit)

---

### 5. **Caching**

**GitLab CI:**
```yaml
cache:
  key:
    files:
      - Cargo.lock
  paths:
    - target/
    - .cargo/
  policy: pull-push
```

**Woodpecker CI:**
Caching erfolgt über:
1. **Woodpecker Volumes** (persistente Volumes zwischen Builds)
2. **External Caching Plugin** (S3/MinIO)
3. **Docker Layer Caching** (wenn Docker-in-Docker verwendet)

**Empfehlung:**
```yaml
# In docker-compose.yml des Woodpecker Agents:
volumes:
  - cargo_cache:/root/.cargo
  - rustup_cache:/root/.rustup
```

**Bereits konfiguriert in `/Volumes/DockerData/stacks/stack-ci/docker-compose.yml`:**
```yaml
woodpecker-agent:
  volumes:
    - cargo_cache:/root/.cargo
    - rustup_cache:/root/.rustup
```

---

### 6. **Artifacts**

**GitLab CI:**
```yaml
artifacts:
  paths:
    - packages/bootstrap-agent/bootstrap-agent-amd64
  expire_in: 7 days
```

**Woodpecker CI:**
Artifacts werden über **Workspace** zwischen Steps geteilt:
- Alle Steps im gleichen Pipeline-Run teilen das gleiche Workspace-Verzeichnis
- Kein explizites `artifacts` nötig
- Für persistente Artifacts: Upload zu S3/MinIO im Step selbst

---

### 7. **Templates & Anchors**

**GitLab CI:**
```yaml
.publish_shared_management: &publish_shared_management
  stage: publish
  script: [...]

publish-shared-management-testing:
  <<: *publish_shared_management
  variables:
    PUBLISH_ENV: testing
```

**Woodpecker CI:**
Keine nativen Anchors/Templates. Alternativen:
1. **YAML Anchors** (funktioniert, aber eingeschränkt)
2. **Matrix Builds** für ähnliche Jobs
3. **Externe Templates** (über `when` conditions)

**In dieser Migration:**
- Jeder Publish-Step ist separat definiert
- Code-Duplikation zugunsten der Klarheit

---

## 🔧 Notwendige Konfigurationen

### 1. **Secrets in Woodpecker/Gitea einrichten**

Gehen Sie zu **Woodpecker UI** → **Repository Settings** → **Secrets**:

#### Scaleway S3 Secrets (per Environment)
```
scaleway_access_key_testing=SCWXXXXXXXXXX
scaleway_secret_key_testing=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
scaleway_bucket_testing=server-onboarding-testing

scaleway_access_key_dev=SCWXXXXXXXXXX
scaleway_secret_key_dev=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
scaleway_bucket_dev=server-onboarding-dev

scaleway_access_key_prd=SCWXXXXXXXXXX
scaleway_secret_key_prd=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
scaleway_bucket_prd=server-onboarding-prd

scaleway_endpoint=https://s3.fr-par.scw.cloud
```

#### Terraform Cloud Secrets
```
tfc_api_token=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
tfc_workspace_id_testing=ws-xxxxxxxxxxxxx
tfc_workspace_id_development=ws-xxxxxxxxxxxxx
tfc_workspace_id_production=ws-xxxxxxxxxxxxx
```

#### AWS OIDC (für CodeArtifact)
```
aws_role_arn=arn:aws:iam::XXXXXXXXXXXX:role/GitLabOIDCRole
```

**⚠️ Hinweis zu OIDC:**
GitLab CI unterstützt OIDC Token (`GITLAB_OIDC_TOKEN`) nativ. Woodpecker CI hat aktuell **keine native OIDC-Unterstützung**.

**Alternativen:**
1. **Static AWS Credentials** verwenden (weniger sicher)
2. **OIDC Plugin entwickeln** (Community-Projekt)
3. **CodeArtifact Publish überspringen** und nur Scaleway S3 nutzen (wie in der Migration implementiert)

---

### 2. **Environment-spezifische Secrets**

Woodpecker unterstützt **Secret Scoping**:

```bash
# In Woodpecker UI bei Secret-Erstellung:
Name: scaleway_access_key_testing
Value: SCWXXXXXXXXXX
Events: push
Branches: testing  # ← Nur für testing Branch verfügbar
```

**Vorteil:** Verhindert versehentliche Verwendung von Production-Secrets in Testing.

---

### 3. **Branch Protection**

In **Gitea** → **Repository Settings** → **Branches**:

```
Branch: master / main
- Require pull request reviews: ✅
- Require status checks: ✅
  - woodpecker/test
  - woodpecker/build-shared-management
  - woodpecker/verify-scaleway-permissions
```

---

## 🚀 Migration Checklist

- [ ] **1. .woodpecker.yml ins Repository committen**
  ```bash
  cp /Volumes/DockerData/stacks/.woodpecker.yml /path/to/your/repo/.woodpecker.yml
  git add .woodpecker.yml
  git commit -m "Add Woodpecker CI pipeline"
  git push
  ```

- [ ] **2. Repository in Woodpecker aktivieren**
  - Woodpecker UI → Repositories → "Aktivieren"
  - Webhook wird automatisch in Gitea erstellt

- [ ] **3. Secrets konfigurieren** (siehe oben)

- [ ] **4. Cargo Cache Volumes prüfen**
  ```bash
  docker volume ls | grep cargo
  # Sollte existieren: ci-stack_cargo_cache, ci-stack_rustup_cache
  ```

- [ ] **5. Test-Push auf `testing` Branch**
  ```bash
  git checkout testing
  git commit --allow-empty -m "Test Woodpecker CI"
  git push
  ```

- [ ] **6. Pipeline in Woodpecker UI überwachen**
  - http://ci.devops.local
  - Prüfen: Alle Steps grün?

- [ ] **7. Verify Jobs testen**
  - `verify-scaleway-permissions` sollte durchlaufen
  - `verify-terraform-cloud-permissions` sollte durchlaufen

- [ ] **8. Build & Publish testen**
  - Änderung in `packages/shared-management/` committen
  - Pipeline sollte bauen + publishen

- [ ] **9. Deploy Testing testen**
  - Nach erfolgreichem Publish sollte TFC-Run getriggert werden
  - Terraform Cloud UI prüfen

- [ ] **10. GitLab CI deaktivieren** (wenn alles funktioniert)
  - `.gitlab-ci.yml` umbenennen zu `.gitlab-ci.yml.backup`

---

## 🔍 Fehlende Features vs. GitLab CI

### ❌ Nicht direkt unterstützt:

1. **GitLab Security Templates**
   ```yaml
   # GitLab CI:
   include:
     - template: Security/SAST.gitlab-ci.yml
     - template: Security/Secret-Detection.gitlab-ci.yml
   ```

   **Woodpecker Alternative:**
   - **Trivy** für Security Scanning (bereits in `stack-utils` vorhanden!)
   - **gitleaks** für Secret Detection
   - **cargo-audit** für Dependency Scanning

   **Implementierung:**
   ```yaml
   security-scan:
     image: aquasec/trivy:latest
     commands:
       - trivy fs --severity HIGH,CRITICAL .

   secret-scan:
     image: zricethezav/gitleaks:latest
     commands:
       - gitleaks detect --source . --verbose

   dependency-audit:
     image: rust:1.90.0
     commands:
       - cargo install cargo-audit
       - cargo audit
   ```

2. **Renovate Bot** (Dependency Updates)
   - GitLab: Native Integration
   - Woodpecker: **Manuell via Cron Job**

   **Alternative:** Renovate als separaten Cron-Job in Woodpecker laufen lassen

3. **OIDC Token für AWS**
   - GitLab: `GITLAB_OIDC_TOKEN` (nativ)
   - Woodpecker: **Nicht verfügbar**

   **Alternative:** Static AWS Credentials oder CodeArtifact überspringen

---

## 🎯 Optimierungen

### 1. **Matrix Builds** für Multi-Environment Publishes

Statt 3 separate Publish-Jobs:
```yaml
publish-shared-management:
  image: rust:1.90.0
  matrix:
    PUBLISH_ENV:
      - testing
      - development
      - production
  secrets:
    - source: scaleway_access_key_${PUBLISH_ENV}
      target: scaleway_access_key
  when:
    - event: push
      branch:
        - evaluate: 'PUBLISH_ENV == "testing" && CI_COMMIT_BRANCH == "testing"'
        - evaluate: 'PUBLISH_ENV == "development" && CI_COMMIT_BRANCH == "dev"'
        - evaluate: 'PUBLISH_ENV == "production" && (CI_COMMIT_BRANCH == "master" || CI_COMMIT_BRANCH == "main")'
```

**Vorteil:** Weniger Code-Duplikation
**Nachteil:** Komplexere `when` Conditions

---

### 2. **Parallel Builds**

Woodpecker führt Steps **sequenziell** aus (außer wenn `depends_on` nicht definiert ist).

**Optimierung:**
```yaml
# Diese Steps können parallel laufen:
test:
  # ...

detect-changes:
  # ...

verify-scaleway-permissions:
  # ...

# Weil keiner von denen depends_on hat!
```

Woodpecker erkennt automatisch, welche Steps parallel laufen können.

---

### 3. **Shared Step-Definitionen** (Plugin)

Für wiederkehrende Tasks (wie AWS CLI Installation):

```yaml
# .woodpecker/install-aws-cli.yml
steps:
  install-aws-cli:
    image: alpine:latest
    commands:
      - apk add --no-cache curl unzip
      - curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
      - unzip -q awscliv2.zip && ./aws/install
```

Dann in Haupt-Pipeline:
```yaml
# Noch nicht nativ unterstützt, aber geplant in Woodpecker 4.0
```

---

## 📊 Performance-Vergleich

| Metrik | GitLab CI | Woodpecker CI |
|--------|-----------|---------------|
| **Pipeline Start** | ~10-15s (Warm) | ~5-10s (Lokal) |
| **Cargo Cache** | GitLab Runner Cache | Docker Volumes (schneller!) |
| **Parallel Steps** | Ja (Runner-abhängig) | Ja (Agent-abhängig) |
| **Build Isolation** | Container per Job | Container per Step |
| **Artifact Transfer** | Upload/Download | Shared Workspace (schneller!) |

**Geschätzte Verbesserung:** 15-25% schneller (bei lokaler Woodpecker Installation)

---

## 🔒 Security Considerations

### 1. **Secret Management**

**GitLab CI:**
- Secrets in GitLab UI → Masked in Logs
- Environment-scoped Secrets
- OIDC Integration

**Woodpecker CI:**
- Secrets in Woodpecker UI → Auch masked
- Branch/Event-scoped Secrets ✅
- **Kein OIDC** ❌

**Empfehlung:** Nutzen Sie **Branch Scoping** für Production Secrets!

---

### 2. **Container Isolation**

**GitLab CI:**
- Jeder Job läuft in separatem Container
- Runner kann Jobs von mehreren Repos ausführen

**Woodpecker CI:**
- Jeder Step läuft in separatem Container ✅
- Agent läuft dediziert für **diesen Stack** ✅
- Bessere Isolation in unserem Setup!

---

### 3. **Audit Logs**

**GitLab CI:** Native Audit Logs in Enterprise Edition

**Woodpecker CI:** Logs via:
1. **Dozzle** (bereits deployed in `stack-utils`)
2. **Woodpecker API** (`/api/repos/{owner}/{repo}/builds`)
3. **Git Hooks** für zusätzliche Logging

---

## 🐛 Bekannte Probleme & Lösungen

### Problem 1: "permission denied" bei Cargo Cache

**Symptom:**
```
error: Permission denied (os error 13) for /root/.cargo
```

**Lösung:**
```yaml
# In docker-compose.yml vom Woodpecker Agent:
environment:
  - WOODPECKER_BACKEND_DOCKER_VOLUMES=cargo_cache:/root/.cargo,rustup_cache:/root/.rustup
```

**Status:** ✅ Bereits in `stack-ci/docker-compose.yml` konfiguriert

---

### Problem 2: Build-Zeit erhöht durch fehlenden Cache

**Symptom:**
Erste Builds dauern sehr lange (30+ Minuten für Rust Compilation)

**Lösung:**
1. **Persistent Volumes** nutzen (siehe oben)
2. **Pre-warmed Cache** erstellen:
   ```bash
   docker run --rm -v cargo_cache:/root/.cargo rust:1.90.0 cargo install sccache
   ```

---

### Problem 3: Woodpecker kann Gitea nicht erreichen

**Symptom:**
```
failed to fetch repo: connection refused
```

**Lösung:**
Prüfen Sie `extra_hosts` in `docker-compose.yml`:
```yaml
woodpecker-server:
  extra_hosts:
    - "git.devops.local:host-gateway"
```

**Status:** ✅ Bereits konfiguriert (siehe vorherige Tasks)

---

## 📚 Weiterführende Ressourcen

- **Woodpecker CI Docs:** https://woodpecker-ci.org/docs/intro
- **Woodpecker Plugins:** https://woodpecker-ci.org/plugins
- **GitLab→Woodpecker Migration:** https://woodpecker-ci.org/docs/migrations/gitlab-ci
- **Rust CI Best Practices:** https://matklad.github.io/2021/09/04/fast-rust-builds.html

---

## ✅ Abschluss

Nach erfolgreicher Migration haben Sie:

✅ **Lokale CI/CD** - Keine Abhängigkeit von GitLab SaaS
✅ **Schnellere Builds** - Lokaler Cache, Shared Workspace
✅ **Bessere Integration** - Gitea + Woodpecker + Traefik Stack
✅ **Environment Parity** - testing → dev → production Flow
✅ **Security** - Branch-scoped Secrets, Container Isolation

**Nächste Schritte:**
1. Woodpecker Stack in Portainer deployen (bereits erledigt ✅)
2. Repository aktivieren
3. Secrets konfigurieren
4. Test-Pipeline ausführen
5. Dokumentation für Team erstellen

---

**Migration erstellt:** 2025-10-18
**Woodpecker Version:** v3.10.0
**Status:** ✅ Bereit für Deployment
