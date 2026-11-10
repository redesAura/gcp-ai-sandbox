variable "org_id" {
  description = "ID numérico de la organización"
  type        = string
}

variable "access_policy_id" {
  description = "ID de la access policy de la organización; si es null se crea una"
  type        = string
  default     = null
}

variable "nombre" {
  description = "Nombre del perímetro (letras, números y guion bajo)"
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,49}$", var.nombre))
    error_message = "El nombre solo admite letras, números y guion bajo, empezando con letra (máx. 50)."
  }
}

variable "descripcion" {
  description = "Descripción del perímetro"
  type        = string
  default     = ""
}

variable "recursos" {
  description = "Proyectos dentro del perímetro, como mapa clave => número de proyecto"
  type        = map(string)

  validation {
    condition     = alltrue([for numero in values(var.recursos) : can(regex("^[0-9]+$", numero))])
    error_message = "Los recursos deben ser números de proyecto."
  }
}

variable "servicios_restringidos" {
  description = "APIs protegidas por el perímetro"
  type        = list(string)
}

variable "servicios_accesibles_vpc" {
  description = "APIs que se pueden llamar desde las redes del perímetro"
  type        = list(string)
  default     = ["RESTRICTED-SERVICES"]
}

variable "rangos_ip_permitidos" {
  description = "Rangos públicos (por ejemplo la salida de on-premises) que reciben un access level"
  type        = list(string)
  default     = []
}

variable "modo_prueba" {
  description = "true aplica la configuración como dry-run: solo registra violaciones, no bloquea"
  type        = bool
  default     = false
}

variable "reglas_ingreso" {
  description = "Reglas de ingreso; servicios usa \"*\" para todos"
  type = map(object({
    identidades      = optional(list(string), [])
    tipo_identidad   = optional(string)
    niveles_acceso   = optional(list(string), [])
    proyectos_origen = optional(list(string), [])
    recursos_destino = optional(list(string), ["*"])
    servicios        = optional(list(string), ["*"])
  }))
  default = {}
}

variable "reglas_egreso" {
  description = "Reglas de egreso; recursos_destino en formato projects/<número>"
  type = map(object({
    identidades      = optional(list(string), [])
    tipo_identidad   = optional(string)
    recursos_destino = list(string)
    servicios        = optional(list(string), ["*"])
  }))
  default = {}
}
