locals {
  politica = var.access_policy_id != null ? var.access_policy_id : google_access_context_manager_access_policy.politica[0].name

  niveles_acceso = length(var.rangos_ip_permitidos) > 0 ? [google_access_context_manager_access_level.corporativo[0].name] : []

  estado = var.modo_prueba ? [] : [true]
  prueba = var.modo_prueba ? [true] : []
}

resource "google_access_context_manager_access_policy" "politica" {
  count = var.access_policy_id == null ? 1 : 0

  parent = "organizations/${var.org_id}"
  title  = "${var.nombre}_politica"
}

resource "google_access_context_manager_access_level" "corporativo" {
  count = length(var.rangos_ip_permitidos) > 0 ? 1 : 0

  parent = "accessPolicies/${local.politica}"
  name   = "accessPolicies/${local.politica}/accessLevels/${var.nombre}_corporativo"
  title  = "${var.nombre}_corporativo"

  basic {
    conditions {
      ip_subnetworks = var.rangos_ip_permitidos
    }
  }
}

resource "google_access_context_manager_service_perimeter" "perimetro" {
  parent                    = "accessPolicies/${local.politica}"
  name                      = "accessPolicies/${local.politica}/servicePerimeters/${var.nombre}"
  title                     = var.nombre
  description               = var.descripcion
  perimeter_type            = "PERIMETER_TYPE_REGULAR"
  use_explicit_dry_run_spec = var.modo_prueba

  dynamic "status" {
    for_each = local.estado
    content {
      restricted_services = var.servicios_restringidos
      access_levels       = local.niveles_acceso

      vpc_accessible_services {
        enable_restriction = true
        allowed_services   = var.servicios_accesibles_vpc
      }

      dynamic "ingress_policies" {
        for_each = var.reglas_ingreso
        content {
          title = ingress_policies.key
          ingress_from {
            identities    = length(ingress_policies.value.identidades) > 0 ? ingress_policies.value.identidades : null
            identity_type = ingress_policies.value.tipo_identidad
            dynamic "sources" {
              for_each = ingress_policies.value.niveles_acceso
              content {
                access_level = sources.value
              }
            }
            dynamic "sources" {
              for_each = ingress_policies.value.proyectos_origen
              content {
                resource = sources.value
              }
            }
          }
          ingress_to {
            resources = ingress_policies.value.recursos_destino
            dynamic "operations" {
              for_each = ingress_policies.value.servicios
              content {
                service_name = operations.value
                dynamic "method_selectors" {
                  for_each = operations.value == "*" ? [] : ["*"]
                  content {
                    method = method_selectors.value
                  }
                }
              }
            }
          }
        }
      }

      dynamic "egress_policies" {
        for_each = var.reglas_egreso
        content {
          title = egress_policies.key
          egress_from {
            identities    = length(egress_policies.value.identidades) > 0 ? egress_policies.value.identidades : null
            identity_type = egress_policies.value.tipo_identidad
          }
          egress_to {
            resources = egress_policies.value.recursos_destino
            dynamic "operations" {
              for_each = egress_policies.value.servicios
              content {
                service_name = operations.value
                dynamic "method_selectors" {
                  for_each = operations.value == "*" ? [] : ["*"]
                  content {
                    method = method_selectors.value
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  dynamic "spec" {
    for_each = local.prueba
    content {
      restricted_services = var.servicios_restringidos
      access_levels       = local.niveles_acceso

      vpc_accessible_services {
        enable_restriction = true
        allowed_services   = var.servicios_accesibles_vpc
      }

      dynamic "ingress_policies" {
        for_each = var.reglas_ingreso
        content {
          title = ingress_policies.key
          ingress_from {
            identities    = length(ingress_policies.value.identidades) > 0 ? ingress_policies.value.identidades : null
            identity_type = ingress_policies.value.tipo_identidad
            dynamic "sources" {
              for_each = ingress_policies.value.niveles_acceso
              content {
                access_level = sources.value
              }
            }
            dynamic "sources" {
              for_each = ingress_policies.value.proyectos_origen
              content {
                resource = sources.value
              }
            }
          }
          ingress_to {
            resources = ingress_policies.value.recursos_destino
            dynamic "operations" {
              for_each = ingress_policies.value.servicios
              content {
                service_name = operations.value
                dynamic "method_selectors" {
                  for_each = operations.value == "*" ? [] : ["*"]
                  content {
                    method = method_selectors.value
                  }
                }
              }
            }
          }
        }
      }

      dynamic "egress_policies" {
        for_each = var.reglas_egreso
        content {
          title = egress_policies.key
          egress_from {
            identities    = length(egress_policies.value.identidades) > 0 ? egress_policies.value.identidades : null
            identity_type = egress_policies.value.tipo_identidad
          }
          egress_to {
            resources = egress_policies.value.recursos_destino
            dynamic "operations" {
              for_each = egress_policies.value.servicios
              content {
                service_name = operations.value
                dynamic "method_selectors" {
                  for_each = operations.value == "*" ? [] : ["*"]
                  content {
                    method = method_selectors.value
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  # Los proyectos se agregan con los recursos *_resource de abajo, también desde 5-sandboxes
  lifecycle {
    ignore_changes = [status[0].resources, spec[0].resources]
  }
}

resource "google_access_context_manager_service_perimeter_resource" "proyecto" {
  for_each = var.modo_prueba ? {} : var.recursos

  perimeter_name = google_access_context_manager_service_perimeter.perimetro.name
  resource       = "projects/${each.value}"
}

resource "google_access_context_manager_service_perimeter_dry_run_resource" "proyecto" {
  for_each = var.modo_prueba ? var.recursos : {}

  perimeter_name = google_access_context_manager_service_perimeter.perimetro.name
  resource       = "projects/${each.value}"
}
