output "anillos" {
  description = "ID del key ring por ubicación"
  value       = { for ubicacion, anillo in google_kms_key_ring.anillo : ubicacion => anillo.id }
}

output "llaves" {
  description = "ID de cada llave, agrupado por ubicación y luego por nombre"
  value = {
    for ubicacion in var.ubicaciones : ubicacion => {
      for llave in var.llaves : llave => google_kms_crypto_key.llave["${ubicacion}/${llave}"].id
    }
  }
}
