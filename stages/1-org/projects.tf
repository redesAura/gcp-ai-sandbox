locals {
  proyectos_common = {
    net-hub = [
      "compute.googleapis.com",
      "dns.googleapis.com",
      "networkconnectivity.googleapis.com",
      "servicenetworking.googleapis.com",
      "logging.googleapis.com",
    ]
    logging = [
      "logging.googleapis.com",
      "bigquery.googleapis.com",
      "bigquerydatatransfer.googleapis.com",
    ]
    security = [
      "cloudkms.googleapis.com",
      "secretmanager.googleapis.com",
      "accesscontextmanager.googleapis.com",
      "securitycenter.googleapis.com",
      "pubsub.googleapis.com",
      "dlp.googleapis.com",
      "logging.googleapis.com",
    ]
  }

  apis_common = flatten([
    for proyecto, apis in local.proyectos_common : [
      for api in apis : { proyecto = proyecto, api = api }
    ]
  ])
}

resource "google_project" "common" {
  for_each = local.proyectos_common

  name                = "${var.prefijo_empresa}-${each.key}"
  project_id          = "${var.prefijo_empresa}-${each.key}"
  folder_id           = google_folder.common.name
  billing_account     = var.billing_account
  labels              = local.etiquetas
  auto_create_network = false
}

resource "google_project_service" "common" {
  for_each = { for a in local.apis_common : "${a.proyecto}/${a.api}" => a }

  project            = google_project.common[each.value.proyecto].project_id
  service            = each.value.api
  disable_on_destroy = false
}
