output "llaves_cmek" {
  description = "ID de las llaves por región y servicio, para usar en las etapas 3 a 5"
  value       = module.kms.llaves
}

output "secretos" {
  description = "ID de cada secreto de Secret Manager"
  value       = { for nombre, secreto in google_secret_manager_secret.secreto : nombre => secreto.id }
}

output "access_policy_id" {
  description = "Access policy de la organización"
  value       = module.vpc_sc.access_policy_id
}

output "perimetro_vpc_sc" {
  description = "Perímetro al que 5-sandboxes agrega cada proyecto aisbx-<equipo>"
  value       = module.vpc_sc.perimetro
}

output "politica_firewall" {
  description = "Política de firewall jerárquica asociada a ai-sandbox"
  value       = module.firewall.id
}
