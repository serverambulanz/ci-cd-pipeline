# OpenTofu Stack - Infrastructure as Code

**OpenTofu** ist ein Open-Source Fork von Terraform nach der Lizenz-Änderung. 100% kompatibel mit Terraform, aber vollständig Open Source (MPL 2.0).

## 🎯 Features

- ✅ **Terraform-kompatibel** - Alle Terraform Modules funktionieren
- ✅ **Open Source** - MPL 2.0 Lizenz, Community-driven
- ✅ **State Management** - Lokales & Remote State Support
- ✅ **Provider Ecosystem** - Gleiche Provider wie Terraform
- ✅ **Atlantis Integration** - Web UI für PR-based Workflows
- ✅ **Multi-Cloud** - AWS, Azure, GCP, Scaleway, etc.

---

## 📦 Stack Komponenten

| Service | Image | Port | Beschreibung |
|---------|-------|------|--------------|
| **opentofu** | opentofu-cli:1.10.6 | - | OpenTofu CLI Container |
| **atlantis** | runatlantis/atlantis:v0.31.0 | 4141 | Web UI für IaC Workflows |

---

## 🚀 Deployment

### 1. DNS-Eintrag in `/etc/hosts` (für Atlantis)

```bash
echo "127.0.0.1 atlantis.devops.local" | sudo tee -a /etc/hosts
```

### 2. Build OpenTofu Image

```bash
cd /Volumes/DockerData/stacks/stack-opentofu
docker build -t opentofu-cli:1.10.6 .
```

### 3. Deploy via Portainer

1. **Portainer UI** öffnen
2. **Stacks** → **Add Stack**
3. **Repository**: `https://github.com/yourorg/stacks`
4. **Compose path**: `stack-opentofu/docker-compose.yml`
5. **Environment Variables** konfigurieren
6. **Deploy**

---

## 🔧 Verwendung

### Methode 1: Direkter CLI-Zugriff

```bash
# In Container Shell wechseln
docker exec -it opentofu sh

# OpenTofu Befehle ausführen
cd /workspace
tofu init
tofu plan
tofu apply
```

### Methode 2: Von Host ausführen

```bash
# Alias erstellen (in ~/.zshrc oder ~/.bashrc)
alias tofu='docker exec -it opentofu tofu'

# Dann direkt nutzen:
tofu version
tofu init
tofu plan
```

### Methode 3: Via Atlantis Web UI

1. **Gitea** → Repository → Settings → Webhooks → Add Webhook
2. **URL:** `http://atlantis.devops.local/events`
3. **Secret:** `<ATLANTIS_WEBHOOK_SECRET>`
4. **Events:** Push, Pull Request

**Workflow:**
1. Create Pull Request in Gitea
2. Atlantis postet Comment mit `tofu plan`
3. Review Plan
4. Comment `atlantis apply` für Deployment

---

## 📁 Workspace Structure

```
/workspace/
├── environments/
│   ├── testing/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   ├── development/
│   └── production/
└── modules/
    ├── lambda/
    ├── vpc/
    └── s3/
```

**Zugriff auf Workspace:**

```bash
docker exec -it opentofu sh
cd /workspace
```

Oder vom Host:

```bash
docker cp my-terraform-files/. opentofu:/workspace/
```

---

## 🔐 State Management

### Local State (für Testing)

```hcl
# backend.tf
terraform {
  backend "local" {
    path = "/workspace/terraform.tfstate"
  }
}
```

### S3 Backend (Scaleway)

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "terraform-state"
    key            = "testing/terraform.tfstate"
    region         = "fr-par"
    endpoint       = "s3.fr-par.scw.cloud"
    skip_credentials_validation = true
    skip_region_validation      = true
  }
}
```

**Credentials:** Via Environment Variables (bereits in docker-compose.yml)

### Terraform Cloud Backend

```hcl
# backend.tf
terraform {
  cloud {
    organization = "server-ambulanz"
    workspaces {
      name = "management-service-testing"
    }
  }
}
```

**Token:** Über `TFC_TOKEN` Environment Variable

---

## 🔗 Provider Configuration

### AWS Provider

```hcl
provider "aws" {
  region = var.aws_region
  # Credentials via AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
}
```

### Scaleway Provider

```hcl
provider "scaleway" {
  zone   = "fr-par-1"
  region = "fr-par"
  # Credentials via SCW_ACCESS_KEY, SCW_SECRET_KEY
}
```

### Gitea Provider (Custom)

Es gibt Community-Provider für Gitea:

```hcl
terraform {
  required_providers {
    gitea = {
      source = "Lerentis/gitea"
      version = "~> 0.19"
    }
  }
}

provider "gitea" {
  base_url = "http://git.devops.local"
  token    = var.gitea_token
}
```

---

## 🎨 Atlantis Web UI

**URL:** http://atlantis.devops.local

### Setup in Gitea

1. **Gitea** → **User Settings** → **Applications** → **Generate New Token**
   - Name: `Atlantis`
   - Scopes: `repo`, `write:repo_hook`

2. Token in Portainer Environment Variables setzen:
   ```
   ATLANTIS_GITEA_TOKEN=<your-token>
   ```

3. **Repository** → **Settings** → **Webhooks** → **Add Webhook**
   - URL: `http://atlantis.devops.local/events`
   - Content Type: `application/json`
   - Secret: `<ATLANTIS_WEBHOOK_SECRET>`
   - Events: `Push`, `Pull Request`

### Atlantis Commands (via PR Comments)

| Command | Beschreibung |
|---------|--------------|
| `atlantis help` | Zeigt alle Commands |
| `atlantis plan` | Führt `tofu plan` aus |
| `atlantis apply` | Führt `tofu apply` aus |
| `atlantis unlock` | Entsperrt locked State |
| `atlantis version` | Zeigt Atlantis Version |

---

## 📊 Integration mit Woodpecker CI

### Woodpecker Pipeline für IaC

```yaml
# .woodpecker.yml
steps:
  tofu-plan:
    image: opentofu-cli:1.10.6
    commands:
      - cd /workspace/environments/testing
      - tofu init
      - tofu plan -out=tfplan
    secrets: [aws_access_key_id, aws_secret_access_key]
    when:
      - event: pull_request

  tofu-apply:
    image: opentofu-cli:1.10.6
    commands:
      - cd /workspace/environments/testing
      - tofu init
      - tofu apply -auto-approve tfplan
    secrets: [aws_access_key_id, aws_secret_access_key]
    when:
      - event: push
        branch: testing
```

---

## 🔒 Security Best Practices

### 1. Secrets Management

**Niemals in Code committen:**
- ❌ `terraform.tfvars`
- ❌ `.env` files
- ❌ Hardcoded Credentials

**Nutzen Sie stattdessen:**
- ✅ Portainer Environment Variables
- ✅ Terraform Cloud Variables
- ✅ AWS Secrets Manager / Parameter Store
- ✅ Scaleway Secret Manager

### 2. State File Security

**S3 Backend mit Encryption:**

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state"
    key            = "prod/terraform.tfstate"
    encrypt        = true
    dynamodb_table = "terraform-locks"  # For state locking
  }
}
```

### 3. Provider Version Pinning

```hcl
terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

---

## 🐛 Troubleshooting

### Problem: "OpenTofu command not found"

**Lösung:**
```bash
# Re-build Image
cd /Volumes/DockerData/stacks/stack-opentofu
docker build -t opentofu-cli:1.10.6 .
```

### Problem: "Backend initialization failed"

**Lösung:**
```bash
# Check Credentials
docker exec opentofu env | grep AWS
docker exec opentofu env | grep SCW

# Re-initialize
docker exec -it opentofu tofu init -reconfigure
```

### Problem: Atlantis Webhook nicht empfangen

**Lösung:**
```bash
# Check Atlantis Logs
docker logs atlantis

# Test Webhook manually
curl -X POST http://atlantis.devops.local/events \
  -H "Content-Type: application/json" \
  -d '{"test": true}'
```

---

## 🔄 Updates

### OpenTofu Update

1. Update `OPENTOFU_VERSION` in `Dockerfile`
2. Re-build Image:
   ```bash
   docker build -t opentofu-cli:<new-version> .
   ```
3. Update `docker-compose.yml`:
   ```yaml
   image: opentofu-cli:<new-version>
   ```

### Atlantis Update

```bash
# In Portainer:
Stacks → stack-opentofu → "Pull and redeploy"
```

---

## 📚 Dokumentation

- **OpenTofu Docs:** https://opentofu.org/docs/
- **Atlantis Docs:** https://www.runatlantis.io/docs/
- **Terraform Providers:** https://registry.terraform.io/browse/providers

---

## 🎯 Example: AWS Lambda Deployment

```hcl
# main.tf
resource "aws_lambda_function" "management_service" {
  function_name = "management-service-${var.environment}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "bootstrap"
  runtime       = "provided.al2"

  filename         = "lambda.zip"
  source_code_hash = filebase64sha256("lambda.zip")

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }
}
```

**Deploy:**

```bash
docker exec -it opentofu sh
cd /workspace/environments/testing
tofu init
tofu plan
tofu apply
```

---

## 📈 URLs

**Atlantis UI:** http://atlantis.devops.local

**CLI Access:**
```bash
docker exec -it opentofu sh
```

---

**Deployment:** Ready for Portainer
**OpenTofu Version:** 1.10.6
**Atlantis Version:** 0.31.0
**Updated:** 2025-10-18
