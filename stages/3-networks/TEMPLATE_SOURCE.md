# Origen del código: terraform-example-foundation (3-networks)

Base copiada del template oficial v7.0.0. Los archivos indicados abajo se adaptaron para el plan IP del reto; el resto de los archivos copiados conserva la estructura del template.

| Dato | Valor |
|---|---|
| Repositorio | https://github.com/terraform-google-modules/terraform-example-foundation |
| Release (tag) | `v7.0.0` |
| Commit | `4930e0a36cdfbaebb897d247055da159d93b0a07` |
| Licencia | Apache-2.0 |

Fuente: `3-networks-hub-and-spoke` (no `3-networks-svpc`).

## Rutas copiadas (template → este repo)

| Template | Destino |
|---|---|
| `3-networks-hub-and-spoke/README.md` | `stages/3-networks/README.md` |
| `3-networks-hub-and-spoke/.gitignore` | `stages/3-networks/.gitignore` |
| `3-networks-hub-and-spoke/common.auto.example.tfvars` | `stages/3-networks/common.auto.example.tfvars` |
| `3-networks-hub-and-spoke/shared.auto.example.tfvars` | `stages/3-networks/shared.auto.example.tfvars` |
| `3-networks-hub-and-spoke/envs/shared/` (completo) | `stages/3-networks/envs/shared/` |
| `3-networks-hub-and-spoke/envs/production/` (completo) | `stages/3-networks/envs/production/` |
| `3-networks-hub-and-spoke/modules/` (los 9 módulos) | `stages/3-networks/modules/` |
| `LICENSE` | `stages/3-networks/LICENSE-terraform-example-foundation.txt` |

No se copiaron `envs/development` ni `envs/nonproduction`.

### Dónde está cada cosa

- **Hub (Shared VPC hub, NCC, NAT):** `envs/shared/net-hubs.tf` (usa `modules/nat`).
- **DNS hub y Private Service Connect:** `envs/shared/net-hubs.tf` y `modules/base_env/main.tf` (`dns_config`, `private_service_connect_ip`, `private_service_cidr`). Los recursos concretos (`google_dns_*`, la dirección PSC, el acceso a servicios privados) se crean en módulos remotos de CFT que se llaman desde ahí, no en módulos locales.
- **Firewall jerárquico:** `envs/shared/hierarchical_firewall.tf` + `modules/hierarchical_firewall_policy/`.
- **Spoke production:** `envs/production/main.tf` → `modules/base_env/`.
- **HA VPN:** `envs/shared/vpn.tf.example` + `modules/vpn-ha/`. En el template viene **desactivado** como `.tf.example`; se activa renombrándolo a `.tf`. También usa `envs/shared/routers.tf.example` + `modules/routers/`.
- **Interconnect (opcional, también `.example`):** `interconnect.tf.example`, `partner_interconnect.tf.example`, `cross_interconnect.tf.example`, `cross_partner_interconnect.tf.example` y sus `*.auto.tfvars.example`, que usan `modules/dedicated_interconnect`, `partner_interconnect`, `cross_dedicated_interconnect` y `cross_partner_interconnect`. Se copiaron porque son parte de `envs/shared`.

## Enlaces simbólicos del template

El template trae estos enlaces simbólicos. Apuntan a archivos que el usuario debe crear a partir de los `*.example.tfvars`, así que por ahora están rotos. Se conservaron tal cual:

- `envs/shared/common.auto.tfvars -> ../../common.auto.tfvars`
- `envs/shared/shared.auto.tfvars -> ../../shared.auto.tfvars`
- `envs/production/common.auto.tfvars -> ../../common.auto.tfvars`

Mientras no existan los destinos, `terraform fmt -check -recursive` falla al leerlos. Como `.gitignore` de la raíz ignora `*.tfvars`, estos enlaces y los `*.example.tfvars` se agregaron con `git add -f`.

## Archivos propios conservados

`stages/3-networks/versions.tf` y `stages/3-networks/.terraform.lock.hcl` son de este repo y no se tocaron. No hubo colisiones de nombres, así que no se creó ningún `*.from-template`. Los `versions.tf` del template están en `envs/*/` y `modules/*/` y se copiaron tal cual.

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


## Adaptaciones del reto (gcp-ai-sandbox)

Se ajustaron `envs/shared/net-hubs.tf`, `envs/shared/remote.tf`, `envs/production/main.tf`, `envs/production/remote.tf` y `modules/base_env/main.tf` para las regiones `us-central1` y `us-east4`, los rangos documentados en `docs/plan-ip.md`, los nombres de subred de plataforma y los endpoints PSC `10.255.255.10`. Los ejemplos DNS siguen pendientes de confirmación. Cada archivo Terraform modificado conserva el encabezado de licencia y lleva un aviso de modificación.

La configuración no habilita despliegues. Además, `remote.tf` aún requiere alinear los outputs esperados con los que realmente producen `0-bootstrap` y `1-org` antes de usar estados remotos.
