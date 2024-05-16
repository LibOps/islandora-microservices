terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "= 3.0.1"
    }
    google = {
      source  = "hashicorp/google"
      version = "= 5.29.1"
    }
  }
}

resource "google_service_account" "service_account" {
  account_id  = "cr-${var.name}"
  description = "Service account for Cloud Run. Managed by Terraform"
}

resource "google_project_iam_member" "sa_role" {
  project = var.project
  role    = "roles/iam.serviceAccountUser"
  member  = format("serviceAccount:%s", google_service_account.service_account.email)
}

data "docker_registry_image" "image" {
  count = length(var.containers)
  name  = var.containers[count.index].image
}

resource "google_cloud_run_service" "cloudrun" {
  count    = length(var.regions)
  name     = format("%s-%s", var.name, var.regions[count.index])
  location = var.regions[count.index]

  lifecycle {
    ignore_changes = [
      metadata[0].annotations["run.googleapis.com/launch-stage"],
      metadata[0].effective_annotations["run.googleapis.com/launch-stage"]
    ]
  }

  metadata {
    annotations = {
      "run.googleapis.com/launch-stage" : "BETA",
    }
  }

  template {
    metadata {
      annotations = {
        "run.googleapis.com/execution-environment" : "gen2",
        "autoscaling.knative.dev/minScale" : var.min_instances,
        "autoscaling.knative.dev/maxScale" : var.max_instances,
        "run.googleapis.com/cpu-throttling" : true,
      }
    }
    spec {
      service_account_name = google_service_account.service_account.email
      dynamic "containers" {
        for_each = var.containers
        content {
          name = containers.value.name
          # make the image the full SHA so new images trigger redeployment
          image = format("%s@%s", containers.value.image, data.docker_registry_image.image[containers.key].sha256_digest)

          dynamic "ports" {
            for_each = containers.value.port != 0 ? toset([containers.value.port]) : toset([])
            content {
              container_port = ports.value
            }
          }

          dynamic "liveness_probe" {
            for_each = containers.value.liveness_probe != "" ? toset([containers.value.liveness_probe]) : toset([])
            content {
              period_seconds    = 300
              failure_threshold = 1
              http_get {
                path = liveness_probe.value
              }
            }
          }

          dynamic "env" {
            for_each = var.secrets
            content {
              name = env.value.name
              value_from {
                secret_key_ref {
                  name = env.value.secret_name
                  key  = "latest"
                }
              }
            }
          }

          dynamic "env" {
            for_each = var.addl_env_vars
            content {
              name  = env.value.name
              value = env.value.value
            }
          }

          resources {
            limits = {
              cpu    = containers.value.cpu
              memory = containers.value.memory
            }
          }
        }
      }
    }
  }
}

resource "google_cloud_run_service_iam_member" "invoker" {
  for_each = toset(var.invokers)
  location = google_cloud_run_service.cloudrun[0].location
  service  = google_cloud_run_service.cloudrun[0].name
  role     = "roles/run.invoker"
  member   = each.value
}
