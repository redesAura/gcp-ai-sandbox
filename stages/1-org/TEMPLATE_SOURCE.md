# Origen del código: terraform-example-foundation (1-org)

Copia **sin adaptar** del template oficial. No se cambió lógica, nombres, variables, versiones ni estructura.

| Dato | Valor |
|---|---|
| Repositorio | https://github.com/terraform-google-modules/terraform-example-foundation |
| Release (tag) | `v7.0.0` |
| Commit | `4930e0a36cdfbaebb897d247055da159d93b0a07` |
| Licencia | Apache-2.0 |

## Rutas copiadas (template → este repo)

| Template | Destino |
|---|---|
| `1-org/README.md` | `stages/1-org/README.md` |
| `1-org/.gitignore` | `stages/1-org/.gitignore` |
| `1-org/envs/shared/` (completo) | `stages/1-org/envs/shared/` |
| `1-org/modules/cai-monitoring/` | `stages/1-org/modules/cai-monitoring/` |
| `1-org/modules/centralized-logging/` | `stages/1-org/modules/centralized-logging/` |
| `1-org/modules/network/` | `stages/1-org/modules/network/` |
| `1-org/modules/service_control/` | `stages/1-org/modules/service_control/` |
| `LICENSE` | `stages/1-org/LICENSE-terraform-example-foundation.txt` |

Los cuatro módulos locales se copian porque `envs/shared` los referencia con rutas relativas (`../../modules/...`).

Contenido relevante: carpetas (`folders.tf`), políticas de organización (`org_policy.tf`), logging centralizado (`log_sinks.tf` + `modules/centralized-logging`), SCC (`scc_notification.tf`), monitoreo CAI, tags, contactos esenciales y VPC Service Controls (`service_control.tf` + `modules/service_control`).

## Archivos propios conservados

`stages/1-org/versions.tf` y `stages/1-org/.terraform.lock.hcl` son de este repo y no se tocaron. No hubo colisiones de nombres, así que no se creó ningún `*.from-template`. Los `versions.tf` del template están en `envs/shared/` y `modules/*/` y se copiaron tal cual.

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
