output "vpc_id" { 
value = google_compute_network.vpc.id 
}
output "subnet_id" { 
value = google_compute_subnetwork.gke_subnet.id 
}
output "subnet_name" { 
value = google_compute_subnetwork.gke_subnet.name 
}
