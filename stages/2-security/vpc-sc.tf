module "vpc_sc" {
  source = "../../modules/vpc-sc"

  org_id                 = var.org_id
  access_policy_id       = var.access_policy_id
  nombre                 = "${var.prefijo_empresa}_aisbx"
  descripcion            = "Perímetro de los proyectos de IA, datos y seguridad"
  recursos               = local.proyectos_perimetro
  servicios_restringidos = var.servicios_restringidos
  rangos_ip_permitidos   = var.rangos_ip_corporativos
  modo_prueba            = var.vpc_sc_modo_prueba

  reglas_ingreso = {
    pipeline-terraform = {
      identidades    = local.identidades_pipeline
      niveles_acceso = ["*"]
    }
  }
}
