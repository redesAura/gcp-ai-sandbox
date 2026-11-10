output "id" {
  description = "ID de la política de firewall"
  value       = google_compute_firewall_policy.politica.id
}

output "nombre" {
  description = "Nombre (ID numérico) de la política de firewall"
  value       = google_compute_firewall_policy.politica.name
}
