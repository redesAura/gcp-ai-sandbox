mock_provider "google" {}

variables {
  proyecto    = "redesaura-security"
  nombre      = "redesaura-cmek"
  ubicaciones = ["us-central1", "us-east4"]
  llaves      = ["storage", "bigquery"]

  encriptadores = {
    storage = ["serviceAccount:service-1@gs-project-accounts.iam.gserviceaccount.com"]
  }
}

run "un_anillo_por_ubicacion" {
  command = plan

  assert {
    condition     = length(google_kms_key_ring.anillo) == 2
    error_message = "Debe haber un key ring por ubicación."
  }

  assert {
    condition     = length(google_kms_crypto_key.llave) == 4
    error_message = "Cada key ring debe tener todas las llaves."
  }
}

run "llaves_rotan_cada_90_dias" {
  command = plan

  assert {
    condition     = alltrue([for l in google_kms_crypto_key.llave : l.rotation_period == "7776000s"])
    error_message = "Las llaves deben rotar cada 90 días."
  }

  assert {
    condition     = alltrue([for l in google_kms_crypto_key.llave : l.version_template[0].protection_level == "SOFTWARE"])
    error_message = "El nivel de protección por defecto debe ser SOFTWARE."
  }
}

run "encriptador_en_cada_ubicacion" {
  command = plan

  assert {
    condition     = length(google_kms_crypto_key_iam_member.encriptador) == 2
    error_message = "El encriptador debe recibir la llave storage en ambas ubicaciones."
  }

  assert {
    condition     = alltrue([for m in google_kms_crypto_key_iam_member.encriptador : m.role == "roles/cloudkms.cryptoKeyEncrypterDecrypter"])
    error_message = "Solo se otorga cryptoKeyEncrypterDecrypter."
  }
}

run "rotacion_mayor_a_90_dias_falla" {
  command = plan

  variables {
    rotacion = "31536000s"
  }

  expect_failures = [var.rotacion]
}

run "encriptador_de_llave_inexistente_falla" {
  command = plan

  variables {
    encriptadores = {
      pubsub = ["serviceAccount:x@example.com"]
    }
  }

  expect_failures = [var.encriptadores]
}

run "salida_por_ubicacion" {
  command = apply # con mock es simulado, no crea nada

  assert {
    condition     = output.llaves["us-east4"]["bigquery"] == google_kms_crypto_key.llave["us-east4/bigquery"].id
    error_message = "La salida debe agrupar las llaves por ubicación y nombre."
  }
}
