# YAML-driven GCP VM infrastructure

This Terraform configuration provisions a small regional managed instance group of GCP VM instances. The infrastructure inputs are defined in [`components.yaml`](components.yaml); Terraform reads that file with `yamldecode` and creates the VPC, subnet, firewall rules, instance template, health check, managed instance group, and autoscaler.

No application source code is included. The VM image is provisioned only with its base operating system; application installation and deployment should be added later through a separate image, startup mechanism, or configuration-management workflow.

## Use

1. Edit `components.yaml`:
   - Set `project_id`.
   - Replace the administrative SSH CIDR.
   - Change the region, zones, machine type, image, and scaling values as needed.
   - Set a dedicated service-account email and least-privilege scopes for production.
2. Authenticate Terraform with Google Application Default Credentials or a supported service-account mechanism.
3. Run:

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

Use another YAML file without changing Terraform code:

```bash
terraform plan -var='components_file=prod.yaml'
```

The sample intentionally does not create an HTTP load balancer or install an application. The managed instance group and health check are ready to be connected to those components when the application-facing design is defined.
