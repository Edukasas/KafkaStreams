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

resource "google_container_registry" "registry" {
  project    = var.project
  depends_on = [google_project_service.container_registry_service]
}

resource "google_service_account" "service_account" {
  account_id   = "gcs-${random_pet.random_suffix.id}-rw"
  display_name = "Service Account for RW"
}

resource "google_storage_bucket_iam_binding" "binding" {
  bucket = google_container_registry.registry.id
  role   = "roles/storage.admin"
  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
  depends_on = [google_container_registry.registry, google_service_account.service_account]
}

resource "google_container_cluster" "kubernetes_cluster" {
  name               = "k8s-cluster-${random_pet.random_suffix.id}"
  location           = var.zone
  initial_node_count = 1
  node_config {
    machine_type    = "n1-standard-4"
    service_account = google_service_account.service_account.email
  }
  depends_on = [google_project_service.container_service, google_storage_bucket_iam_binding.binding]
}

resource "google_project_service" "container_service" {
  service                    = "container.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "container_registry_service" {
  service                    = "containerregistry.googleapis.com"
  disable_dependent_services = true
}