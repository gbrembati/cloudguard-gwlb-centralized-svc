// --- Provider Settings ---
region      = "xx-xxxx-x" 
access_key  = "xxxxxxxxxxxxxxx"
secret_key  = "xxxxxxxxxxxxxxx"

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

availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
number_of_AZs = 3

nat_gw_subnet_1_cidr ="10.250.13.0/24"
nat_gw_subnet_2_cidr = "10.250.23.0/24"
nat_gw_subnet_3_cidr = "10.250.33.0/24"
nat_gw_subnet_4_cidr = "10.250.43.0/24"

gwlbe_subnet_1_cidr = "10.250.14.0/24"
gwlbe_subnet_2_cidr = "10.250.24.0/24"
gwlbe_subnet_3_cidr = "10.250.34.0/24"
gwlbe_subnet_4_cidr = "10.250.44.0/24"

// --- General Settings ---
key_name                = "<ec2-keypair-name>"
enable_volume_encryption = true
volume_size             = 100
enable_instance_connect = false
allow_upload_download   = true
management_server       = "<chkp-management-name>"
configuration_template  = "<chkp-cme-template-name>"
admin_shell             = "/bin/bash"

// --- Gateway Load Balancer Configuration ---
gateway_load_balancer_name        = "<chkp-gwlb-svc-name>"
target_group_name                 = "<chkp-gwlb-tg-name>"
enable_cross_zone_load_balancing  = "true"

// --- Check Point CloudGuard IaaS Security Gateways Auto Scaling Group Configuration ---
gateway_name          = "<chkp-gwlb-gw-name>"
gateway_instance_type = "c6i.large"
minimum_group_size    = 3
maximum_group_size    = 4
gateway_version       = "R80.40-BYOL"
gateway_password_hash = "<openssl-created-pwd-hash>"    // openssl passwd -6 "password"
gateway_SICKey        = "CheckpointPOC2022"
enable_cloudwatch     = true
gateways_provision_address_type = "private"

// --- Check Point CloudGuard IaaS Security Management Server Configuration ---
management_deploy         = true
management_instance_type  = "m6i.xlarge"
management_version        = "R81.10-BYOL"
management_password_hash  = "<openssl-created-pwd-hash>"    // openssl passwd -6 "password"
gateways_policy           = "Standard"
gateway_management        = "Locally managed"
admin_cidr                = "0.0.0.0/0"
gateways_addresses        = "0.0.0.0/0"