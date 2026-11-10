output "access_policy_id" {
  description = "ID de la access policy usada por el perímetro"
  value       = local.politica
}

output "perimetro" {
  description = "Nombre completo del perímetro, para agregar proyectos desde otras etapas"
  value       = google_access_context_manager_service_perimeter.perimetro.name
}

output "nivel_acceso" {
  description = "Nombre del access level corporativo, o null si no hay rangos"
  value       = one(google_access_context_manager_access_level.corporativo[*].name)
}
