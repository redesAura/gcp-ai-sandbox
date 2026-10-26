mock_provider "google" {
  mock_resource "google_service_account" {
    defaults = {
      name  = "projects/redesaura-seed/serviceAccounts/sa-mock@redesaura-seed.iam.gserviceaccount.com"
      email = "sa-mock@redesaura-seed.iam.gserviceaccount.com"
    }
  }
}
mock_provider "google-beta" {}

variables {
  org_id          = "123456789012"
  billing_account = "ABCDEF-123456-ABCDEF"
  prefijo_empresa = "redesaura"
  github_org      = "redesAura"
  github_repo     = "gcp-ai-sandbox"
}

run "bucket_tiene_versionado" {
  command = plan

  assert {
    condition     = google_storage_bucket.estado.versioning[0].enabled == true
    error_message = "El bucket de estado debe tener versionado."
  }
}

run "bucket_sin_acceso_publico" {
  command = plan

  assert {
    condition     = google_storage_bucket.estado.public_access_prevention == "enforced"
    error_message = "El bucket de estado no debe ser público."
  }

  assert {
    condition     = google_storage_bucket.estado.uniform_bucket_level_access == true
    error_message = "El bucket debe usar acceso uniforme."
  }
}

run "una_sa_por_etapa" {
  command = plan

  assert {
    condition     = length(google_service_account.etapa) == 5
    error_message = "Debe existir una cuenta de servicio por cada una de las 5 etapas."
  }
}

run "wif_solo_este_repo" {
  command = plan

  assert {
    condition     = google_iam_workload_identity_pool_provider.github.attribute_condition == "assertion.repository == \"redesAura/gcp-ai-sandbox\""
    error_message = "El proveedor de WIF solo debe aceptar este repositorio."
  }
}

run "org_id_invalido_falla" {
  command = plan

  variables {
    org_id = "abc123"
  }

  expect_failures = [var.org_id]
}

run "bucket_usa_cmek" {
  command = apply # con mock es simulado, no crea nada

  assert {
    condition     = google_storage_bucket.estado.encryption[0].default_kms_key_name == google_kms_crypto_key.estado.id
    error_message = "El bucket debe cifrarse con la llave de KMS."
  }
}