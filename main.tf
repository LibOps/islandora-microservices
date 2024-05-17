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

module "houdini" {
  source = "./modules/cloudrun"

  name    = "houdini"
  project = var.project
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
  source = "./modules/cloudrun"

  name    = "homarus"
  project = var.project
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
  source = "./modules/cloudrun"

  name    = "hypercube"
  project = var.project
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

module "crayfits" {
  source = "./modules/cloudrun"

  name    = "crayfits"
  project = var.project
  containers = tolist([
    {
      name           = "crayfits",
      image          = "us-docker.pkg.dev/${var.project}/shared/fits:main",
      port           = 8080
      liveness_probe = "/healthcheck"
    }
  ])
  providers = {
    google = google.default
    docker = docker.local
  }
}
