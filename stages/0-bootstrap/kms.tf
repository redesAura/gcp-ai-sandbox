resource "google_kms_key_ring" "estado" {
  name     = "${var.prefijo_empresa}-tfstate"
  project  = google_project.seed.project_id
  location = var.region

  depends_on = [google_project_service.apis]
}

resource "google_kms_crypto_key" "estado" {
  name            = "tfstate"
  key_ring        = google_kms_key_ring.estado.id
  rotation_period = "7776000s" # 90 días
  labels          = local.etiquetas
}

data "google_storage_project_service_account" "gcs" {
  project = google_project.seed.project_id
}

resource "google_kms_crypto_key_iam_member" "gcs_usa_llave" {
  crypto_key_id = google_kms_crypto_key.estado.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_storage_project_service_account.gcs.email_address}"
}