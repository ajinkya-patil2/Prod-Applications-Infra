locals {
  config = yamldecode(file(var.components_file))

  network_name = local.config.network.name
  subnet_name  = local.config.subnet.name
}

resource "google_compute_network" "this" {
  name                    = local.network_name
  auto_create_subnetworks = false
  project                 = local.config.project_id
}

resource "google_compute_subnetwork" "this" {
  name                     = local.subnet_name
  ip_cidr_range            = local.config.subnet.cidr
  region                   = local.config.region
  network                  = google_compute_network.this.id
  project                  = local.config.project_id
  private_ip_google_access = local.config.subnet.private_ip_google_access
}

resource "google_compute_firewall" "this" {
  for_each = {
    for rule in local.config.firewall_rules : rule.name => rule
  }

  name    = each.value.name
  network = google_compute_network.this.name
  project = local.config.project_id

  direction     = each.value.direction
  priority     = each.value.priority
  source_ranges = each.value.source_ranges
  target_tags   = each.value.target_tags

  dynamic "allow" {
    for_each = each.value.allow
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }
}

resource "google_compute_instance_template" "this" {
  name_prefix  = "${local.config.instance_template.name}-"
  machine_type = local.config.instance_template.machine_type
  project      = local.config.project_id

  tags = local.config.instance_template.tags

  disk {
    boot         = true
    auto_delete  = true
    source_image = local.config.instance_template.boot_disk.image
    disk_size_gb = local.config.instance_template.boot_disk.size_gb
    disk_type    = local.config.instance_template.boot_disk.type
  }

  network_interface {
    subnetwork = google_compute_subnetwork.this.id

    dynamic "access_config" {
      for_each = local.config.instance_template.public_ip ? [1] : []
      content {}
    }
  }

  service_account {
    email  = local.config.instance_template.service_account.email
    scopes = local.config.instance_template.service_account.scopes
  }

  metadata = local.config.instance_template.metadata

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_instance_group_manager" "this" {
  name               = local.config.instance_group.name
  base_instance_name = local.config.instance_group.base_instance_name
  region             = local.config.region
  project            = local.config.project_id

  distribution_policy_zones = local.config.instance_group.zones

  version {
    instance_template = google_compute_instance_template.this.id
  }

  target_size = local.config.instance_group.target_size

  named_port {
    name = local.config.instance_group.named_port.name
    port = local.config.instance_group.named_port.port
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.this.id
    initial_delay_sec = local.config.instance_group.auto_healing_initial_delay_sec
  }
}

resource "google_compute_health_check" "this" {
  name    = local.config.health_check.name
  project = local.config.project_id

  check_interval_sec  = local.config.health_check.check_interval_sec
  timeout_sec         = local.config.health_check.timeout_sec
  healthy_threshold   = local.config.health_check.healthy_threshold
  unhealthy_threshold = local.config.health_check.unhealthy_threshold

  http_health_check {
    port         = local.config.health_check.http.port
    request_path = local.config.health_check.http.request_path
  }
}

resource "google_compute_region_autoscaler" "this" {
  name    = local.config.autoscaler.name
  region  = local.config.region
  project = local.config.project_id
  target  = google_compute_region_instance_group_manager.this.id

  autoscaling_policy {
    min_replicas    = local.config.autoscaler.min_replicas
    max_replicas    = local.config.autoscaler.max_replicas
    cooldown_period = local.config.autoscaler.cooldown_period

    cpu_utilization {
      target = local.config.autoscaler.cpu_target
    }
  }
}
