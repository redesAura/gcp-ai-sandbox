variable "proyecto" {
  description = "Proyecto donde viven los key rings"
  type        = string
}

variable "nombre" {
  description = "Nombre del key ring (se repite en cada ubicación)"
  type        = string
}

variable "ubicaciones" {
  description = "Ubicaciones donde se crea un key ring con todas las llaves"
  type        = list(string)

  validation {
    condition     = length(var.ubicaciones) > 0
    error_message = "Se necesita al menos una ubicación."
  }
}

variable "llaves" {
  description = "Nombres de las llaves a crear en cada key ring, normalmente una por servicio"
  type        = list(string)
}

variable "rotacion" {
  description = "Periodo de rotación de las llaves, en segundos con sufijo s"
  type        = string
  default     = "7776000s" # 90 días

  validation {
    condition     = can(regex("^[0-9]+s$", var.rotacion)) && tonumber(trimsuffix(var.rotacion, "s")) <= 7776000 && tonumber(trimsuffix(var.rotacion, "s")) >= 86400
    error_message = "La rotación debe estar entre 1 y 90 días (86400s a 7776000s)."
  }
}

variable "nivel_proteccion" {
  description = "SOFTWARE o HSM"
  type        = string
  default     = "SOFTWARE"

  validation {
    condition     = contains(["SOFTWARE", "HSM"], var.nivel_proteccion)
    error_message = "nivel_proteccion debe ser SOFTWARE o HSM."
  }
}

variable "encriptadores" {
  description = "Miembros con roles/cloudkms.cryptoKeyEncrypterDecrypter por llave; se aplica en todas las ubicaciones"
  type        = map(list(string))
  default     = {}

  validation {
    condition     = alltrue([for llave in keys(var.encriptadores) : contains(var.llaves, llave)])
    error_message = "Cada llave en encriptadores debe existir en var.llaves."
  }
}

variable "etiquetas" {
  description = "Etiquetas para las llaves"
  type        = map(string)
  default     = {}
}
