output "carpetas" {
  value = {
    common     = google_folder.common.name
    ai_sandbox = google_folder.ai_sandbox.name
  }
}

output "proyectos" {
  value = { for nombre, p in google_project.common : nombre => p.project_id }
}

# 2-security recibe id y número de security (proyecto_seguridad) y el número de net-hub (proyectos_perimetro_extra)
output "numeros_de_proyecto" {
  value = { for nombre, p in google_project.common : nombre => p.number }
}

output "bucket_logs_auditoria" {
  value = google_logging_project_bucket_config.auditoria.id
}

output "dataset_facturacion" {
  value = google_bigquery_dataset.facturacion.id
}

output "topico_scc" {
  value = var.habilitar_scc ? google_pubsub_topic.scc[0].id : null
}

output "valores_tags" {
  value = { for k, v in google_tags_tag_value.org : k => v.id }
}

output "roles_por_perfil" {
  value = local.roles_por_perfil
}
