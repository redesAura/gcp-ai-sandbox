mock_provider "google" {}
mock_provider "google-beta" {}

variables {
  org_id          = "123456789012"
  prefijo_empresa = "redesaura"

  proyecto_seguridad = {
    id     = "redesaura-security"
    numero = "111111111111"
  }

  proyectos_ia = {
    ai-platform = "222222222222"
    ai-data     = "333333333333"
  }

  proyectos_perimetro_extra = {
    net-hub = "444444444444"
  }

  carpeta_ai_sandbox = "folders/555555555555"

  cuentas_pipeline = {
    "2-security"  = "sa-2-security@redesaura-seed.iam.gserviceaccount.com"
    "5-sandboxes" = "sa-5-sandboxes@redesaura-seed.iam.gserviceaccount.com"
  }
}

run "llaves_en_ambas_regiones" {
  command = plan

  assert {
    condition     = length(module.kms.llaves) == 2 && alltrue([for u in ["us-central1", "us-east4"] : contains(keys(module.kms.llaves), u)])
    error_message = "Debe haber un key ring en us-central1 y otro en us-east4."
  }

  assert {
    condition     = alltrue([for s in ["storage", "bigquery", "compute", "aiplatform", "secretmanager"] : contains(keys(module.kms.llaves["us-central1"]), s)])
    error_message = "Faltan llaves CMEK para buckets, BigQuery, discos, Vertex AI o Secret Manager."
  }
}

run "agentes_de_ia_pueden_cifrar" {
  command = plan

  assert {
    condition     = contains(local.encriptadores["aiplatform"], "serviceAccount:service-222222222222@gcp-sa-aiplatform.iam.gserviceaccount.com")
    error_message = "El agente de Vertex AI de ai-platform debe poder usar su llave."
  }

  assert {
    condition     = contains(local.encriptadores["storage"], "serviceAccount:service-333333333333@gs-project-accounts.iam.gserviceaccount.com")
    error_message = "El agente de Cloud Storage de ai-data debe poder usar su llave."
  }

  assert {
    condition     = contains(local.encriptadores["bigquery"], "serviceAccount:bq-333333333333@bigquery-encryption.iam.gserviceaccount.com")
    error_message = "El agente de BigQuery de ai-data debe poder usar su llave."
  }

  assert {
    condition     = local.encriptadores["secretmanager"] == tolist(["serviceAccount:service-111111111111@gcp-sa-secretmanager.iam.gserviceaccount.com"])
    error_message = "Solo el agente de Secret Manager del proyecto security usa la llave secretmanager."
  }
}

run "secretos_cifrados_con_cmek" {
  command = apply # con mock es simulado, no crea nada

  assert {
    condition = alltrue([
      for s in google_secret_manager_secret.secreto :
      s.replication[0].user_managed[0].replicas[0].customer_managed_encryption[0].kms_key_name == module.kms.llaves["us-central1"]["secretmanager"]
    ])
    error_message = "Cada secreto debe cifrarse con la llave secretmanager de la región principal."
  }

  assert {
    condition     = alltrue([for s in google_secret_manager_secret.secreto : s.replication[0].user_managed[0].replicas[0].location == "us-central1"])
    error_message = "Los secretos solo deben replicarse en la región principal."
  }
}

run "secretos_sin_valor_en_codigo" {
  command = plan

  assert {
    condition     = length(google_secret_manager_secret.secreto) == 2
    error_message = "Se esperan los secretos vpn-psk y huggingface-token."
  }

  assert {
    condition     = google_secret_manager_secret.secreto["vpn-psk"].secret_id == "redesaura-vpn-psk"
    error_message = "El secreto debe llamarse <prefijo>-<nombre>."
  }
}

run "lector_de_secreto" {
  command = plan

  variables {
    secretos = {
      vpn-psk = {
        descripcion = "PSK"
        lectores    = ["serviceAccount:sa-3-networks@redesaura-seed.iam.gserviceaccount.com"]
      }
    }
  }

  assert {
    condition     = google_secret_manager_secret_iam_member.lector["vpn-psk/serviceAccount:sa-3-networks@redesaura-seed.iam.gserviceaccount.com"].role == "roles/secretmanager.secretAccessor"
    error_message = "3-networks debe poder leer la PSK de la VPN."
  }
}

run "perimetro_protege_proyectos_de_ia" {
  command = plan

  assert {
    condition     = length(local.proyectos_perimetro) == 4
    error_message = "El perímetro debe incluir security, ai-platform, ai-data y net-hub."
  }

  assert {
    condition     = alltrue([for n in ["111111111111", "222222222222", "333333333333", "444444444444"] : contains(values(local.proyectos_perimetro), n)])
    error_message = "Falta un proyecto dentro del perímetro."
  }
}

run "perimetro_admite_solo_pipeline" {
  command = plan

  assert {
    condition     = toset(local.identidades_pipeline) == toset(["serviceAccount:sa-2-security@redesaura-seed.iam.gserviceaccount.com", "serviceAccount:sa-5-sandboxes@redesaura-seed.iam.gserviceaccount.com"])
    error_message = "El ingreso debe limitarse a las cuentas de servicio del pipeline."
  }
}

run "perimetro_sin_storage_falla" {
  command = plan

  variables {
    servicios_restringidos = ["aiplatform.googleapis.com", "bigquery.googleapis.com"]
  }

  expect_failures = [var.servicios_restringidos]
}

run "access_policy_existente" {
  command = plan

  variables {
    access_policy_id = "987654321"
  }

  assert {
    condition     = module.vpc_sc.perimetro == "accessPolicies/987654321/servicePerimeters/redesaura_aisbx"
    error_message = "El perímetro debe crearse en la access policy existente."
  }
}

run "cmek_obligatorio_por_politica" {
  command = plan

  assert {
    condition     = alltrue([for s in ["storage.googleapis.com", "bigquery.googleapis.com", "compute.googleapis.com", "aiplatform.googleapis.com"] : contains(google_org_policy_policy.cmek_obligatorio.spec[0].rules[0].values[0].denied_values, s)])
    error_message = "La política debe exigir CMEK en buckets, BigQuery, discos y Vertex AI."
  }

  assert {
    condition     = google_org_policy_policy.cmek_obligatorio.parent == "folders/555555555555"
    error_message = "La política CMEK debe aplicarse a la carpeta ai-sandbox."
  }

  assert {
    condition     = google_org_policy_policy.cmek_solo_proyecto_seguridad.spec[0].rules[0].values[0].allowed_values == tolist(["under:projects/redesaura-security"])
    error_message = "Las llaves CMEK solo pueden venir del proyecto security."
  }
}

run "firewall_niega_todo_al_final" {
  command = plan

  assert {
    condition     = local.reglas_base["deny-egreso-todo"].accion == "deny" && local.reglas_base["deny-egreso-todo"].prioridad == 65000
    error_message = "Debe existir un deny de egreso a 0.0.0.0/0 con la menor prioridad."
  }

  assert {
    condition     = local.reglas_base["deny-ingreso-todo"].accion == "deny" && local.reglas_base["deny-ingreso-todo"].rangos_origen == ["0.0.0.0/0"]
    error_message = "Debe existir un deny de ingreso desde Internet."
  }
}

run "firewall_salida_solo_a_dominios_permitidos" {
  command = plan

  assert {
    condition     = contains(local.reglas_base["allow-egreso-dominios-permitidos"].fqdns_destino, "pypi.org") && contains(local.reglas_base["allow-egreso-dominios-permitidos"].fqdns_destino, "huggingface.co")
    error_message = "La lista de salida debe incluir PyPI y Hugging Face."
  }

  assert {
    condition     = local.reglas_base["allow-egreso-dominios-permitidos"].prioridad < local.reglas_base["deny-egreso-todo"].prioridad
    error_message = "La lista de dominios debe evaluarse antes del deny final."
  }
}

run "firewall_bloquea_produccion" {
  command = plan

  variables {
    rangos_produccion = ["10.200.0.0/16"]
  }

  assert {
    condition     = local.reglas_produccion["deny-egreso-produccion"].rangos_destino == tolist(["10.200.0.0/16"])
    error_message = "El egreso hacia producción debe estar bloqueado."
  }

  assert {
    condition     = local.reglas_produccion["deny-egreso-produccion"].prioridad < local.reglas_base["delegar-egreso-interno"].prioridad
    error_message = "El bloqueo a producción debe evaluarse antes que el tráfico interno."
  }
}

run "region_no_permitida_falla" {
  command = plan

  variables {
    ubicaciones_kms = ["us-central1", "europe-west1"]
  }

  expect_failures = [var.ubicaciones_kms]
}
