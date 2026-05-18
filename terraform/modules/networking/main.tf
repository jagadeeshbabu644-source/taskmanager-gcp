resource "google_compute_network" "vpc" {
  name                    = "${var.project_id}-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id
}
resource "google_compute_subnetwork" "gke_subnet" {
  name          = "${var.project_id}-gke-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id
  # Pods need separate large IP range (many pods per node)
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr
  }
  # Services need separate range (each Service gets a ClusterIP)
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr
  }
  private_ip_google_access = true
}
resource "google_compute_router" "router" {
  name    = "${var.project_id}-router"
  region  = var.region
  network = google_compute_network.vpc.id
  project = var.project_id
}
# NAT: lets private GKE nodes reach internet (pull images, logs, APIs)
resource "google_compute_router_nat" "nat" {
  name                               = "${var.project_id}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  project                            = var.project_id
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
