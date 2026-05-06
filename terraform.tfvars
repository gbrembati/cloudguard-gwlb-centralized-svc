// --- Provider Settings ---
region     = "<aws-region>"
aws-access-key = "<aws-access-key>"
aws-secret-key = "<aws-secret-key>"

// --- Networking Settings ---
vpc_cidr = "10.250.0.0/16"
public_subnets_map = {
  "eu-west-1a" = 1
  "eu-west-1b" = 2
  "eu-west-1c" = 3
}
tgw_subnets_map = {
  "eu-west-1a" = 5
  "eu-west-1b" = 6
  "eu-west-1c" = 7
}
subnets_bit_length = 8

availability_zones = ["eu-west-3a", "eu-west-3b", "eu-west-3c"]
number_of_AZs      = 3

nat_gw_subnet_1_cidr = "10.250.13.0/24"
nat_gw_subnet_2_cidr = "10.250.23.0/24"
nat_gw_subnet_3_cidr = "10.250.33.0/24"
nat_gw_subnet_4_cidr = "10.250.43.0/24"

gwlbe_subnet_1_cidr = "10.250.14.0/24"
gwlbe_subnet_2_cidr = "10.250.24.0/24"
gwlbe_subnet_3_cidr = "10.250.34.0/24"
gwlbe_subnet_4_cidr = "10.250.44.0/24"

// --- General Settings ---
enable_volume_encryption = true
volume_size              = 100
enable_instance_connect  = false
allow_upload_download    = true
admin_shell              = "/bin/bash"

// --- Gateway Load Balancer Configuration ---
enable_cross_zone_load_balancing = "true"

// --- Check Point CloudGuard IaaS Security Gateways Auto Scaling Group Configuration ---
gateway_instance_type                  = "c6in.large"
minimum_group_size                     = 3
maximum_group_size                     = 4
gateway_version                        = "R82.10-BYOL"                // "R80.40-BYOL" | "R81.20-BYOL"
enable_cloudwatch                      = true
gateways_provision_address_type        = "private"
allocate_public_IP                     = false
gateway_bootstrap_script               = ""
gateway_maintenance_mode_password_hash = ""

// --- Check Point CloudGuard IaaS Security Management Server Configuration ---
management_deploy                         = false
management_instance_type                  = "m6i.xlarge"
management_version                        = "R82.10-BYOL"                // "R81.10-BYOL" | "R81.20-BYOL"           
management_maintenance_mode_password_hash = ""
gateways_policy                           = "Standard"
gateway_management                        = "Locally managed"
admin_cidr                                = "0.0.0.0/0"
gateways_addresses                        = "0.0.0.0/0"