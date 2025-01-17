terraform {
  required_version = "= 1.5.7"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
    github = {
      source  = "integrations/github"
      version = "6.5.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "5.45.0"
    }
  }

  backend "gcs" {
    bucket = "libops-public-microservices-terraform"
    prefix = "/github-test"
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

resource "random_shuffle" "region" {
  input = [
    "us-east4",
    "us-east5",
    "us-central1",
    "us-west3",
    "us-west1",
    "us-west4",
    "us-south1"
  ]
  result_count = 1
}


module "houdini" {
  source = "../modules/cloudrun"

  name    = "houdini-test"
  project = var.project
  regions = random_shuffle.region.result
  skipNeg = true
  containers = tolist([
    {
      name           = "houdini",
      image          = "us-docker.pkg.dev/${var.project}/shared/imagemagick:main",
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
  source = "../modules/cloudrun"

  name    = "homarus-test"
  project = var.project
  regions = random_shuffle.region.result
  skipNeg = true
  containers = tolist([
    {
      name           = "homarus",
      image          = "us-docker.pkg.dev/${var.project}/shared/ffmpeg:main",
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
  source = "../modules/cloudrun"

  name    = "hypercube-test"
  project = var.project
  regions = random_shuffle.region.result
  skipNeg = true
  containers = tolist([
    {
      name           = "hypercube",
      image          = "us-docker.pkg.dev/${var.project}/shared/tesseract:main",
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
  source = "../modules/cloudrun"

  name    = "fits-test"
  project = var.project
  regions = random_shuffle.region.result
  skipNeg = true
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
  source = "../modules/cloudrun"

  name    = "crayfits-test"
  project = var.project
  regions = random_shuffle.region.result
  skipNeg = true
  containers = tolist([
    {
      name           = "crayfits",
      image          = "us-docker.pkg.dev/${var.project}/shared/fits:main",
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
      - "${module.fits.urls[random_shuffle.region.result[0]]}/fits/examine"
EOT
    }
  ])
  providers = {
    google = google.default
    docker = docker.local
  }
}
