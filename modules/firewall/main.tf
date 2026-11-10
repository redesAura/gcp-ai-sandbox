resource "google_compute_firewall_policy" "politica" {
  parent      = var.padre
  short_name  = var.nombre
  description = var.descripcion
}

resource "google_compute_firewall_policy_rule" "regla" {
  for_each = var.reglas

  firewall_policy         = google_compute_firewall_policy.politica.name
  description             = each.key
  priority                = each.value.prioridad
  direction               = each.value.direccion
  action                  = each.value.accion
  enable_logging          = each.value.registrar
  target_service_accounts = each.value.cuentas_de_servicio

  match {
    src_ip_ranges             = each.value.rangos_origen
    dest_ip_ranges            = each.value.rangos_destino
    dest_fqdns                = each.value.fqdns_destino
    src_threat_intelligences  = each.value.amenazas_origen
    dest_threat_intelligences = each.value.amenazas_destino

    dynamic "layer4_configs" {
      for_each = each.value.protocolos
      content {
        ip_protocol = layer4_configs.value.protocolo
        ports       = layer4_configs.value.puertos
      }
    }
  }
}

resource "google_compute_firewall_policy_association" "asociacion" {
  for_each = var.asociaciones

  name              = "${var.nombre}-${each.key}"
  firewall_policy   = google_compute_firewall_policy.politica.id
  attachment_target = each.value
}
