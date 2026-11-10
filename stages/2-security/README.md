# 2-security

Controles de seguridad de la landing zone: llaves CMEK, Secret Manager, perímetro de VPC Service Controls y firewall jerárquico de la carpeta `ai-sandbox`. Las políticas de organización que obligan a usar CMEK viven en `1-org`.

> Igual que el resto del repo, esta etapa **no se despliega**. Solo se valida con `terraform validate` y `terraform test` con `mock_provider`.

## Qué crea

| Archivo | Recursos | Requisito del reto |
|---|---|---|
| `kms.tf` | Un key ring `<prefijo>-cmek` en `us-central1` y otro en `us-east4`, con una llave por servicio (`storage`, `bigquery`, `compute`, `aiplatform`, `artifactregistry`, `pubsub`, `dataflow`, `secretmanager`, `logging`), rotación cada 90 días | CMEK en todo |
| `kms.tf` | `cryptoKeyEncrypterDecrypter` para los agentes de servicio de cada proyecto de IA sobre la llave de su servicio | CMEK en todo |
| `secrets.tf` | Secretos `<prefijo>-vpn-psk` y `<prefijo>-huggingface-token`, replicados solo en la región principal y cifrados con la llave `secretmanager` | Secret Manager, sin secretos en código |
| `vpc-sc.tf` | Perímetro `<prefijo>_aisbx` con los proyectos security, ai-platform, ai-data y net-hub; restringe Storage, BigQuery, Vertex AI y el resto de `servicios_restringidos`; desde la VPC solo se alcanzan servicios restringidos; solo las cuentas del pipeline entran desde fuera | Perímetro VPC-SC alrededor de IA y datos, 0 copias fuera del perímetro |
| `firewall.tf` | Política de firewall jerárquica asociada a `ai-sandbox` | Firewall jerárquico, salida a Internet solo a dominios permitidos, sin rutas a producción |

Los módulos están en [`modules/kms`](../../modules/kms), [`modules/vpc-sc`](../../modules/vpc-sc) y [`modules/firewall`](../../modules/firewall), cada uno con sus propias pruebas.

### Reglas del firewall jerárquico

| Prioridad | Dirección | Acción | Qué |
|---|---|---|---|
| 100 / 101 | ingreso / egreso | deny | `rangos_produccion` (solo si la lista no está vacía) |
| 200 / 201 | ingreso / egreso | deny | IPs maliciosas conocidas (Threat Intelligence) |
| 1000 / 1001 | ingreso / egreso | goto_next | Rangos internos (Shared VPC y on-premises por HA VPN); los decide el firewall de la VPC |
| 1010 | ingreso | goto_next | IAP (`35.235.240.0/20`) en 22 y 3389 |
| 1020 | ingreso | goto_next | Health checks de Google |
| 1011 | egreso | allow | `restricted.googleapis.com` y `private.googleapis.com` en 443 |
| 1021 | egreso | allow | `dominios_permitidos` (PyPI, Hugging Face, GitHub, Anaconda) en 443 |
| 65000 / 65001 | ingreso / egreso | deny | `0.0.0.0/0` |

La prioridad identifica a cada regla dentro de la política, así que no puede repetirse ni siquiera entre ingreso y egreso: ingreso usa números pares y egreso el siguiente impar. El módulo `firewall` lo valida.

## Entradas

Los valores vienen de etapas anteriores; ver [`terraform.tfvars.example`](terraform.tfvars.example).

| Variable | De dónde sale |
|---|---|
| `proyecto_seguridad` | Proyecto `security` de la carpeta `common`: salidas `proyectos` y `numeros_de_proyecto` de 1-org |
| `proyectos_ia` | Proyectos `ai-platform` y `ai-data` de la carpeta `ai-sandbox`. Los crea 4-ai-platform, así que la variable empieza vacía (`{}`) y se llena cuando existen |
| `proyectos_perimetro_extra` | Proyecto `net-hub`: salida `numeros_de_proyecto` de 1-org |
| `carpeta_ai_sandbox` | Salida `carpetas.ai_sandbox` de 1-org |
| `cuentas_pipeline` | Salida `cuentas_por_etapa` de 0-bootstrap |
| `access_policy_id` | Access policy de la organización; si se deja en `null` se crea una (solo puede haber una por organización) |

## Salidas para otras etapas

- `llaves_cmek`: `llaves_cmek["us-central1"]["storage"]`, etc. Las etapas 3 a 5 deben usarlas en buckets, datasets, discos, Workbench, Vertex AI y Artifact Registry; la política de organización rechaza cualquier recurso de esos servicios sin CMEK.
- `secretos`: 3-networks lee la PSK de la VPN con `google_secret_manager_secret_version` (la cuenta `sa-3-networks` debe estar en `lectores`).
- `perimetro_vpc_sc`: 5-sandboxes agrega cada proyecto `aisbx-<equipo>` con `google_access_context_manager_service_perimeter_resource`. El perímetro ignora cambios en su lista de recursos para que esas altas no generen drift aquí.

## Cómo probar

```bash
cd stages/2-security
terraform init -backend=false
terraform validate
terraform test          # 15 passed, 0 failed
```

Y los módulos:

```bash
cd modules/kms && terraform init -backend=false && terraform test       # 6 passed
cd modules/vpc-sc && terraform init -backend=false && terraform test    # 8 passed
cd modules/firewall && terraform init -backend=false && terraform test  # 5 passed
```

El backend es GCS con prefijo `2-security`, el mismo que permite la condición IAM de `sa-2-security` en el bucket de estado. El bucket se pasa al iniciar: `terraform init -backend-config="bucket=redesaura-tfstate"`.

## Decisiones y supuestos

El documento del reto no es consistente en algunos puntos; esto es lo que se asumió (resumen en el [ADR 0003](../../docs/adr/0003-controles-de-seguridad.md)):

- **Firewall jerárquico en 2-security.** La tabla de componentes lo pone en el dominio de Seguridad (módulo `firewall`), aunque el diagrama lo dibuja en el hub de red. Se dejó aquí; 3-networks solo administra las reglas de firewall de cada VPC. Por eso la cuenta `sa-2-security` tiene `roles/compute.orgFirewallPolicyAdmin` (crear la política y sus reglas) y `roles/compute.orgSecurityResourceAdmin` (asociarla a la carpeta) en 0-bootstrap.
- **Políticas de CMEK en 1-org.** `gcp.restrictNonCmekServices` y `gcp.restrictCmekCryptoKeyProjects` sobre `ai-sandbox` se definen en 1-org, que ya conoce el proyecto `security` porque lo crea (ver ADR 0002). Esta etapa no las repite: dos estados administrando la misma política chocarían al aplicar. Por eso `sa-2-security` no necesita `roles/orgpolicy.policyAdmin`.
- **Proyectos de otras etapas.** `security` y `net-hub` los crea 1-org; `ai-platform` y `ai-data`, 4-ai-platform. Esta etapa solo recibe sus IDs y números. Como corre antes que 4-ai-platform, primero se aplica con `proyectos_ia = {}` (llaves, secretos, perímetro con `security` y `net-hub`, firewall) y se vuelve a aplicar con los números de `ai-platform` y `ai-data` cuando existen.
- **Valores de los secretos fuera de Terraform.** Se crean los secretos vacíos y el valor se agrega con `gcloud secrets versions add`, para que no quede ni en el código ni en el estado.
- **Agentes de servicio.** Los correos de los agentes se arman con el número de proyecto. Existen cuando la API correspondiente se habilita en el proyecto (4-ai-platform), así que esa etapa debe correr la primera vez antes de que los permisos de KMS se puedan aplicar en un despliegue real.
- **Segunda región de KMS.** Una llave CMEK debe estar en la misma región que el recurso, y `us-east4` es la región alterna para GPU, por eso hay key ring en ambas.
- **Enforced por defecto.** El criterio de aceptación pide que copiar datos fuera del perímetro falle. Para un primer despliegue real conviene `vpc_sc_modo_prueba = true`, revisar las violaciones en los logs y después pasarlo a `false`.
- **Costo de NGFW.** Las reglas con FQDN y Threat Intelligence requieren Cloud NGFW Standard, que se cobra por GB inspeccionado. No aplica mientras no se despliegue.
- **Sandboxes por equipo.** Sus agentes de servicio todavía no reciben permisos sobre las llaves; eso se resuelve con la fábrica de sandboxes en el sprint 5.
