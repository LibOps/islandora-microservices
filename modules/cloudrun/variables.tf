variable "name" {
  type = string
}

variable "min_instances" {
  type    = string
  default = "0"
}
variable "max_instances" {
  type    = string
  default = "5"
}

variable "memory" {
  type    = string
  default = "512Mi"
}

variable "cpu" {
  type    = string
  default = "1000m"
}

variable "regions" {
  type        = list(string)
  description = "The GCP region(s) to deploy to"
}

variable "invokers" {
  type = list(string)
}

variable "project" {
  type        = string
  description = "The GCP project to use"
}

variable "secrets" {
  type = list(object({
    name        = string
    secret_id   = string
    secret_name = string
  }))
  default = []
}
variable "containers" {
  type = list(object({
    image          = string
    name           = string
    port           = optional(number, 0)
    memory         = optional(string, "512Mi")
    cpu            = optional(string, "1000m")
    liveness_probe = optional(string, "")
  }))
}

variable "addl_env_vars" {
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}
