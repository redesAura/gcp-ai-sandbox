resource "google_org_policy_policy" "cmek_obligatorio" {
  name   = "${var.carpeta_ai_sandbox}/policies/gcp.restrictNonCmekServices"
  parent = var.carpeta_ai_sandbox

  spec {
    rules {
      values {
        denied_values = var.servicios_cmek
      }
    }
  }
}

resource "google_org_policy_policy" "cmek_solo_proyecto_seguridad" {
  name   = "${var.carpeta_ai_sandbox}/policies/gcp.restrictCmekCryptoKeyProjects"
  parent = var.carpeta_ai_sandbox

  spec {
    rules {
      values {
        allowed_values = ["under:projects/${var.proyecto_seguridad.id}"]
      }
    }
  }
}
