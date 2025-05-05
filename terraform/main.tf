terraform {
  backend "gcs" {}
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

provider "random" {}

resource "random_pet" "random_suffix" {
  keepers = {
    project = var.project
    region  = var.region
    zone    = var.zone
  }
}

resource "google_project_service" "artifact_registry_service" {
  service                    = "artifactregistry.googleapis.com"
  disable_dependent_services = true
}

resource "google_artifact_registry_repository" "registry" {
  location      = var.region
  repository_id = "docker-repo-${random_pet.random_suffix.id}"
  format        = "DOCKER"
  depends_on    = [google_project_service.artifact_registry_service]
}

resource "google_service_account" "service_account" {
  account_id   = "ar-${random_pet.random_suffix.id}-rw"
  display_name = "Service Account for Artifact Registry RW"
}

resource "google_artifact_registry_repository_iam_binding" "binding" {
  location   = google_artifact_registry_repository.registry.location
  repository = google_artifact_registry_repository.registry.name
  role       = "roles/artifactregistry.writer"
  members    = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
  depends_on = [google_artifact_registry_repository.registry, google_service_account.service_account]
}

resource "google_container_cluster" "kubernetes_cluster" {
  name               = "k8s-cluster-${random_pet.random_suffix.id}"
  location           = var.zone
  initial_node_count = 1
  node_config {
    machine_type    = "n1-standard-4"
    service_account = google_service_account.service_account.email
  }
  depends_on = [google_project_service.container_service, google_artifact_registry_repository_iam_binding.binding]
}

resource "google_project_service" "container_service" {
  service                    = "container.googleapis.com"
  disable_dependent_services = true
}