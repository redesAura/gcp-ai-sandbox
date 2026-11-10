mock_provider "google" {
  mock_resource "google_logging_organization_sink" {
    defaults = {
      writer_identity = "serviceAccount:o123456789012-000000@gcp-sa-logging.iam.gserviceaccount.com"
    }
  }
}
mock_provider "google-beta" {}

variables {
  org_id          = "123456789012"
  billing_account = "ABCDEF-123456-ABCDEF"
  prefijo_empresa = "redesaura"
  dominio         = "empresa.com"
  grupos = {
    plataforma  = "gcp-plataforma@empresa.com"
    seguridad   = "gcp-seguridad@empresa.com"
    auditoria   = "gcp-auditoria@empresa.com"
    facturacion = "gcp-facturacion@empresa.com"
  }
}

run "carpetas_bajo_la_organizacion" {
  command = plan

  assert {
    condition     = google_folder.common.parent == "organizations/123456789012" && google_folder.ai_sandbox.parent == "organizations/123456789012"
    error_message = "Las carpetas common y ai-sandbox deben colgar directo de la organización."
  }

  assert {
    condition     = google_folder.ai_sandbox.display_name == "ai-sandbox"
    error_message = "La carpeta de sandboxes debe llamarse ai-sandbox."
  }
}

run "proyectos_de_common" {
  command = plan

  assert {
    condition     = toset(keys(google_project.common)) == toset(["net-hub", "logging", "security"])
    error_message = "common debe tener los proyectos net-hub, logging y security."
  }

  assert {
    condition     = google_project.common["net-hub"].project_id == "redesaura-net-hub"
    error_message = "Los proyectos deben usar el prefijo de la empresa."
  }

  assert {
    condition     = alltrue([for p in google_project.common : p.auto_create_network == false])
    error_message = "Ningún proyecto debe crear la red default."
  }

  assert {
    condition = alltrue([
      for p in google_project.common : alltrue([
        for k in ["team", "owner", "cost_center", "expires", "managed_by"] : contains(keys(p.labels), k)
      ])
    ])
    error_message = "Los proyectos deben llevar las etiquetas obligatorias."
  }
}

run "sin_llaves_de_cuentas_de_servicio" {
  command = plan

  assert {
    condition     = google_org_policy_policy.booleana["iam.disableServiceAccountKeyCreation"].spec[0].rules[0].enforce == "TRUE"
    error_message = "La creación de llaves de cuentas de servicio debe estar bloqueada."
  }

  assert {
    condition     = google_org_policy_policy.booleana["iam.disableServiceAccountKeyUpload"].spec[0].rules[0].enforce == "TRUE"
    error_message = "La carga de llaves de cuentas de servicio debe estar bloqueada."
  }
}

run "solo_regiones_permitidas" {
  command = plan

  assert {
    condition     = toset(google_org_policy_policy.regiones_permitidas.spec[0].rules[0].values[0].allowed_values) == toset(["in:us-central1-locations", "in:us-east4-locations"])
    error_message = "Solo deben permitirse us-central1 y us-east4."
  }
}

run "sin_ip_publicas" {
  command = plan

  assert {
    condition     = google_org_policy_policy.sin_ip_publica_vm.spec[0].rules[0].deny_all == "TRUE"
    error_message = "Las VM no deben tener IP pública."
  }

  assert {
    condition     = google_org_policy_policy.booleana["sql.restrictPublicIp"].spec[0].rules[0].enforce == "TRUE"
    error_message = "Cloud SQL no debe tener IP pública."
  }
}

run "sandbox_aislado_y_con_cmek" {
  command = apply # con mock es simulado, no crea nada

  assert {
    condition     = google_org_policy_policy.sandbox_cmek_obligatorio.parent == google_folder.ai_sandbox.name
    error_message = "La política de CMEK debe aplicarse a la carpeta ai-sandbox."
  }

  assert {
    condition     = contains(google_org_policy_policy.sandbox_cmek_obligatorio.spec[0].rules[0].values[0].denied_values, "aiplatform.googleapis.com")
    error_message = "Vertex AI debe requerir CMEK en ai-sandbox."
  }

  assert {
    condition     = google_org_policy_policy.sandbox_llaves_de_security.spec[0].rules[0].values[0].allowed_values == tolist(["under:projects/redesaura-security"])
    error_message = "Las llaves CMEK solo pueden venir del proyecto security."
  }

  assert {
    condition     = google_org_policy_policy.sandbox_vpc_compartida.spec[0].rules[0].values[0].allowed_values == tolist(["under:${google_folder.common.name}", "under:${google_folder.ai_sandbox.name}"])
    error_message = "Los sandboxes solo pueden usar Shared VPC de common o ai-sandbox."
  }
}

run "logs_de_auditoria_centralizados" {
  command = apply

  assert {
    condition     = google_logging_organization_sink.auditoria.include_children == true
    error_message = "El sink debe incluir todos los proyectos de la organización."
  }

  assert {
    condition     = google_logging_organization_sink.auditoria.destination == "logging.googleapis.com/${google_logging_project_bucket_config.auditoria.id}"
    error_message = "El sink debe escribir en el bucket de logs del proyecto logging."
  }

  assert {
    condition     = google_project_iam_member.sink_escribe_logs.member == google_logging_organization_sink.auditoria.writer_identity
    error_message = "La identidad del sink debe poder escribir en el bucket."
  }

  assert {
    condition     = google_logging_project_bucket_config.auditoria.project == "redesaura-logging"
    error_message = "Los logs deben guardarse en el proyecto logging."
  }
}

run "contactos_esenciales" {
  command = plan

  assert {
    condition     = contains(google_essential_contacts_contact.org["gcp-seguridad@empresa.com"].notification_category_subscriptions, "SECURITY")
    error_message = "El grupo de seguridad debe recibir las notificaciones de seguridad."
  }

  assert {
    condition     = google_org_policy_policy.contactos_del_dominio.spec[0].rules[0].values[0].allowed_values == tolist(["@empresa.com"])
    error_message = "Los contactos solo pueden ser del dominio de la empresa."
  }
}

run "restriccion_de_dominio_opcional" {
  command = plan

  assert {
    condition     = length(google_org_policy_policy.dominios_iam) == 0
    error_message = "Sin IDs de cliente no debe crearse la restricción de dominio."
  }
}

run "restriccion_de_dominio_activa" {
  command = plan

  variables {
    ids_cliente_permitidos = ["C0abc1234"]
  }

  assert {
    condition     = google_org_policy_policy.dominios_iam[0].spec[0].rules[0].values[0].allowed_values == tolist(["C0abc1234"])
    error_message = "La restricción de dominio debe usar los IDs de cliente."
  }
}

run "scc_desactivable" {
  command = plan

  variables {
    habilitar_scc = false
  }

  assert {
    condition     = length(google_scc_v2_organization_notification_config.hallazgos_activos) == 0
    error_message = "Con habilitar_scc = false no debe crearse la notificación de SCC."
  }
}

run "perfiles_sin_permisos_de_iam" {
  command = plan

  assert {
    condition = alltrue([
      for perfil in ["cientifico_datos", "ingeniero_ml"] : alltrue([
        for rol in output.roles_por_perfil[perfil] : !contains(["roles/owner", "roles/editor", "roles/resourcemanager.projectIamAdmin", "roles/compute.networkAdmin"], rol)
      ])
    ])
    error_message = "Científicos e ingenieros ML no deben poder cambiar IAM ni crear redes."
  }
}

run "org_id_invalido_falla" {
  command = plan

  variables {
    org_id = "abc123"
  }

  expect_failures = [var.org_id]
}

run "region_no_permitida_falla" {
  command = plan

  variables {
    regiones_permitidas = ["europe-west1"]
  }

  expect_failures = [var.regiones_permitidas]
}

run "grupo_invalido_falla" {
  command = plan

  variables {
    grupos = {
      plataforma  = "no-es-correo"
      seguridad   = "gcp-seguridad@empresa.com"
      auditoria   = "gcp-auditoria@empresa.com"
      facturacion = "gcp-facturacion@empresa.com"
    }
  }

  expect_failures = [var.grupos]
}
