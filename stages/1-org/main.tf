locals {
  org = "organizations/${var.org_id}"

  etiquetas = {
    team        = "plataforma"
    owner       = var.owner
    cost_center = var.cost_center
    expires     = "never"
    managed_by  = "terraform"
  }
}

resource "google_folder" "common" {
  display_name = "common"
  parent       = local.org
}

resource "google_folder" "ai_sandbox" {
  display_name = "ai-sandbox"
  parent       = local.org
}
