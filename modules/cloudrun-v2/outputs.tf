output "backend" {
  value = var.skipNeg ? "" : google_compute_backend_service.backend[0].id
}

output "urls" {
  value = {
    for region, service in google_cloud_run_v2_service.cloudrun :
    region => service.status[0].url
  }
}
