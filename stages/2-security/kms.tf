module "kms" {
  source = "../../modules/kms"

  proyecto      = var.proyecto_seguridad.id
  nombre        = "${var.prefijo_empresa}-cmek"
  ubicaciones   = var.ubicaciones_kms
  llaves        = local.llaves
  rotacion      = var.rotacion_llaves
  encriptadores = local.encriptadores
  etiquetas     = local.etiquetas
}
