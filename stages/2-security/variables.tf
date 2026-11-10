variable "org_id" {
  description = "ID numérico de la organización de GCP"
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.org_id))
    error_message = "org_id debe contener solo dígitos."
  }
}

variable "prefijo_empresa" {
  description = "Prefijo corto para nombrar recursos"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{2,9}$", var.prefijo_empresa))
    error_message = "Usa de 3 a 10 caracteres en minúsculas, empezando con letra."
  }
}

variable "region" {
  description = "Región principal"
  type        = string
  default     = "us-central1"

  validation {
    condition     = contains(["us-central1", "us-east4"], var.region)
    error_message = "Solo se permiten us-central1 y us-east4."
  }
}

variable "ubicaciones_kms" {
  description = "Regiones con key ring; la alterna existe para cómputo con GPU en us-east4"
  type        = list(string)
  default     = ["us-central1", "us-east4"]

  validation {
    condition     = length(var.ubicaciones_kms) > 0 && alltrue([for u in var.ubicaciones_kms : contains(["us-central1", "us-east4"], u)])
    error_message = "Solo se permiten us-central1 y us-east4."
  }

  validation {
    condition     = contains(var.ubicaciones_kms, var.region)
    error_message = "ubicaciones_kms debe incluir la región principal."
  }
}

variable "proyecto_seguridad" {
  description = "Proyecto security de la carpeta common, creado en 1-org"
  type = object({
    id     = string
    numero = string
  })

  validation {
    condition     = can(regex("^[0-9]+$", var.proyecto_seguridad.numero))
    error_message = "proyecto_seguridad.numero debe contener solo dígitos."
  }
}

variable "proyectos_ia" {
  description = "Proyectos de la carpeta ai-sandbox que usan CMEK y quedan dentro del perímetro (nombre => número de proyecto)"
  type        = map(string)

  validation {
    condition     = alltrue([for numero in values(var.proyectos_ia) : can(regex("^[0-9]+$", numero))])
    error_message = "Los valores deben ser números de proyecto."
  }
}

variable "proyectos_perimetro_extra" {
  description = "Otros proyectos dentro del perímetro sin llaves propias, por ejemplo net-hub (nombre => número)"
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for numero in values(var.proyectos_perimetro_extra) : can(regex("^[0-9]+$", numero))])
    error_message = "Los valores deben ser números de proyecto."
  }
}

variable "carpeta_ai_sandbox" {
  description = "Carpeta ai-sandbox creada en 1-org, formato folders/<id>"
  type        = string

  validation {
    condition     = can(regex("^folders/[0-9]+$", var.carpeta_ai_sandbox))
    error_message = "carpeta_ai_sandbox debe tener el formato folders/<id>."
  }
}

variable "cuentas_pipeline" {
  description = "Correos de las cuentas de servicio de las etapas (salida cuentas_por_etapa de 0-bootstrap)"
  type        = map(string)
}

variable "encriptadores_adicionales" {
  description = "Miembros extra por llave, por ejemplo la cuenta de Cloud Logging para la llave logging"
  type        = map(list(string))
  default     = {}
}

variable "rotacion_llaves" {
  description = "Periodo de rotación de las llaves"
  type        = string
  default     = "7776000s" # 90 días
}

variable "secretos" {
  description = "Secretos a crear; el valor se carga fuera de Terraform. lectores recibe secretAccessor"
  type = map(object({
    descripcion = string
    lectores    = optional(list(string), [])
  }))
  default = {
    vpn-psk = {
      descripcion = "Llave precompartida del túnel HA VPN hacia on-premises"
    }
    huggingface-token = {
      descripcion = "Token de lectura de Hugging Face para descargar modelos abiertos"
    }
  }
}

variable "access_policy_id" {
  description = "Access policy existente de la organización; null crea una nueva"
  type        = string
  default     = null
}

variable "vpc_sc_modo_prueba" {
  description = "true deja el perímetro en dry-run (solo registra violaciones)"
  type        = bool
  default     = false
}

variable "rangos_ip_corporativos" {
  description = "IPs públicas corporativas que pueden llegar a las APIs del perímetro"
  type        = list(string)
  default     = []
}

variable "servicios_restringidos" {
  description = "APIs protegidas por VPC Service Controls"
  type        = list(string)
  default = [
    "aiplatform.googleapis.com",
    "alloydb.googleapis.com",
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "containerregistry.googleapis.com",
    "datacatalog.googleapis.com",
    "dataflow.googleapis.com",
    "dataplex.googleapis.com",
    "discoveryengine.googleapis.com",
    "dlp.googleapis.com",
    "logging.googleapis.com",
    "modelarmor.googleapis.com",
    "monitoring.googleapis.com",
    "notebooks.googleapis.com",
    "pubsub.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "sqladmin.googleapis.com",
    "storage.googleapis.com",
    "tpu.googleapis.com",
  ]

  validation {
    condition     = alltrue([for s in ["storage.googleapis.com", "bigquery.googleapis.com", "aiplatform.googleapis.com"] : contains(var.servicios_restringidos, s)])
    error_message = "El perímetro debe restringir al menos Cloud Storage, BigQuery y Vertex AI."
  }
}

variable "servicios_cmek" {
  description = "Servicios que la política de organización obliga a usar CMEK en la carpeta ai-sandbox"
  type        = list(string)
  default = [
    "aiplatform.googleapis.com",
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "dataflow.googleapis.com",
    "notebooks.googleapis.com",
    "pubsub.googleapis.com",
    "secretmanager.googleapis.com",
    "storage.googleapis.com",
  ]

  validation {
    condition     = alltrue([for s in ["storage.googleapis.com", "bigquery.googleapis.com", "compute.googleapis.com", "aiplatform.googleapis.com"] : contains(var.servicios_cmek, s)])
    error_message = "CMEK debe ser obligatorio al menos en buckets, BigQuery, discos y Vertex AI."
  }
}

variable "rangos_internos" {
  description = "Rangos privados de la Shared VPC y de on-premises"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "rangos_produccion" {
  description = "Rangos de los entornos productivos; se bloquean en ambos sentidos"
  type        = list(string)
  default     = []
}

variable "dominios_permitidos" {
  description = "Dominios a los que los sandboxes pueden salir por HTTPS"
  type        = list(string)
  default = [
    "pypi.org",
    "files.pythonhosted.org",
    "huggingface.co",
    "cdn-lfs.huggingface.co",
    "cdn-lfs-us-1.hf.co",
    "github.com",
    "codeload.github.com",
    "objects.githubusercontent.com",
    "conda.anaconda.org",
    "repo.anaconda.com",
  ]

  validation {
    condition     = length(var.dominios_permitidos) <= 100
    error_message = "Una regla de firewall admite como máximo 100 FQDN."
  }
}

variable "owner" {
  description = "Dueño de los recursos (etiqueta)"
  type        = string
  default     = "plataforma"
}

variable "cost_center" {
  description = "Centro de costos (etiqueta)"
  type        = string
  default     = "ti-ia"
}
