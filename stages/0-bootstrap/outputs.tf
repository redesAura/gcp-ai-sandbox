output "proyecto_semilla" {
  value = google_project.seed.project_id
}

output "bucket_estado" {
  value = google_storage_bucket.estado.name
}

output "cuentas_por_etapa" {
  value = { for etapa, sa in google_service_account.etapa : etapa => sa.email }
}

output "proveedor_wif" {
  value = google_iam_workload_identity_pool_provider.github.name
}