variable "nombre" {
  description = "Nombre corto de la política de firewall jerárquica"
  type        = string
}

variable "padre" {
  description = "Carpeta u organización dueña de la política (folders/<id> u organizations/<id>)"
  type        = string

  validation {
    condition     = can(regex("^(folders|organizations)/[0-9]+$", var.padre))
    error_message = "padre debe tener el formato folders/<id> u organizations/<id>."
  }
}

variable "descripcion" {
  description = "Descripción de la política"
  type        = string
  default     = ""
}

variable "asociaciones" {
  description = "Carpetas u organización donde se aplica la política, como mapa nombre => folders/<id>"
  type        = map(string)
  default     = {}
}

variable "reglas" {
  description = "Reglas de la política, la clave se usa como descripción"
  type = map(object({
    prioridad           = number
    direccion           = string
    accion              = string
    rangos_origen       = optional(list(string))
    rangos_destino      = optional(list(string))
    fqdns_destino       = optional(list(string))
    amenazas_origen     = optional(list(string))
    amenazas_destino    = optional(list(string))
    registrar           = optional(bool, false)
    cuentas_de_servicio = optional(list(string))
    protocolos = optional(list(object({
      protocolo = string
      puertos   = optional(list(string))
    })), [{ protocolo = "all" }])
  }))

  validation {
    condition     = alltrue([for r in values(var.reglas) : contains(["INGRESS", "EGRESS"], r.direccion)])
    error_message = "direccion debe ser INGRESS o EGRESS."
  }

  validation {
    condition     = alltrue([for r in values(var.reglas) : contains(["allow", "deny", "goto_next"], r.accion)])
    error_message = "accion debe ser allow, deny o goto_next."
  }

  validation {
    condition     = length(distinct([for r in values(var.reglas) : r.prioridad])) == length(var.reglas)
    error_message = "No puede haber dos reglas con la misma prioridad, aunque tengan distinta dirección: la prioridad identifica a la regla dentro de la política."
  }
}
