// Module: Check Point CloudGuard Network Gateway Load Balancer into an existing VPC

// --- AWS Provider ---
variable "region" {
  type = string
  description = "AWS region"
  default = ""
}
variable "access_key" {
  type = string
  description = "AWS access key"
  default = ""
}
variable "secret_key" {
  type = string
  description = "AWS secret key"
  default = ""
}

// ---VPC Network Configuration ---
variable "number_of_AZs" {
  type = number
  description = "Number of Availability Zones to use in the VPC. This must match your selections in the list of Availability Zones parameter"
  default = 2
}
variable "availability_zones"{
  type = list(string)
  description = "The Availability Zones (AZs) to use for the subnets in the VPC. Select two (the logical order is preserved)"
}
resource "null_resource" "tgw_availability_zones_validation1" {
  count = var.number_of_AZs == length(var.availability_zones) ? 0 : "variable availability_zones list size must be equal to variable num_of_AZs"
}
variable "vpc_cidr" {
  type = string
  description = "The CIDR block of the VPC"
  default = "10.0.0.0/16"
}
variable "public_subnets_map" {
  type = map(string)
  description = "A map of pairs {availability-zone = subnet-suffix-number}. Each entry creates a subnet. Minimum 2 pairs.  (e.g. {\"us-east-1a\" = 1} ) "
}
resource "null_resource" "tgw_availability_zones_validation2" {
  count = var.number_of_AZs == length(var.public_subnets_map) ? 0 : "variable public_subnets_map size must be equal to variable num_of_AZs"
}
variable "subnets_bit_length" {
  type = number
  description = "Number of additional bits with which to extend the vpc cidr. For example, if given a vpc_cidr ending in /16 and a subnets_bit_length value of 4, the resulting subnet address will have length /20"
}
variable "tgw_subnets_map" {
  type = map(string)
  description = "A map of pairs {availability-zone = subnet-suffix-number} for the tgw subnets. Each entry creates a subnet. Minimum 2 pairs.  (e.g. {\"us-east-1a\" = 1} ) "
}
resource "null_resource" "tgw_availability_zones_validation3" {
  count = var.number_of_AZs == length(var.tgw_subnets_map) ? 0 : "variable tgw_subnets_map size must be equal to variable num_of_AZs"
}
variable "nat_gw_subnet_1_cidr" {
  type = string
  description = "CIDR block for NAT subnet 1 located in the 1st Availability Zone"
  default = "10.0.13.0/24"
}
variable "nat_gw_subnet_2_cidr" {
  type = string
  description = "CIDR block for NAT subnet 2 located in the 2st Availability Zone"
  default = "10.0.23.0/24"
}
variable "nat_gw_subnet_3_cidr" {
  type = string
  description = "CIDR block for NAT subnet 3 located in the 3st Availability Zone"
  default = "10.0.33.0/24"
}
variable "nat_gw_subnet_4_cidr" {
  type = string
  description = "CIDR block for NAT subnet 4 located in the 4st Availability Zone"
  default = "10.0.43.0/24"
}
variable "gwlbe_subnet_1_cidr" {
  type = string
  description = "CIDR block for Gateway Loadbalancer endpoint subnet 1 located in the 1st Availability Zone"
  default = "10.0.14.0/24"
}
variable "gwlbe_subnet_2_cidr" {
  type = string
  description = "CIDR block for Gateway Loadbalancer endpoint subnet 2 located in the 2st Availability Zone"
  default = "10.0.24.0/24"
}
variable "gwlbe_subnet_3_cidr" {
  type = string
  description = "CIDR block for Gateway Loadbalancer endpoint subnet 3 located in the 3st Availability Zone"
  default = "10.0.34.0/24"
}
variable "gwlbe_subnet_4_cidr" {
  type = string
  description = "CIDR block for Gateway Loadbalancer endpoint subnet 4 located in the 4st Availability Zone"
  default = "10.0.44.0/24"
}
// --- General Settings ---
variable "key_name" {
  type = string
  description = "The EC2 Key Pair name to allow SSH access to the instances"
}
variable "enable_volume_encryption" {
  type = bool
  description = "Encrypt Environment instances volume with default AWS KMS key"
  default = true
}
variable "volume_size" {
  type = number
  description = "Root volume size (GB) - minimum 100"
  default = 100
}
resource "null_resource" "volume_size_too_small" {
  // Will fail if var.volume_size is less than 100
  count = var.volume_size >= 100 ? 0 : "variable volume_size must be at least 100"
}
variable "volume_type" {
  type = string
  description = "General Purpose SSD Volume Type"
  default = "gp3"
}
variable "enable_instance_connect" {
  type = bool
  description = "Enable SSH connection over AWS web console"
  default = false
}
variable "allow_upload_download" {
  type = bool
  description = "Automatically download Blade Contracts and other important data. Improve product experience by sending data to Check Point"
  default = true
}
variable "management_server" {
  type = string
  description = "The name that represents the Security Management Server in the automatic provisioning configuration."
  default = "gwlb-management-server"
}
variable "configuration_template" {
  type = string
  description = "A name of a gateway configuration template in the automatic provisioning configuration."
  default = "gwlb-ASG-configuration"
}
variable "admin_shell" {
  type = string
  description = "Set the admin shell to enable advanced command line configuration"
  default = "/etc/cli.sh"
}

// --- Gateway Load Balancer Configuration ---

variable "gateway_load_balancer_name" {
  type = string
  description =  "Gateway Load Balancer name. This name must be unique within your AWS account and can have a maximum of 32 alphanumeric characters and hyphens. A name cannot begin or end with a hyphen."
  default = "gwlb1"
}
resource "null_resource" "gateway_load_balancer_name_too_long" {
  // Will fail if gateway_load_balancer_name more than 32
  count = length(var.gateway_load_balancer_name) <= 32 ? 0 : "variable gateway_load_balancer_name must be at most 32"
}
variable "target_group_name" {
  type = string
  description =  "Target Group Name. This name must be unique within your AWS account and can have a maximum of 32 alphanumeric characters and hyphens. A name cannot begin or end with a hyphen."
  default = "tg1"
}
resource "null_resource" "target_group_name_too_long" {
  // Will fail if target_group_name more than 32
  count = length(var.target_group_name) <= 32 ? 0 : "variable target_group_name must be at most 32"
}
variable "enable_cross_zone_load_balancing" {
  type = bool
  description =  "Select 'true' to enable cross-az load balancing. NOTE! this may cause a spike in cross-az charges."
  default = true
}

// --- Check Point CloudGuard IaaS Security Gateways Auto Scaling Group Configuration ---

variable "gateway_name" {
  type = string
  description = "The name tag of the Security Gateway instances. (optional)"
  default = "Check-Point-Gateway-tf"
}
variable "gateway_instance_type" {
  type = string
  description = "The EC2 instance type for the Security Gateways."
  default = "c5.xlarge"
}
module "validate_instance_type" {
  source = "./modules/common/instance_type"

  chkp_type = "gateway"
  instance_type = var.gateway_instance_type
}
variable "minimum_group_size" {
  type = number
  description = "The minimal number of Security Gateways."
  default = 2
}
variable "maximum_group_size" {
  type = number
  description = "The maximal number of Security Gateways."
  default = 10
}
variable "gateway_version" {
  type = string
  description =  "The version and license to install on the Security Gateways."
  default = "R80.40-BYOL"
}
module "validate_gateway_version" {
  source = "./modules/common/version_license"

  chkp_type = "gwlb_gw"
  version_license = var.gateway_version
}
variable "gateway_password_hash" {
  type = string
  description = "(Optional) Admin user's password hash (use command 'openssl passwd -6 PASSWORD' to get the PASSWORD's hash)"
}
variable "gateway_SICKey" {
  type = string
  description = "The Secure Internal Communication key for trusted connection between Check Point components (at least 8 alphanumeric characters)"
}

variable "gateways_provision_address_type" {
  type = string
  description = "Determines if the gateways are provisioned using their private or public address"
  default = "private"
}
variable "enable_cloudwatch" {
  type = bool
  description = "Report Check Point specific CloudWatch metrics."
  default = false
}

// --- Check Point CloudGuard IaaS Security Management Server Configuration ---

variable "management_deploy" {
  type = bool
  description = "Select 'false' to use an existing Security Management Server or to deploy one later and to ignore the other parameters of this section"
  default = true
}
variable "management_instance_type" {
  type = string
  description = "The EC2 instance type of the Security Management Server"
  default = "m5.xlarge"
}
module "validate_management_instance_type" {
  source = "./modules/common/instance_type"

  chkp_type = "management"
  instance_type = var.management_instance_type
}
variable "management_version" {
  type = string
  description =  "The license to install on the Security Management Server"
  default = "R81.10-BYOL"
}
module "validate_management_version" {
  source = "./modules/common/version_license"

  chkp_type = "management"
  version_license = var.management_version
}
variable "management_password_hash" {
  type = string
  description = "(Optional) Admin user's password hash (use command 'openssl passwd -6 PASSWORD' to get the PASSWORD's hash)"
  default = ""
}
variable "gateways_policy" {
  type = string
  description = "The name of the Security Policy package to be installed on the gateways in the Security Gateways Auto Scaling group"
  default = "Standard"
}
variable "gateway_management" {
  type = string
  description = "Select 'Over the internet' if any of the gateways you wish to manage are not directly accessed via their private IP address."
  default = "Locally managed"
}
variable "admin_cidr" {
  type = string
  description = "Allow web, ssh, and graphical clients only from this network to communicate with the Security Management Server"
}
variable "gateways_addresses" {
  type = string
  description = "Allow gateways only from this network to communicate with the Security Management Server"
}

# Validation of variables input

locals {
  regex_valid_vpc_cidr = "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\\/(1[6-9]|2[0-8]))$"
  // Will fail if var.vpc_cidr is invalid
  regex_vpc_cidr = regex(local.regex_valid_vpc_cidr, var.vpc_cidr) == var.vpc_cidr ? 0 : "Variable [vpc_cidr] must be a valid vpc cidr"

  regex_valid_gateway_sic_key = "^[a-zA-Z0-9]{8,}$"
  // Will fail if var.gateway_SIC_Key is invalid
  regex_gateway_sic_result = regex(local.regex_valid_gateway_sic_key, var.gateway_SICKey) == var.gateway_SICKey ? 0 : "Variable [gateway_SIC_Key] must be at least 8 alphanumeric characters"

  control_over_public_or_private_allowed_values = [
    "public",
    "private"]
  // will fail if [var.control_gateway_over_public_or_private_address] is invalid:
  validate_control_over_public_or_private = index(local.control_over_public_or_private_allowed_values, var.gateways_provision_address_type)

  gateway_management_allowed_values = [
    "Locally managed",
    "Over the internet"]
  // will fail if [var.gateway_management] is invalid:
  validate_gateway_management = index(local.gateway_management_allowed_values, var.gateway_management)

  regex_valid_management_password_hash = "^[\\$\\./a-zA-Z0-9]*$"
  // Will fail if var.management_password_hash is invalid
  regex_management_password_hash = regex(local.regex_valid_management_password_hash, var.management_password_hash) == var.management_password_hash ? 0 : "Variable [management_password_hash] must be a valid password hash"

  regex_valid_gateway_password_hash = "^[\\$\\./a-zA-Z0-9]*$"
  // Will fail if var.gateway_password_hash is invalid
  regex_gateway_password_hash = regex(local.regex_valid_gateway_password_hash, var.gateway_password_hash) == var.gateway_password_hash ? 0 : "Variable [gateway_password_hash] must be a valid password hash"


  regex_valid_admin_cidr = "^([0-9]{1,3}\\.){3}[0-9]{1,3}/([0-9]|[1-2][0-9]|3[0-2])$"
  // Will fail if var.admin_cidr is invalid
  regex_admin_cidr = regex(local.regex_valid_admin_cidr, var.admin_cidr) == var.admin_cidr ? 0 : "Variable [admin_cidr] must be a valid CIDR"

  regex_valid_gateways_addresses = "^([0-9]{1,3}\\.){3}[0-9]{1,3}/([0-9]|[1-2][0-9]|3[0-2])$"
  // Will fail if var.gateways_addresses is invalid
  regex_gateways_addresses = regex(local.regex_valid_gateways_addresses, var.gateways_addresses) == var.gateways_addresses ? 0 : "Variable [gateways_addresses] must be a valid gateways addresses"

  regex_valid_management_server = "^([A-Za-z]([-0-9A-Za-z]{0,61}[0-9A-Za-z])?|)$"
  // Will fail if var.management_server is invalid
  regex_management_server = regex(local.regex_valid_management_server, var.management_server) == var.management_server ? 0 : "Variable [management_server] can not be an empty string"

  regex_valid_configuration_template = "^([A-Za-z]([-0-9A-Za-z]{0,61}[0-9A-Za-z])?|)$"
  // Will fail if var.configuration_template is invalid
  regex_configuration_template = regex(local.regex_valid_configuration_template, var.configuration_template) == var.configuration_template ? 0 : "Variable [configuration_template] can not be an empty string"

  deploy_management_condition = var.management_deploy == true

  volume_type_allowed_values = [
    "gp3",
    "gp2"]
  // will fail if [var.volume_type] is invalid:
  validate_volume_type = index(local.volume_type_allowed_values, var.volume_type)


  #note: we need to add validiation for every subnet in masters solution
}