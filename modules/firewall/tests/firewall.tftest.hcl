mock_provider "google" {}

variables {
  nombre       = "redesaura-aisbx"
  padre        = "folders/555555555555"
  asociaciones = { ai-sandbox = "folders/555555555555" }

  reglas = {
    allow-egreso-dominios = {
      prioridad     = 1000
      direccion     = "EGRESS"
      accion        = "allow"
      fqdns_destino = ["pypi.org"]
      protocolos    = [{ protocolo = "tcp", puertos = ["443"] }]
    }
    deny-egreso-todo = {
      prioridad      = 65000
      direccion      = "EGRESS"
      accion         = "deny"
      rangos_destino = ["0.0.0.0/0"]
      registrar      = true
    }
  }
}

run "politica_en_la_carpeta" {
  command = plan

  assert {
    condition     = google_compute_firewall_policy.politica.parent == "folders/555555555555"
    error_message = "La política debe pertenecer a la carpeta indicada."
  }

  assert {
    condition     = google_compute_firewall_policy_association.asociacion["ai-sandbox"].attachment_target == "folders/555555555555"
    error_message = "La política debe asociarse a la carpeta."
  }
}

run "reglas_creadas" {
  command = plan

  assert {
    condition     = length(google_compute_firewall_policy_rule.regla) == 2
    error_message = "Debe crearse una regla por entrada."
  }

  assert {
    condition     = google_compute_firewall_policy_rule.regla["allow-egreso-dominios"].match[0].layer4_configs[0].ports == tolist(["443"])
    error_message = "La regla de dominios solo debe abrir 443."
  }

  assert {
    condition     = google_compute_firewall_policy_rule.regla["deny-egreso-todo"].match[0].layer4_configs[0].ip_protocol == "all"
    error_message = "Sin protocolos la regla aplica a todo."
  }

  assert {
    condition     = google_compute_firewall_policy_rule.regla["deny-egreso-todo"].enable_logging == true
    error_message = "El deny final debe registrar."
  }
}

run "prioridad_repetida_falla" {
  command = plan

  variables {
    reglas = {
      a = { prioridad = 1000, direccion = "EGRESS", accion = "deny", rangos_destino = ["0.0.0.0/0"] }
      b = { prioridad = 1000, direccion = "INGRESS", accion = "allow", rangos_origen = ["10.0.0.0/8"] }
    }
  }

  expect_failures = [var.reglas]
}

run "accion_invalida_falla" {
  command = plan

  variables {
    reglas = {
      a = { prioridad = 1000, direccion = "EGRESS", accion = "permitir", rangos_destino = ["0.0.0.0/0"] }
    }
  }

  expect_failures = [var.reglas]
}

run "padre_invalido_falla" {
  command = plan

  variables {
    padre = "projects/redesaura-security"
  }

  expect_failures = [var.padre]
}
