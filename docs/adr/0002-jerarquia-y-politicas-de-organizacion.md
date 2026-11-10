# 0002 - Jerarquía de recursos y políticas de organización

Contexto:
El reto pide una carpeta ai-sandbox aislada de producción, regiones permitidas, cero llaves de cuentas de servicio, CMEK en buckets, discos, BigQuery y Vertex AI verificado por política de organización, y logs de auditoría centralizados. 0-bootstrap ya crea la carpeta bootstrap con el proyecto semilla y una cuenta de servicio por etapa.

Decisión:
- 1-org crea las carpetas common y ai-sandbox directamente bajo la organización, y los proyectos net-hub, logging y security dentro de common. Los proyectos de ai-sandbox los crean 4-ai-platform y 5-sandboxes.
- Las políticas generales (regiones us-central1 y us-east4, sin llaves de cuentas de servicio, sin IP públicas, sin red default, buckets privados) se aplican en la organización.
- CMEK obligatorio (gcp.restrictNonCmekServices) y llaves solo del proyecto security (gcp.restrictCmekCryptoKeyProjects) se aplican en la carpeta ai-sandbox, no en toda la organización.
- compute.restrictSharedVpcHostProjects en ai-sandbox limita la Shared VPC a proyectos de common y ai-sandbox.
- Las políticas se declaran con google_org_policy_policy en lugar del módulo org-policy del template, para no depender de módulos externos en las pruebas con mock_provider.
- Un solo sink de organización envía auditoría, VPC Flow Logs, firewall y DNS a un bucket de Cloud Logging con Log Analytics en el proyecto logging.
- Los grupos de Cloud Identity se reciben como variables; 1-org solo asigna sus roles.
- Los roles por perfil de equipo se publican como output para que 5-sandboxes los asigne por proyecto.

Consecuencias:
- 2-security depende de que exista el proyecto security, y 3-networks del proyecto net-hub.
- sa-1-org necesita, además de los roles originales, projectCreator, billing.user, iam.securityAdmin, securitycenter.notificationConfigEditor, essentialcontacts.admin, tagAdmin y tagUser (agregados en 0-bootstrap).
- El bucket de logs, el dataset de facturación y el tópico de SCC en common no usan CMEK porque se crean antes que las llaves de 2-security; se pueden migrar después.
- Cualquier recurso en ai-sandbox sin llave CMEK de security falla al crearse; las etapas 4 y 5 deben pasar la llave de 2-security a cada recurso.
- iam.allowedPolicyMemberDomains queda desactivada hasta conocer el ID de cliente de Cloud Identity.
