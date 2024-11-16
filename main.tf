terraform {
  required_version = "= 1.5.7"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.1"
    }
    github = {
      source  = "integrations/github"
      version = "6.2.1"
    }
    google = {
      source  = "hashicorp/google"
      version = "5.29.1"
    }
  }

  backend "gcs" {
    bucket = "libops-public-microservices-terraform"
    prefix = "/microservices"
  }
}


provider "google" {
  alias   = "default"
  project = var.project
}

provider "docker" {
  alias = "local"
  registry_auth {
    address     = "us-docker.pkg.dev"
    config_file = pathexpand("~/.docker/config.json")
  }
}

module "ocrpdf" {
  source = "./modules/cloudrun"

  name    = "ocrpdf"
  project = var.project
  containers = tolist([
    {
      name           = "ocrpdf",
      image          = "us-docker.pkg.dev/${var.project}/shared/scyllaridae-ocrpdf:main",
      port           = 8080
      liveness_probe = "/healthcheck"
      memory         = "2Gi"
      cpu            = "2000m"
    }
  ])
  providers = {
    google = google.default
    docker = docker.local
  }
}

module "pandoc" {
  source = "./modules/cloudrun"

  name    = "pandoc"
  project = var.project
  containers = tolist([
    {
      name           = "pandoc",
      image          = "us-docker.pkg.dev/${var.project}/shared/scyllaridae-pandoc:main",
      port           = 8080
      liveness_probe = "/healthcheck"
      memory         = "4Gi"
      cpu            = "4000m"
    }
  ])
  providers = {
    google = google.default
    docker = docker.local
  }
}

module "whisper" {
  source = "./modules/cloudrun"

  name    = "whisper"
  project = var.project
  containers = tolist([
    {
      name           = "whisper",
      image          = "us-docker.pkg.dev/${var.project}/shared/scyllaridae-whisper:main",
      port           = 8080
      liveness_probe = "/healthcheck"
      memory         = "4Gi"
      cpu            = "4000m"
    }
  ])
  providers = {
    google = google.default
    docker = docker.local
  }
}

module "houdini" {
  source = "./modules/cloudrun"

  name    = "houdini"
  project = var.project
  containers = tolist([
    {
      name           = "houdini",
      image          = "us-docker.pkg.dev/${var.project}/shared/scyllaridae-imagemagick:main",
      port           = 8080
      liveness_probe = "/healthcheck"
    }
  ])
  providers = {
    google = google.default
    docker = docker.local
  }
}

module "homarus" {
  source = "./modules/cloudrun"

  name    = "homarus"
  project = var.project
  containers = tolist([
    {
      name           = "homarus",
      image          = "us-docker.pkg.dev/${var.project}/shared/scyllaridae-ffmpeg:main",
      port           = 8080
      liveness_probe = "/healthcheck"
    }
  ])
  providers = {
    google = google.default
    docker = docker.local
  }
}

module "hypercube" {
  source = "./modules/cloudrun"

  name    = "hypercube"
  project = var.project
  containers = tolist([
    {
      name           = "hypercube",
      image          = "us-docker.pkg.dev/${var.project}/shared/scyllaridae-tesseract:main",
      port           = 8080
      liveness_probe = "/healthcheck"
    }
  ])
  providers = {
    google = google.default
    docker = docker.local
  }
}

module "fits" {
  source = "./modules/cloudrun"

  name    = "fits"
  project = var.project
  containers = tolist([
    {
      name   = "fits",
      image  = "us-docker.pkg.dev/${var.project}/shared/harvard-fits:main",
      memory = "2Gi"
      cpu    = "2000m"
    }
  ])

  providers = {
    google = google.default
    docker = docker.local
  }
}

module "crayfits" {
  source = "./modules/cloudrun"

  name    = "crayfits"
  project = var.project
  containers = tolist([
    {
      name           = "crayfits",
      image          = "us-docker.pkg.dev/${var.project}/shared/scyllaridae-fits:main",
      liveness_probe = "/healthcheck"
    }
  ])
  addl_env_vars = tolist([
    {
      name  = "SCYLLARIDAE_YML"
      value = <<EOT
allowedMimeTypes:
  - "*"
cmdByMimeType:
  default:
    cmd: "curl"
    args:
      - "-X"
      - "POST"
      - "-F"
      - "datafile=@-"
      - "https://microservices.libops.site/fits/examine"
EOT
    }
  ])
  providers = {
    google = google.default
    docker = docker.local
  }
}

module "lb" {
  source = "./modules/lb"

  project = var.project
  backends = {
    "homarus"   = module.homarus.backend,
    "houdini"   = module.houdini.backend,
    "hypercube" = module.hypercube.backend,
    "fits"      = module.fits.backend
    "crayfits"  = module.crayfits.backend
    "whisper"   = module.whisper.backend
    "pandoc"    = module.pandoc.backend
    "ocrpdf"    = module.ocrpdf.backend
  }
}

resource "google_monitoring_uptime_check_config" "availability" {
  for_each = toset([
    "crayfits",
    "homarus",
    "houdini",
    "hypercube"
  ])
  display_name = "${each.value}-availability"
  timeout      = "10s"
  period       = "60s"
  project      = var.project
  selected_regions = [
    "USA_OREGON",
    "USA_VIRGINIA",
    "USA_IOWA"
  ]
  http_check {
    path         = "/${each.value}/healthcheck"
    port         = "443"
    use_ssl      = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project
      host       = "microservices.libops.site"
    }
  }
}
