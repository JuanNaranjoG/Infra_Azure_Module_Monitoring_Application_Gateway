variable "application_gateways" {
  description = "Mapa de instancias de Application Gateway a monitorear. La key es el nombre identificador y se usa en el nombre de la alerta."
  type = map(object({
    id = string
  }))
}

variable "resource_group_name" {
  description = "Nombre del grupo de recursos donde residen las instancias de Application Gateway"
  type        = string
}

variable "action_group_id" {
  description = "ID del Action Group para el envío de notificaciones"
  type        = string
}

####################
# Parámetros de alerta
####################
variable "metric_severity" {
  description = "Severidad de las alertas por métrica (0 = Critical, 1 = Error, 2 = Warning, 3 = Informational, 4 = Verbose)"
  type        = map(number)

  validation {
    condition     = alltrue([for k, v in var.metric_severity : v >= 0 && v <= 4])
    error_message = "La severidad debe estar entre 0 y 4."
  }
}

variable "frequency" {
  description = "Frecuencia de evaluación de la alerta. Ejemplos: PT1M, PT5M, PT15M, PT30M, PT1H"
  type        = string
  default     = "PT5M"
}

variable "window_size" {
  description = "Ventana de tiempo para la evaluación. Ejemplos: PT5M, PT10M, PT15M, PT30M, PT1H, PT6H, PT12H, P1D"
  type        = string
  default     = "PT5M"
}

####################
# Umbrales por métrica
####################
variable "thresholds" {
  description = <<-EOT
    Umbrales para cada métrica de Azure Application Gateway. Valores por defecto:
      - unhealthy_host_count   : 1 (Count) — alerta si al menos 1 backend es marcado como no saludable por el health probe
      - failed_requests        : 50 (Count) — alerta si el número de solicitudes fallidas supera 50
      - backend_connect_time   : 5000 (ms) — alerta si el tiempo promedio de conexión TCP hacia backends supera 5000 ms
  EOT
  type = object({
    unhealthy_host_count  = number
    failed_requests       = number
    backend_connect_time  = number
  })
  default = {
    unhealthy_host_count  = 1
    failed_requests       = 50
    backend_connect_time  = 5000
  }
}

#####################
# Variables generales
#####################
variable "project" {
  description = "Nombre del proyecto o iniciativa"
  type        = string
}

variable "purpose" {
  description = "Propósito del recurso"
  type        = string
  default     = "monitoring"
}

variable "bdo_environment" {
  description = "Ambiente del recurso (Dev, QA, Prod, etc.)"
  type        = string
}

variable "resource_aditional_tags" {
  description = "Tags adicionales opcionales"
  type        = map(string)
  default     = {}
}

variable "resource_tags" {
  description = "Tags obligatorios BdO / Aval"
  type        = map(string)
  default     = {}
}

variable "name_sevice" {
  description = "Nombre del servicio a monitorear"
  type        = string
  default     = "Azure Application Gateway"
}
