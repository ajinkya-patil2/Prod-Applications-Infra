output "network_name" {
  value       = google_compute_network.this.name
  description = "VPC network name."
}

output "subnet_name" {
  value       = google_compute_subnetwork.this.name
  description = "Application subnet name."
}

output "instance_group_manager" {
  value       = google_compute_region_instance_group_manager.this.name
  description = "Regional managed instance group name."
}

output "health_check" {
  value       = google_compute_health_check.this.name
  description = "Health check used for auto-healing."
}
