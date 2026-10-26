locals {
  seed_project_id = "${var.prefijo_empresa}-seed"

  etiquetas = {
    team        = "plataforma"
    owner       = var.owner
    cost_center = var.cost_center
    expires     = "never"
    managed_by  = "terraform"
  }
}

resource "google_folder" "bootstrap" {
  display_name = "bootstrap"
  parent       = "organizations/${var.org_id}"
}

resource "google_project" "seed" {
  name                = local.seed_project_id
  project_id          = local.seed_project_id
  folder_id           = google_folder.bootstrap.name
  billing_account     = var.billing_account
  labels              = local.etiquetas
  auto_create_network = false
}

resource "google_project_service" "apis" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "storage.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudbilling.googleapis.com",
    "serviceusage.googleapis.com",
  ])

  project            = google_project.seed.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_project_iam_audit_config" "seed" {
  project = google_project.seed.project_id
  service = "allServices"

  audit_log_config {
    log_type = "ADMIN_READ"
  }
  audit_log_config {
    log_type = "DATA_READ"
  }
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}
