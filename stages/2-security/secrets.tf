resource "google_secret_manager_secret" "secreto" {
  for_each = var.secretos

  project             = var.proyecto_seguridad.id
  secret_id           = "${var.prefijo_empresa}-${each.key}"
  labels              = local.etiquetas
  annotations         = { descripcion = each.value.descripcion }
  deletion_protection = true

  replication {
    user_managed {
      replicas {
        location = var.region
        customer_managed_encryption {
          kms_key_name = module.kms.llaves[var.region]["secretmanager"]
        }
      }
    }
  }

  depends_on = [module.kms]
}

resource "google_secret_manager_secret_iam_member" "lector" {
  for_each = {
    for par in flatten([
      for secreto, config in var.secretos : [
        for lector in config.lectores : { secreto = secreto, lector = lector }
      ]
    ]) : "${par.secreto}/${par.lector}" => par
  }

  project   = var.proyecto_seguridad.id
  secret_id = google_secret_manager_secret.secreto[each.value.secreto].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = each.value.lector
}
