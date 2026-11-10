mock_provider "google" {}

variables {
  org_id                 = "123456789012"
  access_policy_id       = "987654321"
  nombre                 = "redesaura_aisbx"
  servicios_restringidos = ["storage.googleapis.com", "bigquery.googleapis.com", "aiplatform.googleapis.com"]

  recursos = {
    ai-platform = "222222222222"
    ai-data     = "333333333333"
  }

  reglas_ingreso = {
    pipeline = {
      identidades    = ["serviceAccount:sa-2-security@redesaura-seed.iam.gserviceaccount.com"]
      niveles_acceso = ["*"]
    }
  }

  reglas_egreso = {
    modelos-google = {
      identidades      = ["serviceAccount:service-222222222222@gcp-sa-aiplatform.iam.gserviceaccount.com"]
      recursos_destino = ["projects/999999999999"]
      servicios        = ["storage.googleapis.com"]
    }
  }
}

run "perimetro_enforced" {
  command = plan

  assert {
    condition     = length(google_access_context_manager_service_perimeter.perimetro.status) == 1 && length(google_access_context_manager_service_perimeter.perimetro.spec) == 0
    error_message = "En modo enforced la configuración va en status."
  }

  assert {
    condition     = google_access_context_manager_service_perimeter.perimetro.status[0].restricted_services == toset(var.servicios_restringidos)
    error_message = "El perímetro debe restringir los servicios indicados."
  }

  assert {
    condition     = google_access_context_manager_service_perimeter.perimetro.status[0].vpc_accessible_services[0].enable_restriction == true
    error_message = "Los servicios accesibles desde la VPC deben estar restringidos."
  }

  assert {
    condition     = length(google_access_context_manager_service_perimeter_resource.proyecto) == 2 && length(google_access_context_manager_service_perimeter_dry_run_resource.proyecto) == 0
    error_message = "Los proyectos deben agregarse al perímetro enforced."
  }

  assert {
    condition     = google_access_context_manager_service_perimeter_resource.proyecto["ai-data"].resource == "projects/333333333333"
    error_message = "El recurso debe usar el número de proyecto."
  }
}

run "reglas_de_ingreso_y_egreso" {
  command = plan

  assert {
    condition     = google_access_context_manager_service_perimeter.perimetro.status[0].ingress_policies[0].ingress_from[0].sources[0].access_level == "*"
    error_message = "La regla de ingreso del pipeline debe aceptar cualquier origen."
  }

  assert {
    condition     = google_access_context_manager_service_perimeter.perimetro.status[0].egress_policies[0].egress_to[0].operations[0].service_name == "storage.googleapis.com"
    error_message = "La regla de egreso debe limitarse al servicio indicado."
  }

  assert {
    condition     = google_access_context_manager_service_perimeter.perimetro.status[0].egress_policies[0].egress_to[0].operations[0].method_selectors[0].method == "*"
    error_message = "Un servicio concreto debe llevar selector de métodos."
  }
}

run "perimetro_dry_run" {
  command = plan

  variables {
    modo_prueba = true
  }

  assert {
    condition     = length(google_access_context_manager_service_perimeter.perimetro.status) == 0 && length(google_access_context_manager_service_perimeter.perimetro.spec) == 1
    error_message = "En dry-run la configuración va en spec."
  }

  assert {
    condition     = google_access_context_manager_service_perimeter.perimetro.use_explicit_dry_run_spec == true
    error_message = "El dry-run debe usar spec explícito."
  }

  assert {
    condition     = length(google_access_context_manager_service_perimeter_dry_run_resource.proyecto) == 2 && length(google_access_context_manager_service_perimeter_resource.proyecto) == 0
    error_message = "En dry-run los proyectos se agregan a spec."
  }
}

run "usa_access_policy_existente" {
  command = plan

  assert {
    condition     = length(google_access_context_manager_access_policy.politica) == 0
    error_message = "Con access_policy_id no se crea otra access policy."
  }
}

run "crea_access_policy" {
  command = plan

  variables {
    access_policy_id = null
  }

  assert {
    condition     = google_access_context_manager_access_policy.politica[0].parent == "organizations/123456789012"
    error_message = "La access policy debe crearse en la organización."
  }
}

run "nivel_de_acceso_corporativo" {
  command = plan

  variables {
    rangos_ip_permitidos = ["203.0.113.0/24"]
  }

  assert {
    condition     = google_access_context_manager_access_level.corporativo[0].basic[0].conditions[0].ip_subnetworks == tolist(["203.0.113.0/24"])
    error_message = "El access level debe contener los rangos corporativos."
  }

  assert {
    condition     = contains(google_access_context_manager_service_perimeter.perimetro.status[0].access_levels, "accessPolicies/987654321/accessLevels/redesaura_aisbx_corporativo")
    error_message = "El perímetro debe usar el access level corporativo."
  }
}

run "sin_rangos_no_hay_nivel_de_acceso" {
  command = plan

  assert {
    condition     = length(google_access_context_manager_access_level.corporativo) == 0
    error_message = "Sin rangos no se crea access level."
  }
}

run "nombre_invalido_falla" {
  command = plan

  variables {
    nombre = "redesaura-aisbx"
  }

  expect_failures = [var.nombre]
}
