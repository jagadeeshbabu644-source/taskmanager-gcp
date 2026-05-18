resource "google_service_account" "gke_sa" {
  account_id   = "${var.cluster_name}-sa"
  display_name = "GKE Node Service Account"
  project      = var.project_id
}
resource "google_project_iam_member" "gke_sa_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/artifactregistry.reader",
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}
resource "google_container_cluster" "primary" {
  name       = var.cluster_name
  location   = var.zone
  project    = var.project_id
  network    = var.vpc_id
  subnetwork = var.subnet_id
  remove_default_node_pool = true
  initial_node_count       = 1
  networking_mode          = "VPC_NATIVE"
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"
  addons_config {
    http_load_balancing        { disabled = false }
    horizontal_pod_autoscaling { disabled = false }
  }
  release_channel     { channel = "REGULAR" }
  deletion_protection = false
}
resource "google_container_node_pool" "nodes" {
  name       = "${var.cluster_name}-nodes"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  project    = var.project_id
  node_count = var.node_count
  node_config {
    machine_type    = var.machine_type
    disk_size_gb    = 30
    disk_type       = "pd-standard"
    service_account = google_service_account.gke_sa.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
    labels          = { env = var.environment }
  }
  autoscaling {
    min_node_count = 1
    max_node_count = var.max_nodes
  }
  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
