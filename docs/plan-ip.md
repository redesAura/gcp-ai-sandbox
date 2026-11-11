# Plan IP de `3-networks`

## Supuestos

- On-premises usa `172.16.0.0/16`; ningún rango de Google Cloud se traslapa con él.
- Se asigna `10.10.0.0/16` a `us-central1` y `10.20.0.0/16` a `us-east4`.
- Hub y plataforma son VPC separadas. Sus subredes están dentro del bloque regional común, sin traslaparse entre sí.
- La VPC de plataforma recibe el rango de Private Service Access `10.10.16.0/20`; un endpoint PSC para APIs de Google se centraliza en el hub (`10.255.255.10/32`) y se comparte con los spokes por NCC.
- El dominio y los resolutores DNS on-prem aún no fueron confirmados. Los valores de los archivos `*.example.tfvars` son ejemplos; el reenvío DNS depende de que HA VPN proporcione conectividad a esos resolutores.

## `us-central1` — `10.10.0.0/16`

| Recurso | CIDR | Uso |
|---|---|---|
| `snet-hub-usc1` | `10.10.0.0/24` | Subred del hub |
| `snet-hub-usc1-proxy` | `10.10.2.0/23` | Proxy-only del hub, reservado desde el espacio libre para el módulo de red |
| PSA | `10.10.16.0/20` | Private Service Access de la VPC de plataforma |
| `snet-ai-platform-usc1` | `10.10.32.0/22` | Nodos y servicios compartidos de la plataforma |
| `gke-services-usc1` | `10.10.36.0/22` | Services de GKE |
| `gke-master-usc1` | `10.10.40.0/28` | Rango reservado para control plane privado; lo consume la etapa del clúster |
| `snet-ai-data-usc1` | `10.10.44.0/24` | Datos y workers de Dataflow |
| `snet-ai-platform-usc1-proxy` | `10.10.48.0/23` | Proxy-only de la VPC de plataforma |
| `gke-pods-usc1` | `10.10.64.0/19` | Pods del clúster principal |
| `snet-aisbx-01` | `10.10.128.0/22` | Sandbox equipo 1 |
| `snet-aisbx-02` | `10.10.132.0/22` | Sandbox equipo 2 |
| `snet-aisbx-03` | `10.10.136.0/22` | Sandbox equipo 3 |
| Reserva | `10.10.140.0/22` a `10.10.252.0/22` | Hasta 29 sandboxes adicionales /22 |

## `us-east4` — `10.20.0.0/16`

| Recurso | CIDR | Uso |
|---|---|---|
| `snet-hub-use4` | `10.20.0.0/24` | Subred regional del hub |
| `snet-hub-use4-proxy` | `10.20.2.0/23` | Proxy-only del hub, reservado desde el espacio libre |
| `snet-ai-platform-use4` | `10.20.32.0/22` | Nodos y servicios compartidos del clúster de respaldo |
| `gke-services-use4` | `10.20.36.0/22` | Services de GKE |
| `gke-master-use4` | `10.20.40.0/28` | Rango reservado para control plane privado |
| `snet-ai-platform-use4-proxy` | `10.20.48.0/23` | Proxy-only de la VPC de plataforma |
| `gke-pods-use4` | `10.20.64.0/20` | Pods del clúster de respaldo |
| Reserva | `10.20.128.0/17` | Posibles recursos de sandbox en la región alterna |

## Rangos globales

- PSC a APIs de Google: `10.255.255.10/32`.
- HA VPN: dos túneles en `us-central1`. En `169.254.0.0/30`, Google usa `.1` y el peer on-prem `.2`; el segundo usa `.1` y `.2` dentro de `169.254.1.0/30`. Son enlaces BGP, no subredes VPC.
- ASN de Cloud Router: `64512`; ASN on-prem (supuesto): `65001`. No hay VPN en `us-east4` en este diseño.
- GKE reserva cuatro IP por subred primaria. Se dimensionaron los rangos secundarios de pods bajo la hipótesis del equipo de un `/24` por nodo máximo: `/19` para 32 nodos y `/20` para 16.

## Pendientes de confirmación

1. Confirmar con redes `172.16.0.0/16`, los ASN y los dos rangos BGP /30. HA VPN queda apagada (`enable_ha_vpn = false`) hasta conocer las dos IP públicas on-prem y crear el secreto PSK.
2. Sustituir `example.com.` y `172.16.0.53`/`172.16.0.54` en los ejemplos por el dominio y los resolutores DNS reales; las dos IP son marcadores, no datos confirmados.
3. El `/28` de `gke-master-*` se reserva para `4-ai-platform`; no se crea como subred en esta etapa.
4. Los rangos `snet-aisbx-*` se crean como subredes de la Shared VPC de plataforma; `5-sandboxes` debe asociar sus recursos a la subred del equipo. Las subredes por sí solas no aíslan el tráfico: IAM y reglas de firewall deben completar la separación.
5. Verificar los espacios proxy-only asignados desde los bloques que el equipo reportó como libres.
