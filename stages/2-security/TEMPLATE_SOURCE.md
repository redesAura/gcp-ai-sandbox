# Origen del código: terraform-example-foundation (2-security)

Copia **sin adaptar** del template oficial. No se cambió lógica, nombres, variables, versiones ni estructura.

| Dato | Valor |
|---|---|
| Repositorio | https://github.com/terraform-google-modules/terraform-example-foundation |
| Release (tag) | `v7.0.0` |
| Commit | `4930e0a36cdfbaebb897d247055da159d93b0a07` |
| Licencia | Apache-2.0 |

## Rutas copiadas (template → este repo)

### KMS y Secret Manager (de `2-environments`, solo el ambiente `production`)

| Template | Destino |
|---|---|
| `2-environments/README.md` | `stages/2-security/README.md` |
| `2-environments/.gitignore` | `stages/2-security/.gitignore` |
| `2-environments/terraform.example.tfvars` | `stages/2-security/terraform.example.tfvars` |
| `2-environments/envs/production/` (completo) | `stages/2-security/envs/production/` |
| `2-environments/modules/env_baseline/` (completo) | `stages/2-security/modules/env_baseline/` |

`envs/production/main.tf` referencia `../../modules/env_baseline`, que se copió en la misma posición relativa. No se copiaron `envs/development` ni `envs/nonproduction`.

En v7.0.0, `env_baseline` crea la carpeta del ambiente y los proyectos `prj-p-kms` y `prj-p-secrets` (`kms.tf`, `secrets.tf`, vía `terraform-google-modules/project-factory`), además de un Assured Workload opcional. **No crea key rings, llaves (`google_kms_crypto_key`) ni secretos**: eso hay que agregarlo al adaptar.

### VPC Service Controls (de `1-org`)

En v7.0.0, VPC-SC vive en la etapa `1-org` (no en las de redes).

| Template | Destino |
|---|---|
| `1-org/envs/shared/service_control.tf` | `stages/2-security/vpc-sc-from-template/envs/shared/service_control.tf` |
| `1-org/modules/service_control/` (completo) | `stages/2-security/vpc-sc-from-template/modules/service_control/` |

`service_control.tf` referencia `../../modules/service_control`, que se conservó en la misma posición relativa. Ese archivo depende de variables, locals y data sources definidos en otros archivos de `1-org/envs/shared` (por ejemplo `variables.tf`, `remote.tf`, `projects.tf`), que no se copiaron aquí; esos están en `stages/1-org/envs/shared/` (rama `copy-1-org`). Por eso esta carpeta no es una configuración válida por sí sola hasta adaptarla.

| Template | Destino |
|---|---|
| `LICENSE` | `stages/2-security/LICENSE-terraform-example-foundation.txt` |

## Enlaces simbólicos del template

`envs/production/terraform.tfvars` es un enlace simbólico del template (`-> ../../terraform.tfvars`). Apunta a un archivo que el usuario debe crear a partir de `terraform.example.tfvars`, así que por ahora está roto. Se conservó tal cual; mientras no exista el destino, `terraform fmt -check -recursive` falla al leerlo.

Como `.gitignore` de la raíz ignora `*.tfvars`, `terraform.example.tfvars` y este enlace se agregaron con `git add -f`.

## Archivos propios conservados

`stages/2-security/versions.tf` y `stages/2-security/.terraform.lock.hcl` son de este repo y no se tocaron. No hubo colisiones de nombres, así que no se creó ningún `*.from-template`.

## Licencia y atribución (Apache-2.0)

```
terraform-example-foundation
Copyright Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use these files except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

- El texto completo de la licencia del template está en [`LICENSE-terraform-example-foundation.txt`](LICENSE-terraform-example-foundation.txt) (copia exacta de `LICENSE` del template).
- El template no incluye archivo `NOTICE`.
- Los encabezados de licencia de cada archivo se conservan exactamente como en el original.
- Cuando estos archivos se adapten, cada archivo modificado debe llevar un aviso visible de que fue modificado (sección 4(b) de la licencia), por ejemplo una línea `# Modificado por redesAura (gcp-ai-sandbox)` debajo del encabezado original.
