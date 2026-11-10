locals {
  rangos_iap           = ["35.235.240.0/20"]
  rangos_health_checks = ["35.191.0.0/16", "130.211.0.0/22"]
  rangos_apis_google   = ["199.36.153.4/30", "199.36.153.8/30"] # restricted y private.googleapis.com
  ips_maliciosas       = ["iplist-known-malicious-ips"]

  # La prioridad identifica a la regla dentro de la política, así que no se repite
  # entre ingreso y egreso: ingreso usa números pares y egreso el siguiente impar.
  reglas_produccion = {
    deny-ingreso-produccion = {
      prioridad     = 100
      direccion     = "INGRESS"
      accion        = "deny"
      rangos_origen = var.rangos_produccion
      registrar     = true
    }
    deny-egreso-produccion = {
      prioridad      = 101
      direccion      = "EGRESS"
      accion         = "deny"
      rangos_destino = var.rangos_produccion
      registrar      = true
    }
  }

  reglas_base = {
    deny-ingreso-ips-maliciosas = {
      prioridad       = 200
      direccion       = "INGRESS"
      accion          = "deny"
      amenazas_origen = local.ips_maliciosas
      registrar       = true
    }
    deny-egreso-ips-maliciosas = {
      prioridad        = 201
      direccion        = "EGRESS"
      accion           = "deny"
      amenazas_destino = local.ips_maliciosas
      registrar        = true
    }
    delegar-ingreso-interno = {
      prioridad     = 1000
      direccion     = "INGRESS"
      accion        = "goto_next"
      rangos_origen = var.rangos_internos
    }
    delegar-ingreso-iap = {
      prioridad     = 1010
      direccion     = "INGRESS"
      accion        = "goto_next"
      rangos_origen = local.rangos_iap
      protocolos    = [{ protocolo = "tcp", puertos = ["22", "3389"] }]
    }
    delegar-ingreso-health-checks = {
      prioridad     = 1020
      direccion     = "INGRESS"
      accion        = "goto_next"
      rangos_origen = local.rangos_health_checks
      protocolos    = [{ protocolo = "tcp" }]
    }
    deny-ingreso-todo = {
      prioridad     = 65000
      direccion     = "INGRESS"
      accion        = "deny"
      rangos_origen = ["0.0.0.0/0"]
      registrar     = true
    }
    delegar-egreso-interno = {
      prioridad      = 1001
      direccion      = "EGRESS"
      accion         = "goto_next"
      rangos_destino = var.rangos_internos
    }
    allow-egreso-apis-google = {
      prioridad      = 1011
      direccion      = "EGRESS"
      accion         = "allow"
      rangos_destino = local.rangos_apis_google
      protocolos     = [{ protocolo = "tcp", puertos = ["443"] }]
    }
    allow-egreso-dominios-permitidos = {
      prioridad     = 1021
      direccion     = "EGRESS"
      accion        = "allow"
      fqdns_destino = var.dominios_permitidos
      protocolos    = [{ protocolo = "tcp", puertos = ["443"] }]
      registrar     = true
    }
    deny-egreso-todo = {
      prioridad      = 65001
      direccion      = "EGRESS"
      accion         = "deny"
      rangos_destino = ["0.0.0.0/0"]
      registrar      = true
    }
  }
}

module "firewall" {
  source = "../../modules/firewall"

  nombre       = "${var.prefijo_empresa}-aisbx"
  padre        = var.carpeta_ai_sandbox
  descripcion  = "Firewall jerárquico de la carpeta ai-sandbox"
  asociaciones = { ai-sandbox = var.carpeta_ai_sandbox }
  reglas       = merge({ for k, v in local.reglas_produccion : k => v if length(var.rangos_produccion) > 0 }, local.reglas_base)
}
