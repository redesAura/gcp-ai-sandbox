variable "org_id" {
  description = "ID numérico de la organización de GCP"
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.org_id))
    error_message = "org_id debe contener solo dígitos."
  }
}

variable "billing_account" {
  description = "Cuenta de facturación para los proyectos de common, formato XXXXXX-XXXXXX-XXXXXX"
  type        = string

  validation {
    condition     = can(regex("^[A-Z0-9]{6}-[A-Z0-9]{6}-[A-Z0-9]{6}$", var.billing_account))
    error_message = "billing_account debe tener el formato XXXXXX-XXXXXX-XXXXXX."
  }
}

variable "prefijo_empresa" {
  description = "Prefijo corto para nombrar recursos (el mismo de 0-bootstrap)"
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

variable "regiones_permitidas" {
  description = "Regiones donde se pueden crear recursos (política gcp.resourceLocations)"
  type        = list(string)
  default     = ["us-central1", "us-east4"]

  validation {
    condition     = length(var.regiones_permitidas) > 0 && alltrue([for r in var.regiones_permitidas : contains(["us-central1", "us-east4"], r)])
    error_message = "regiones_permitidas no puede estar vacía y solo acepta us-central1 y us-east4."
  }
}

variable "dominio" {
  description = "Dominio de Cloud Identity de la empresa, sin @ (por ejemplo empresa.com)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$", var.dominio))
    error_message = "dominio debe ser un nombre de dominio válido en minúsculas y sin @."
  }
}

variable "ids_cliente_permitidos" {
  description = "IDs de cliente de Cloud Identity (C0xxxxxxx) aceptados en IAM. Vacío desactiva la restricción de dominio"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.ids_cliente_permitidos : can(regex("^C[0-9a-z]+$", id))])
    error_message = "Cada ID de cliente debe tener el formato C0xxxxxxx."
  }
}

variable "grupos" {
  description = "Correos de los grupos de Cloud Identity de la organización"
  type = object({
    plataforma  = string
    seguridad   = string
    auditoria   = string
    facturacion = string
  })

  validation {
    condition     = alltrue([for g in values(var.grupos) : can(regex("^[a-z0-9._-]+@[a-z0-9.-]+\\.[a-z]+$", g))])
    error_message = "Cada grupo debe ser un correo válido en minúsculas."
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

variable "dias_retencion_logs" {
  description = "Días que se conservan los logs de auditoría centralizados"
  type        = number
  default     = 400

  validation {
    condition     = var.dias_retencion_logs >= 30 && var.dias_retencion_logs <= 3650
    error_message = "dias_retencion_logs debe estar entre 30 y 3650."
  }
}

variable "habilitar_scc" {
  description = "Crea la notificación de Security Command Center hacia Pub/Sub"
  type        = bool
  default     = true
}

variable "idioma_contactos" {
  description = "Idioma de las notificaciones de Essential Contacts"
  type        = string
  default     = "es"
}

variable "servicios_cmek_obligatorio" {
  description = "Servicios que deben usar CMEK dentro de la carpeta ai-sandbox"
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
    condition     = alltrue([for s in ["storage.googleapis.com", "bigquery.googleapis.com", "compute.googleapis.com", "aiplatform.googleapis.com"] : contains(var.servicios_cmek_obligatorio, s)])
    error_message = "CMEK debe ser obligatorio al menos en buckets, BigQuery, discos y Vertex AI."
  }
}
