variable "backends" {
  type        = map(string)
  description = "The Cloud Run Serverless NEG backends"
}

variable "project" {
  type        = string
  description = "The GCP project to use"
}
