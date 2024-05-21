variable "name" {
  type = string
}

variable "min_instances" {
  type    = string
  default = "0"
}
variable "max_instances" {
  type    = string
  default = "100"
}

variable "regions" {
  type        = list(string)
  description = "The GCP region(s) to deploy to"
  default = [
    "us-east4",
    "us-east5",
    "us-central1",
    "us-west3",
    "us-west1",
    "us-west4",
    "us-south1",
    "northamerica-northeast1",
    "northamerica-northeast2",
    "australia-southeast1",
    "australia-southeast2"
  ]
}

variable "project" {
  type        = string
  description = "The GCP project to use"
}

variable "skipNeg" {
  type    = bool
  default = false
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
