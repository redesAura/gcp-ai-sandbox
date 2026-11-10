# 1-org

Esta etapa monta la estructura de la organización: las carpetas, los proyectos compartidos, las políticas de organización, los logs de auditoría, Security Command Center, los tags y los permisos de los grupos. Todo lo que viene después (redes, seguridad, la plataforma de IA y los sandboxes) se apoya en lo que se crea aquí.

Se aplica con la cuenta `sa-1-org` que crea `0-bootstrap`, y el estado vive en `gs://redesaura-tfstate/1-org/`. El bucket se pasa al iniciar, igual que en `2-security`: `terraform init -backend-config="bucket=redesaura-tfstate"`.

## La jerarquía

```
organización
├── bootstrap/     redesaura-seed (de 0-bootstrap)
├── common/        redesaura-net-hub, redesaura-logging, redesaura-security
└── ai-sandbox/    ai-platform, ai-data y los aisbx-<equipo>
```

Los tres proyectos de `common` se crean aquí, vacíos y con las APIs ya activadas, para que las siguientes etapas solo tengan que llenarlos:

- `redesaura-net-hub`: la Shared VPC, Cloud NAT, DNS y la VPN. Lo usa `3-networks`.
- `redesaura-logging`: el bucket de auditoría y el dataset de facturación. Los usa esta misma etapa.
- `redesaura-security`: KMS, Secret Manager, VPC-SC y el tópico de SCC. Lo usa `2-security` (y esta etapa, para el tópico).

Los proyectos de `ai-sandbox` no se crean aquí: `ai-platform` y `ai-data` salen de `4-ai-platform`, y los de cada equipo, de `5-sandboxes`.

## Políticas de organización

La idea general es cerrar por defecto lo que suele salir mal en una organización nueva. A nivel organización:

- Solo se pueden crear recursos en `us-central1` y `us-east4`.
- No hay llaves de cuentas de servicio; el pipeline entra con Workload Identity Federation.
- Las cuentas de servicio default ya no reciben Editor automáticamente.
- Ninguna VM ni Cloud SQL puede tener IP pública, y los proyectos nuevos nacen sin la red default.
- Compute queda endurecido: OS Login obligatorio, sin puerto serial, sin virtualización anidada, sin IPv6 externa y forwarding solo interno.
- Los buckets usan acceso uniforme y nunca pueden ser públicos.
- Los contactos esenciales, y si se define `ids_cliente_permitidos`, cualquier identidad en IAM, tienen que ser del dominio de la empresa.

La carpeta `ai-sandbox` tiene tres reglas extra, porque ahí es donde los equipos trabajan con datos:

- Vertex AI, BigQuery, Storage, discos, GKE, Workbench, Artifact Registry, Pub/Sub, Dataflow y Secret Manager solo aceptan recursos cifrados con CMEK. La lista (`servicios_cmek_obligatorio`) coincide con las llaves que crea `2-security`.
- Esas llaves solo pueden venir de `redesaura-security`.
- Los proyectos solo pueden conectarse a una Shared VPC de `common` o de `ai-sandbox`, nunca a una red de producción.

La lista completa de constraints está en [`org_policies.tf`](org_policies.tf).

## Logs y SCC

Se activan los logs de auditoría (Admin Read, Data Read y Data Write) para todos los servicios. Un sink a nivel organización junta auditoría, VPC Flow Logs, firewall y consultas DNS de todos los proyectos en el bucket `auditoria-org` del proyecto de logging, con Log Analytics y 400 días de retención.

En el mismo proyecto queda el dataset `facturacion`, que es de donde lee el tablero de costos de `cost-guard`.

Los hallazgos activos de Security Command Center se publican en el tópico `scc-hallazgos` del proyecto de seguridad.

## Quién puede hacer qué

Los grupos de Cloud Identity se crean a mano y se pasan en la variable `grupos`:

- **plataforma** puede ver la organización, las políticas, el IAM y los logs, pero no toca los datos de los equipos. Los cambios a la base se hacen solo desde el pipeline.
- **seguridad** tiene revisor de seguridad, SCC en lectura y acceso a los logs de data access.
- **auditoria** puede leer y consultar los logs del proyecto de logging.
- **facturacion** puede ver la facturación y el dataset `facturacion`.

Los permisos dentro de cada sandbox (científico de datos, ingeniero ML, líder de equipo y revisor) se definen aquí en el output `roles_por_perfil`, pero los asigna `5-sandboxes`. Ningún perfil puede modificar IAM ni crear redes.

## Tags

Hay dos tags. `entorno` (`common` o `ai-sandbox`) se pone en cada carpeta y sirve para escribir condiciones de IAM y de políticas. `sensibilidad` (`baja`, `media`, `alta`) es para clasificar los datasets y buckets del `data-lake`.

## Cómo aplicarla

Antes de correr Terraform hay que:

1. Crear los grupos de Cloud Identity.
2. Activar Security Command Center (nivel Standard) en la organización.

Luego copia [`terraform.tfvars.example`](terraform.tfvars.example) a `terraform.tfvars` y llena al menos `org_id`, `billing_account`, `prefijo_empresa`, `dominio` y `grupos`. El resto tiene defaults razonables; revisa [`variables.tf`](variables.tf) si necesitas cambiar algo.

Después del primer apply, falta un paso manual: en la consola de Billing, apuntar la exportación de facturación al dataset `facturacion`.

Para validar sin tocar GCP:

```bash
cd stages/1-org
terraform init -backend=false
terraform validate
terraform test
```

Las pruebas usan `mock_provider`, así que corren sin credenciales.

## Cosas que no están aquí (a propósito)

- **CMEK en `common`.** El bucket de logs, el dataset de facturación y el tópico de SCC se crean antes que las llaves de `2-security`, así que por ahora usan cifrado de Google. Se pueden migrar a CMEK después.
- **Modelos permitidos de Model Garden.** `vertexai.allowedModels` lo maneja el módulo `vertex-models`, junto con su lista `allowed_models`.
- **VPC Service Controls y firewall jerárquico.** El perímetro y la política de firewall jerárquica de `ai-sandbox` los crea `2-security`; `3-networks` solo administra las reglas de cada VPC.

## Salidas para otras etapas

- `carpetas`: `2-security` usa `carpetas.ai_sandbox` como `carpeta_ai_sandbox`.
- `proyectos` y `numeros_de_proyecto`: `2-security` arma `proyecto_seguridad` con el id y el número de `security`, y pasa el número de `net-hub` en `proyectos_perimetro_extra`.
- `roles_por_perfil`: lo usa `5-sandboxes`.

El razonamiento detrás de la jerarquía y las políticas está en el [ADR 0002](../../docs/adr/0002-jerarquia-y-politicas-de-organizacion.md). Parte del código está adaptado de [terraform-example-foundation](https://github.com/terraform-google-modules/terraform-example-foundation) (ver [la licencia](LICENSE-terraform-example-foundation.txt)).
