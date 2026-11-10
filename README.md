# gcp-ai-sandbox

Sandbox de IA sobre Google Cloud definido con Terraform: una *landing zone* (organización, seguridad, redes) más una plataforma de Vertex AI y sandboxes por equipo, entregada en 5 sprints.

> **Importante:** el proyecto no tiene cuenta ni presupuesto de Google Cloud. **Nada se despliega.** Nunca ejecutes `terraform apply` ni `terraform plan` contra un proyecto real. Todo se valida con `terraform fmt`, `terraform validate` y `terraform test` usando `mock_provider`.

## Estructura

```
gcp-ai-sandbox/
├── .github/
│   ├── CODEOWNERS                # equipo @redesAura/plataforma es dueño de modules/, stages/ y .github/
│   └── workflows/
│       └── terraform-ci.yml      # pipeline de CI que corre en cada pull request a main
├── .tflint.hcl                   # configuración de tflint (plugin de reglas de Google 0.39.0)
├── docs/
│   └── adr/                      # registros de decisiones de arquitectura (ADRs)
├── modules/                      # módulos reutilizables de Terraform (sprints posteriores)
├── policies/                     # políticas como código (sprints posteriores)
├── tests/                        # pruebas compartidas (sprints posteriores)
└── stages/                       # cada etapa es una configuración de Terraform independiente
    ├── 0-bootstrap/              # proyecto semilla, bucket de estado, KMS, cuentas de servicio, WIF
    ├── 1-org/                    # carpetas y políticas de organización
    ├── 2-security/               # KMS, Secret Manager, perímetros
    ├── 3-networks/               # Shared VPC hub-and-spoke
    ├── 4-ai-platform/            # Vertex AI y clúster GKE con GPU compartido
    └── 5-sandboxes/              # un sandbox por equipo (teams/)
```

Cada etapa tiene su propio `versions.tf` (Terraform `>= 1.9.0, < 2.0.0`, proveedores `google` y `google-beta` `~> 6.0`) y su `.terraform.lock.hcl` versionado. `0-bootstrap` y `1-org` tienen recursos y pruebas; las demás etapas se implementan en los siguientes sprints.

Los recursos usan el prefijo `redesaura` (por ejemplo `redesaura-seed` y `redesaura-tfstate`). Va en minúsculas porque Google Cloud no acepta mayúsculas en IDs de proyecto ni nombres de bucket.

## Requisitos

- Terraform 1.9 o superior:
  ```bash
  brew tap hashicorp/tap
  brew install hashicorp/tap/terraform
  ```
- No hace falta instalar tflint ni checkov: solo corren en GitHub Actions.

## Comandos

Desde la raíz del repo, revisar el formato de todo el proyecto:

```bash
terraform fmt -check -recursive   # solo revisa
terraform fmt -recursive          # corrige el formato
```

Validar y probar una etapa (ejemplo con bootstrap):

```bash
cd stages/0-bootstrap
terraform init -backend=false     # descarga los proveedores, sin estado remoto
terraform validate                # debe decir: The configuration is valid
terraform test                    # debe decir: 6 passed, 0 failed
```

Si cambias la versión de un proveedor, regenera el lock file para Mac y Linux (el CI corre en Linux):

```bash
terraform providers lock -platform=darwin_arm64 -platform=darwin_amd64 -platform=linux_amd64
```

## Integración continua

El workflow `.github/workflows/terraform-ci.yml` corre en cada pull request a `main`, sin secretos de Google:

1. `terraform fmt -check -recursive`
2. `terraform init -backend=false`, `validate` y `test` en cada etapa de la matriz (hoy: `stages/0-bootstrap` y `stages/1-org`)
3. `tflint` sobre todo el repositorio
4. `checkov` sobre todo el repositorio; los hallazgos que no aplican se justifican en el recurso con `#checkov:skip=<ID>:<razón>`

## Cómo contribuir

`main` está protegida: no se puede hacer push directo y el check `checks (stages/0-bootstrap)` debe pasar antes de integrar. No se requieren aprobaciones.

```bash
git switch main && git pull
git switch -c mi-rama
# ...cambios...
terraform fmt -recursive
git add <archivos> && git commit -m "descripción"
git push -u origin mi-rama
```

Después abre el pull request en GitHub, espera a que el pipeline esté en verde e intégralo.

## Documentación

- Decisiones de arquitectura: [`docs/adr/`](docs/adr/)
- Etapa de bootstrap: [`stages/0-bootstrap/`](stages/0-bootstrap/)
- Etapa de organización: [`stages/1-org/`](stages/1-org/)

## Código de terceros

`1-org` adapta partes de [terraform-example-foundation](https://github.com/terraform-google-modules/terraform-example-foundation) (Google LLC, licencia Apache-2.0), versión `v7.0.0`. `2-security` y `3-networks` contienen código copiado **sin adaptar** del mismo template. Los encabezados de licencia originales se conservan en cada archivo. El origen exacto de cada archivo, la versión y el aviso de atribución están en:

- [`stages/1-org/TEMPLATE_SOURCE.md`](stages/1-org/TEMPLATE_SOURCE.md)
- [`stages/2-security/TEMPLATE_SOURCE.md`](stages/2-security/TEMPLATE_SOURCE.md)
- [`stages/3-networks/TEMPLATE_SOURCE.md`](stages/3-networks/TEMPLATE_SOURCE.md)

El código de `2-security` y `3-networks` todavía no está adaptado ni validado contra este repositorio.
