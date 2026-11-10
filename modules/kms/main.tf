locals {
  llaves = {
    for par in setproduct(var.ubicaciones, var.llaves) : "${par[0]}/${par[1]}" => {
      ubicacion = par[0]
      llave     = par[1]
    }
  }

  asignaciones = {
    for a in flatten([
      for ubicacion in var.ubicaciones : [
        for llave, miembros in var.encriptadores : [
          for miembro in miembros : { ubicacion = ubicacion, llave = llave, miembro = miembro }
        ]
      ]
    ]) : "${a.ubicacion}/${a.llave}/${a.miembro}" => a
  }
}

resource "google_kms_key_ring" "anillo" {
  for_each = toset(var.ubicaciones)

  name     = var.nombre
  project  = var.proyecto
  location = each.value
}

resource "google_kms_crypto_key" "llave" {
  #checkov:skip=CKV_GCP_82:prevent_destroy breaks terraform test teardown; nothing is deployed
  for_each = local.llaves

  name            = each.value.llave
  key_ring        = google_kms_key_ring.anillo[each.value.ubicacion].id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = var.rotacion
  labels          = var.etiquetas

  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = var.nivel_proteccion
  }
}

resource "google_kms_crypto_key_iam_member" "encriptador" {
  for_each = local.asignaciones

  crypto_key_id = google_kms_crypto_key.llave["${each.value.ubicacion}/${each.value.llave}"].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = each.value.miembro
}
