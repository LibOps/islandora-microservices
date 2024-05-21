locals {
  metrics_json = file("${path.module}/dashboard.json")
  md5          = md5(local.metrics_json)
}

data "google_compute_global_address" "default" {
  project = var.project
  name    = "microservices-ipv4"
}

data "google_compute_global_address" "default-v6" {
  project = var.project
  name    = "microservices-ipv6"
}

resource "google_compute_global_forwarding_rule" "https" {
  project               = var.project
  name                  = "microservices-https"
  target                = google_compute_target_https_proxy.default.self_link
  ip_address            = data.google_compute_global_address.default.address
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

resource "google_compute_global_forwarding_rule" "https-v6" {
  project               = var.project
  name                  = "microservices-https-v6"
  target                = google_compute_target_https_proxy.default.self_link
  ip_address            = data.google_compute_global_address.default-v6.address
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

resource "google_compute_target_https_proxy" "default" {
  project = var.project
  name    = "microservices-https-proxy"
  url_map = google_compute_url_map.default.self_link

  ssl_certificates = [
    google_compute_managed_ssl_certificate.default.id,
  ]
}

resource "google_compute_managed_ssl_certificate" "default" {
  name = "microservices-tls"
  managed {
    domains = [
      "microservices.libops.site"
    ]
  }
  project = var.project
}

resource "google_compute_url_map" "default" {
  name    = "microservices-url-map"
  project = var.project

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  default_url_redirect {
    https_redirect = true
    strip_query    = true
    host_redirect  = "github.com"
    path_redirect  = "LibOps/islandora-microservices"
  }

  path_matcher {
    name            = "allpaths"
    default_service = var.backends.houdini
    dynamic "path_rule" {
      for_each = var.backends
      content {
        paths   = ["/${path_rule.key}", "/${path_rule.key}/*"]
        service = path_rule.value
      }
    }
    dynamic "path_rule" {
      for_each = var.backends
      content {
        paths   = ["/${path_rule.key}/healthcheck"]
        service = path_rule.value
        route_action {
          url_rewrite {
            path_prefix_rewrite = "/healthcheck"
          }
        }
      }
    }
  }
}

# add a dashboard
# only updating it if we update our JSON
# since terraform and google's dashboard exports don't play nice
resource "null_resource" "metrics-json" {
  triggers = {
    md5 = local.md5
  }
}
resource "google_monitoring_dashboard" "dashboard" {
  project        = var.project
  dashboard_json = local.metrics_json

  lifecycle {
    ignore_changes = [
      dashboard_json
    ]
    replace_triggered_by = [null_resource.metrics-json.id]
  }
}
