terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
    google = {
      source  = "hashicorp/google"
      version = "6.16.0"
    }
  }
}

data "google_service_account" "service_account" {
  account_id = "cr-microservices"
}

data "docker_registry_image" "image" {
  count = length(var.containers)
  name  = var.containers[count.index].image
}

resource "google_cloud_run_service" "cloudrun" {
  for_each = toset(var.regions)
  name     = var.name
  location = each.value

  lifecycle {
    ignore_changes = [
      metadata[0].annotations["run.googleapis.com/launch-stage"],
      metadata[0].effective_annotations["run.googleapis.com/launch-stage"]
    ]
    create_before_destroy = true
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
        "run.googleapis.com/cpu-throttling" : var.containers[0].gpus == "",
      }
    }
    spec {
      service_account_name  = data.google_service_account.service_account.email
      container_concurrency = 1

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
            limits = merge(
              {
                memory = containers.value.memory
              },
              containers.value.gpus != "" ? {
                "nvidia.com/gpu" = containers.value.gpus
                } : { cpu        = containers.value.cpu
              }
            )
          }
        }
      }
    }
  }
}

resource "google_cloud_run_service_iam_member" "invoker" {
  for_each = toset(var.regions)
  location = each.value
  service  = google_cloud_run_service.cloudrun[each.value].name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# create a serverless NEG for this set of regional services
resource "google_compute_region_network_endpoint_group" "neg" {
  for_each              = var.skipNeg ? toset([]) : toset(var.regions)
  name                  = "libops-neg-${var.name}-${each.value}"
  network_endpoint_type = "SERVERLESS"
  region                = each.value
  project               = var.project

  cloud_run {
    service = google_cloud_run_service.cloudrun[each.value].name
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_backend_service" "backend" {
  count = var.skipNeg ? 0 : 1

  project = var.project
  name    = "libops-backend-${var.name}"

  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTPS"

  dynamic "backend" {
    for_each = google_compute_region_network_endpoint_group.neg

    content {
      group = backend.value.id
    }
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}
