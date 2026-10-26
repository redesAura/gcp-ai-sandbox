resource "google_storage_bucket" "estado" {
  name                        = "${var.prefijo_empresa}-aisbx-tfstate"
  project                     = google_project.seed.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  labels                      = local.etiquetas

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.estado.id
  }

  depends_on = [google_kms_crypto_key_iam_member.gcs_usa_llave]
}