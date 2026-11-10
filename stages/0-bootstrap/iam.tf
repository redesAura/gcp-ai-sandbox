locals {
  roles_por_etapa = {
    "1-org" = [
      "roles/resourcemanager.folderAdmin",
      "roles/orgpolicy.policyAdmin",
      "roles/logging.configWriter",
      "roles/resourcemanager.projectCreator",
      "roles/billing.user",
      "roles/iam.securityAdmin",
      "roles/securitycenter.notificationConfigEditor",
      "roles/essentialcontacts.admin",
      "roles/resourcemanager.tagAdmin",
      "roles/resourcemanager.tagUser",
    ]
    "2-security" = [
      "roles/cloudkms.admin",
      "roles/accesscontextmanager.policyAdmin",
      "roles/secretmanager.admin",
      "roles/compute.orgFirewallPolicyAdmin",
      "roles/compute.orgSecurityResourceAdmin",
    ]
    "3-networks"    = ["roles/compute.xpnAdmin", "roles/compute.networkAdmin", "roles/compute.securityAdmin"]
    "4-ai-platform" = ["roles/resourcemanager.projectCreator", "roles/aiplatform.admin", "roles/container.admin"]
    "5-sandboxes"   = ["roles/resourcemanager.projectCreator", "roles/billing.user"]
  }

  asignaciones = flatten([
    for etapa, roles in local.roles_por_etapa : [
      for rol in roles : { etapa = etapa, rol = rol }
    ]
  ])
}

resource "google_service_account" "etapa" {
  for_each = toset(var.etapas)

  project      = google_project.seed.project_id
  account_id   = "sa-${each.value}"
  display_name = "Terraform etapa ${each.value}"
}

resource "google_storage_bucket_iam_member" "estado" {
  for_each = google_service_account.etapa

  bucket = google_storage_bucket.estado.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${each.value.email}"

  condition {
    title      = "solo-prefijo-${each.key}"
    expression = "resource.name == \"projects/_/buckets/${google_storage_bucket.estado.name}\" || resource.name.startsWith(\"projects/_/buckets/${google_storage_bucket.estado.name}/objects/${each.key}/\")"
  }
}

resource "google_organization_iam_member" "etapa" {
  for_each = { for a in local.asignaciones : "${a.etapa}/${a.rol}" => a }

  org_id = var.org_id
  role   = each.value.rol
  member = "serviceAccount:${google_service_account.etapa[each.value.etapa].email}"
}