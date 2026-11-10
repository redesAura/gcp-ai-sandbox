locals {
  etiquetas = {
    team        = "plataforma"
    owner       = var.owner
    cost_center = var.cost_center
    expires     = "never"
    managed_by  = "terraform"
  }

  # Agentes de servicio que cifran con CMEK en cada proyecto de IA; %s es el número de proyecto
  agentes = {
    storage          = ["service-%s@gs-project-accounts.iam.gserviceaccount.com"]
    bigquery         = ["bq-%s@bigquery-encryption.iam.gserviceaccount.com"]
    compute          = ["service-%s@compute-system.iam.gserviceaccount.com", "service-%s@container-engine-robot.iam.gserviceaccount.com", "service-%s@gcp-sa-notebooks.iam.gserviceaccount.com"]
    aiplatform       = ["service-%s@gcp-sa-aiplatform.iam.gserviceaccount.com"]
    artifactregistry = ["service-%s@gcp-sa-artifactregistry.iam.gserviceaccount.com"]
    pubsub           = ["service-%s@gcp-sa-pubsub.iam.gserviceaccount.com"]
    dataflow         = ["service-%s@dataflow-service-producer-prod.iam.gserviceaccount.com", "service-%s@compute-system.iam.gserviceaccount.com"]
  }

  llaves = concat(keys(local.agentes), ["secretmanager", "logging"])

  encriptadores_ia = {
    for llave, plantillas in local.agentes : llave => distinct(flatten([
      for numero in values(var.proyectos_ia) : [
        for plantilla in plantillas : "serviceAccount:${format(plantilla, numero)}"
      ]
    ]))
  }

  encriptadores = {
    for llave in local.llaves : llave => distinct(concat(
      lookup(local.encriptadores_ia, llave, []),
      llave == "secretmanager" ? ["serviceAccount:service-${var.proyecto_seguridad.numero}@gcp-sa-secretmanager.iam.gserviceaccount.com"] : [],
      lookup(var.encriptadores_adicionales, llave, []),
    ))
  }

  identidades_pipeline = [for correo in values(var.cuentas_pipeline) : "serviceAccount:${correo}"]

  proyectos_perimetro = merge(
    { security = var.proyecto_seguridad.numero },
    var.proyectos_ia,
    var.proyectos_perimetro_extra,
  )
}
