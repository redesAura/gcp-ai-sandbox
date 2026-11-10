# 0003 - Controles de seguridad y reparto entre 1-org y 2-security

Contexto:
El reto pide CMEK en todo, Secret Manager, un perímetro de VPC Service Controls alrededor de los proyectos de IA y datos, y un firewall jerárquico. 1-org y 2-security se desarrollaron en paralelo y al integrarlas las dos declaraban las mismas políticas de CMEK sobre la carpeta ai-sandbox; además 2-security asumía que 1-org creaba los proyectos ai-platform y ai-data, que según el ADR 0002 crea 4-ai-platform.

Decisión:
- Las políticas gcp.restrictNonCmekServices y gcp.restrictCmekCryptoKeyProjects se declaran solo en 1-org, que es la etapa de políticas de organización según el reto y ya conoce el proyecto security. Su lista de servicios cubre todas las llaves que crea 2-security.
- 2-security crea las llaves (módulo kms, un key ring por región y una llave por servicio), los secretos, el perímetro (módulo vpc-sc) y el firewall jerárquico de ai-sandbox (módulo firewall). 3-networks solo administra las reglas de firewall de cada VPC.
- 2-security recibe por variables lo que crean otras etapas: carpeta ai-sandbox, id y número de security y número de net-hub (salidas de 1-org) y las cuentas del pipeline (salida de 0-bootstrap).
- `proyectos_ia` empieza vacío. 2-security se aplica una vez antes de 4-ai-platform y otra después, con los números de ai-platform y ai-data, para darles permisos sobre las llaves y meterlos al perímetro.
- En la política de firewall cada regla tiene una prioridad distinta, también entre ingreso y egreso, porque la prioridad es lo que identifica a la regla dentro de la política.
- Los valores de los secretos se cargan fuera de Terraform para que no queden en el código ni en el estado.

Consecuencias:
- sa-2-security tiene cloudkms.admin, accesscontextmanager.policyAdmin, secretmanager.admin, compute.orgFirewallPolicyAdmin y compute.orgSecurityResourceAdmin (para asociar la política a la carpeta); no necesita orgpolicy.policyAdmin.
- Cambiar la lista de servicios con CMEK obligatorio es un cambio en 1-org, y agregar una llave nueva en 2-security implica revisarla.
- Los agentes de servicio de cada sandbox todavía no reciben permisos sobre las llaves; lo resuelve la fábrica de sandboxes (5-sandboxes), que también agrega cada proyecto al perímetro.
- 3-networks, al adaptarse, no debe conservar el firewall jerárquico que trae el template.
