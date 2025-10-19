# Docker Image Version Audit
**Datum:** 2025-10-18
**Status:** Audit aller verwendeten Docker Images im DevOps Stack

## Zusammenfassung

| Service | Aktueller Tag | Tatsächliche Version | Neueste Version | Status | Aktion |
|---------|--------------|---------------------|-----------------|--------|--------|
| **Gitea** | `latest` | v1.24.6 | v1.24.6 | ✅ Aktuell | Keine |
| **Traefik** | `latest` | v3.5.3 | v3.5.3 | ✅ Aktuell | Keine |
| **Homarr** | `ghcr.io/ajnart/homarr:latest` | v0.15.x | v1.42.0 | ⚠️ DEPRECATED | **Migration erforderlich!** |
| **Woodpecker Server** | `v3.10.0` | v3.10.0 | v3.10.0 | ✅ Aktuell | Keine |
| **Woodpecker Agent** | `v3.10.0` | v3.10.0 | v3.10.0 | ✅ Aktuell | Keine |
| **DefectDojo Django** | `latest` | ? | v2.51.0 | ⚠️ Unbekannt | **Prüfung erforderlich** |
| **DefectDojo Nginx** | `latest` | ? | v2.51.0 | ⚠️ Unbekannt | **Prüfung erforderlich** |
| **Trivy** | `latest` | ? | v0.67.2 | ⚠️ Unbekannt | **Prüfung erforderlich** |
| **Dozzle** | `latest` | ? | v8.10.0+ | ⚠️ Unbekannt | **Prüfung erforderlich** |
| **Harbor** | `v2.11.0` | v2.11.0 | v2.14.0 | ⚠️ VERALTET | **Upgrade empfohlen** |

---

## Detaillierte Analyse

### ✅ Aktuell und stabil

#### 1. Gitea (`gitea/gitea:latest`)
- **Aktuell deployed:** v1.24.6 (11. September 2024)
- **Neueste Version:** v1.24.6
- **Status:** `latest` Tag ist korrekt und aktuell
- **Aktion:** Keine Änderung erforderlich

#### 2. Traefik (`traefik:latest`)
- **Aktuell deployed:** v3.5.3 (26. September 2025)
- **Neueste Version:** v3.5.3 "Chabichou"
- **Status:** `latest` Tag ist korrekt und aktuell
- **Aktion:** Keine Änderung erforderlich

#### 3. Woodpecker CI (`woodpeckerci/woodpecker-server:v3.10.0` + `woodpeckerci/woodpecker-agent:v3.10.0`)
- **Aktuell deployed:** v3.10.0 (gepinnt)
- **Neueste Version:** v3.10.0 (28. September 2025)
- **Status:** Explizit gepinnt auf aktuelle stabile Version
- **Hinweis:** Wurde von `latest` (v2.8.3) upgegradet wegen Bug-Fix
- **Aktion:** Keine Änderung erforderlich

---

### ⚠️ Kritisch: Sofortige Aktion erforderlich

#### 4. Homarr Dashboard (`ghcr.io/ajnart/homarr:latest`)
- **Aktuell deployed:** v0.15.x (2. August 2025)
- **Neueste Version:** v1.42.0 (17. Oktober 2025)
- **Repository:** DEPRECATED - `ajnart/homarr` wurde am 13. Oktober 2025 archiviert!
- **Neues Repository:** `homarr-labs/homarr`
- **Neues Image:** `ghcr.io/homarr-labs/homarr:latest` oder `ghcr.io/homarr-labs/homarr:v1.42.0`
- **Status:** ❌ **KRITISCH - Repository archiviert, keine Security-Updates mehr!**
- **Aktion:**
  1. Migration zu `ghcr.io/homarr-labs/homarr:v1.42.0`
  2. docker-compose.yml anpassen
  3. Stack in Portainer neu deployen
  4. Daten migrieren falls nötig

---

### ⚠️ Prüfung erforderlich

#### 5. DefectDojo (`defectdojo/defectdojo-django:latest` + `defectdojo/defectdojo-nginx:latest`)
- **Aktuell deployed:** Unbekannt (nicht laufend)
- **Neueste Version:** v2.51.0 (6. Oktober 2025)
- **Status:** Stack nicht deployed, Version von `latest` unbekannt
- **Aktion:**
  1. Prüfen ob `latest` auf v2.51.0 zeigt
  2. Bei Deployment: Explizite Version verwenden (`defectdojo/defectdojo-django:2.51.0`)

#### 6. Trivy (`aquasec/trivy:latest`)
- **Aktuell deployed:** Unbekannt (nicht laufend)
- **Neueste Version:** v0.67.2 (10. Oktober 2025)
- **Status:** Stack nicht deployed, Version von `latest` unbekannt
- **Aktion:**
  1. Prüfen ob `latest` aktuell ist
  2. Optional: Pin auf `aquasec/trivy:0.67.2`

#### 7. Dozzle (`amir20/dozzle:latest`)
- **Aktuell deployed:** Unbekannt (nicht laufend)
- **Neueste Version:** v8.10.0+ (Januar 2025+)
- **Status:** Stack nicht deployed
- **Aktion:** Bei Deployment prüfen ob `latest` aktuell ist

---

### 🔄 Upgrade empfohlen

#### 8. Harbor Registry (`goharbor/*:v2.11.0`)
- **Aktuell deployed:** v2.11.0 (gepinnt)
- **Neueste Version:** v2.14.0 (September 2025)
- **Status:** 3 Minor Versions veraltet
- **Komponenten:**
  - `goharbor/harbor-db:v2.11.0`
  - `goharbor/redis-photon:v2.11.0`
  - `goharbor/registry-photon:v2.11.0`
  - `goharbor/harbor-registryctl:v2.11.0`
  - `goharbor/harbor-core:v2.11.0`
  - `goharbor/harbor-jobservice:v2.11.0`
  - `goharbor/harbor-portal:v2.11.0`
  - `goharbor/trivy-adapter-photon:v2.11.0`
  - `goharbor/nginx-photon:v2.11.0`
- **Aktion:**
  1. Upgrade auf v2.14.0 planen
  2. Release Notes prüfen: https://github.com/goharbor/harbor/releases
  3. Migration testen
  4. Alle Harbor-Komponenten gleichzeitig auf v2.14.0 upgraden

---

## Empfohlene Aktionen (Priorität)

### 🔴 Hoch (Sofort)
1. **Homarr Migration** - Repository deprecated, Security-Risiko
   - Stack: `stack-dashboard`
   - Neue Image: `ghcr.io/homarr-labs/homarr:v1.42.0`

### 🟡 Mittel (Kurzfristig)
2. **Harbor Upgrade** - 3 Versionen hinterher
   - Stack: `stack-registry`
   - Von: `v2.11.0` → Zu: `v2.14.0`

### 🟢 Niedrig (Bei Gelegenheit)
3. **DefectDojo, Trivy, Dozzle** - Vor Deployment Version pinnen
   - Stacks: `stack-dojo`, `stack-utils`
   - Explizite Versionen statt `latest` verwenden

---

## Best Practices für die Zukunft

### ✅ DO:
- **Explizite Versions-Tags** verwenden (z.B. `v3.10.0` statt `latest`)
- **Release Notes** vor Upgrades lesen
- **Breaking Changes** in Minor/Major Releases prüfen
- **Regelmäßige Audits** (monatlich oder quartalsweise)
- **GitHub Release Pages** abonnieren für wichtige Services

### ❌ DON'T:
- **`latest` in Produktion** vermeiden (außer bei sehr stabilen Projekten wie Traefik)
- **Automatische Updates** ohne Testing
- **Versionen mischen** (z.B. Harbor v2.11 + v2.14 Komponenten)

---

## Nächste Schritte

1. ✅ Woodpecker auf v3.10.0 upgraded (erledigt)
2. ⏳ Homarr Migration auf `homarr-labs/homarr:v1.42.0`
3. ⏳ Harbor Upgrade auf v2.14.0 planen
4. ⏳ DefectDojo/Trivy/Dozzle Version-Pins setzen vor Deployment

---

**Letzte Aktualisierung:** 2025-10-18
**Audit durchgeführt von:** Claude Code
