locals {
  roles_org_por_grupo = {
    plataforma = [
      "roles/resourcemanager.organizationViewer",
      "roles/resourcemanager.folderViewer",
      "roles/orgpolicy.policyViewer",
      "roles/iam.securityReviewer",
    ]
    seguridad = [
      "roles/iam.securityReviewer",
      "roles/securitycenter.adminViewer",
      "roles/orgpolicy.policyViewer",
    ]
    facturacion = [
      "roles/billing.viewer",
    ]
  }

  roles_logging_por_grupo = {
    plataforma  = ["roles/logging.viewer"]
    seguridad   = ["roles/logging.privateLogViewer"]
    auditoria   = ["roles/logging.viewer", "roles/logging.privateLogViewer", "roles/bigquery.user"]
    facturacion = ["roles/bigquery.user"]
  }

  roles_facturacion_por_grupo = {
    facturacion = ["roles/bigquery.dataViewer"]
  }

  # Roles que 5-sandboxes asigna a los grupos de cada equipo dentro de su proyecto aisbx-<equipo>
  roles_por_perfil = {
    cientifico_datos = [
      "roles/aiplatform.user",
      "roles/notebooks.admin",
      "roles/bigquery.user",
      "roles/storage.objectUser",
      "roles/artifactregistry.reader",
      "roles/iam.serviceAccountUser",
      "roles/logging.viewer",
      "roles/monitoring.viewer",
    ]
    ingeniero_ml = [
      "roles/aiplatform.user",
      "roles/notebooks.admin",
      "roles/bigquery.user",
      "roles/storage.objectUser",
      "roles/artifactregistry.writer",
      "roles/iam.serviceAccountUser",
      "roles/container.clusterAdmin",
      "roles/container.developer",
      "roles/logging.viewer",
      "roles/monitoring.viewer",
    ]
    lider_equipo = [
      "roles/browser",
      "roles/aiplatform.viewer",
      "roles/logging.viewer",
      "roles/monitoring.viewer",
    ]
    revisor = [
      "roles/browser",
      "roles/aiplatform.viewer",
      "roles/logging.viewer",
      "roles/monitoring.viewer",
    ]
  }

  asignaciones_org         = flatten([for g, roles in local.roles_org_por_grupo : [for r in roles : { grupo = g, rol = r }]])
  asignaciones_logging     = flatten([for g, roles in local.roles_logging_por_grupo : [for r in roles : { grupo = g, rol = r }]])
  asignaciones_facturacion = flatten([for g, roles in local.roles_facturacion_por_grupo : [for r in roles : { grupo = g, rol = r }]])
}

resource "google_organization_iam_member" "grupos" {
  for_each = { for a in local.asignaciones_org : "${a.grupo}/${a.rol}" => a }

  org_id = var.org_id
  role   = each.value.rol
  member = "group:${var.grupos[each.value.grupo]}"
}

resource "google_project_iam_member" "grupos" {
  for_each = { for a in local.asignaciones_logging : "${a.grupo}/${a.rol}" => a }

  project = local.proyecto_logging
  role    = each.value.rol
  member  = "group:${var.grupos[each.value.grupo]}"
}

resource "google_bigquery_dataset_iam_member" "grupos" {
  for_each = { for a in local.asignaciones_facturacion : "${a.grupo}/${a.rol}" => a }

  project    = local.proyecto_logging
  dataset_id = google_bigquery_dataset.facturacion.dataset_id
  role       = each.value.rol
  member     = "group:${var.grupos[each.value.grupo]}"
}
