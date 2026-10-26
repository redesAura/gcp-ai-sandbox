variable "org_id" {
  description = "ID numérico de la organización de GCP"
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.org_id))
    error_message = "org_id debe contener solo dígitos."
  }
}

variable "billing_account" {
  description = "Cuenta de facturación, formato XXXXXX-XXXXXX-XXXXXX"
  type        = string

  validation {
    condition     = can(regex("^[A-Z0-9]{6}-[A-Z0-9]{6}-[A-Z0-9]{6}$", var.billing_account))
    error_message = "billing_account debe tener el formato XXXXXX-XXXXXX-XXXXXX."
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

variable "github_org" {
  description = "Organización de GitHub"
  type        = string
}

variable "github_repo" {
  description = "Nombre del repositorio"
  type        = string
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

variable "etapas" {
  description = "Etapas que reciben una cuenta de servicio"
  type        = list(string)
  default     = ["1-org", "2-security", "3-networks", "4-ai-platform", "5-sandboxes"]
}