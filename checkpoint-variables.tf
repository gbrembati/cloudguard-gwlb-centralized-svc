// Module: Check Point CloudGuard Network Gateway Load Balancer into an existing VPC

// --- AWS Provider ---
variable "region" {
  type        = string
  description = "AWS region"
  default     = ""
}
variable "access_key" {
  type        = string
  description = "AWS access key"
  default     = ""
}
variable "secret_key" {
  type        = string
  description = "AWS secret key"
  default     = ""
}

// ---VPC Network Configuration ---
variable "number_of_AZs" {
  type        = number
  description = "Number of Availability Zones to use in the VPC. This must match your selections in the list of Availability Zones parameter"
  default     = 2
}
variable "availability_zones" {
  type        = list(string)
  description = "The Availability Zones (AZs) to use for the subnets in the VPC. Select two (the logical order is preserved)"
}
variable "vpc_cidr" {
  type        = string
  description = "The CIDR block of the VPC"
  default     = "10.0.0.0/16"

  validation {
    condition     = can(regex("^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\\/(1[6-9]|2[0-8]))$", var.vpc_cidr))
    error_message = "Variable [vpc_cidr] must be a valid VPC CIDR."
  }
}
variable "public_subnets_map" {
  type        = map(string)
  description = "A map of pairs {availability-zone = subnet-suffix-number}. Each entry creates a subnet. Minimum 2 pairs.  (e.g. {\"us-east-1a\" = 1} ) "
}
variable "subnets_bit_length" {
  type        = number
  description = "Number of additional bits with which to extend the vpc cidr. For example, if given a vpc_cidr ending in /16 and a subnets_bit_length value of 4, the resulting subnet address will have length /20"
}
variable "tgw_subnets_map" {
  type        = map(string)
  description = "A map of pairs {availability-zone = subnet-suffix-number} for the tgw subnets. Each entry creates a subnet. Minimum 2 pairs.  (e.g. {\"us-east-1a\" = 1} ) "
}
variable "nat_gw_subnet_1_cidr" {
  type        = string
  description = "CIDR block for NAT subnet 1 located in the 1st Availability Zone"
  default     = "10.0.13.0/24"
}
variable "nat_gw_subnet_2_cidr" {
  type        = string
  description = "CIDR block for NAT subnet 2 located in the 2st Availability Zone"
  default     = "10.0.23.0/24"
}
variable "nat_gw_subnet_3_cidr" {
  type        = string
  description = "CIDR block for NAT subnet 3 located in the 3st Availability Zone"
  default     = "10.0.33.0/24"
}
variable "nat_gw_subnet_4_cidr" {
  type        = string
  description = "CIDR block for NAT subnet 4 located in the 4st Availability Zone"
  default     = "10.0.43.0/24"
}
variable "gwlbe_subnet_1_cidr" {
  type        = string
  description = "CIDR block for Gateway Loadbalancer endpoint subnet 1 located in the 1st Availability Zone"
  default     = "10.0.14.0/24"
}
variable "gwlbe_subnet_2_cidr" {
  type        = string
  description = "CIDR block for Gateway Loadbalancer endpoint subnet 2 located in the 2st Availability Zone"
  default     = "10.0.24.0/24"
}
variable "gwlbe_subnet_3_cidr" {
  type        = string
  description = "CIDR block for Gateway Loadbalancer endpoint subnet 3 located in the 3st Availability Zone"
  default     = "10.0.34.0/24"
}
variable "gwlbe_subnet_4_cidr" {
  type        = string
  description = "CIDR block for Gateway Loadbalancer endpoint subnet 4 located in the 4st Availability Zone"
  default     = "10.0.44.0/24"
}
// --- General Settings ---
variable "key_name" {
  type        = string
  description = "The EC2 Key Pair name to allow SSH access to the instances"
}
variable "enable_volume_encryption" {
  type        = bool
  description = "Encrypt Environment instances volume with default AWS KMS key"
  default     = true
}
variable "volume_size" {
  type        = number
  description = "Root volume size (GB) - minimum 100"
  default     = 100

  validation {
    condition     = var.volume_size >= 100
    error_message = "Variable [volume_size] must be at least 100."
  }
}
variable "volume_type" {
  type        = string
  description = "General Purpose SSD Volume Type"
  default     = "gp3"

  validation {
    condition     = contains(["gp3", "gp2"], var.volume_type)
    error_message = "Variable [volume_type] must be one of: gp3, gp2."
  }
}
variable "enable_instance_connect" {
  type        = bool
  description = "Enable SSH connection over AWS web console"
  default     = false
}
variable "allow_upload_download" {
  type        = bool
  description = "Automatically download Blade Contracts and other important data. Improve product experience by sending data to Check Point"
  default     = true
}
variable "management_server" {
  type        = string
  description = "The name that represents the Security Management Server in the automatic provisioning configuration."
  default     = "gwlb-management-server"

  validation {
    condition     = can(regex("^([A-Za-z]([-0-9A-Za-z]{0,61}[0-9A-Za-z])?|)$", var.management_server))
    error_message = "Variable [management_server] must be a valid hostname or empty string."
  }
}
variable "configuration_template" {
  type        = string
  description = "A name of a gateway configuration template in the automatic provisioning configuration."
  default     = "gwlb-ASG-configuration"

  validation {
    condition     = can(regex("^([A-Za-z]([-0-9A-Za-z]{0,61}[0-9A-Za-z])?|)$", var.configuration_template))
    error_message = "Variable [configuration_template] must be a valid configuration template name or empty string."
  }
}
variable "admin_shell" {
  type        = string
  description = "Set the admin shell to enable advanced command line configuration"
  default     = "/etc/cli.sh"
}

// --- Gateway Load Balancer Configuration ---

variable "gateway_load_balancer_name" {
  type        = string
  description = "Gateway Load Balancer name. This name must be unique within your AWS account and can have a maximum of 32 alphanumeric characters and hyphens. A name cannot begin or end with a hyphen."
  default     = "gwlb1"

  validation {
    condition     = length(var.gateway_load_balancer_name) <= 32
    error_message = "Variable [gateway_load_balancer_name] must be at most 32 characters."
  }
}
variable "target_group_name" {
  type        = string
  description = "Target Group Name. This name must be unique within your AWS account and can have a maximum of 32 alphanumeric characters and hyphens. A name cannot begin or end with a hyphen."
  default     = "tg1"

  validation {
    condition     = length(var.target_group_name) <= 32
    error_message = "Variable [target_group_name] must be at most 32 characters."
  }
}
variable "enable_cross_zone_load_balancing" {
  type        = bool
  description = "Select 'true' to enable cross-az load balancing. NOTE! this may cause a spike in cross-az charges."
  default     = true
}

// --- Check Point CloudGuard IaaS Security Gateways Auto Scaling Group Configuration ---

variable "gateway_name" {
  type        = string
  description = "The name tag of the Security Gateway instances. (optional)"
  default     = "Check-Point-Gateway-tf"
}
variable "gateway_instance_type" {
  type        = string
  description = "The EC2 instance type for the Security Gateways."
  default     = "c5.xlarge"
}
variable "minimum_group_size" {
  type        = number
  description = "The minimal number of Security Gateways."
  default     = 2
}
variable "maximum_group_size" {
  type        = number
  description = "The maximal number of Security Gateways."
  default     = 10
}
variable "gateway_version" {
  type        = string
  description = "The version and license to install on the Security Gateways."
  default     = "R80.40-BYOL"
}
variable "gateway_password_hash" {
  type        = string
  description = "(Optional) Admin user's password hash (use command 'openssl passwd -6 PASSWORD' to get the PASSWORD's hash)"
  sensitive   = true

  validation {
    condition     = can(regex("^[\\$\\./a-zA-Z0-9]*$", var.gateway_password_hash))
    error_message = "Variable [gateway_password_hash] must be a valid password hash."
  }
}
variable "gateway_SICKey" {
  type        = string
  description = "The Secure Internal Communication key for trusted connection between Check Point components (at least 8 alphanumeric characters)"
  sensitive   = true

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{8,}$", var.gateway_SICKey))
    error_message = "Variable [gateway_SICKey] must be at least 8 alphanumeric characters."
  }
}

variable "gateways_provision_address_type" {
  type        = string
  description = "Determines if the gateways are provisioned using their private or public address"
  default     = "private"

  validation {
    condition     = contains(["public", "private"], var.gateways_provision_address_type)
    error_message = "Variable [gateways_provision_address_type] must be one of: public, private."
  }
}
variable "allocate_public_IP" {
  type        = bool
  description = "Allocate a Public IP for gateway members"
  default     = false
}
variable "enable_cloudwatch" {
  type        = bool
  description = "Report Check Point specific CloudWatch metrics."
  default     = false
}
variable "gateway_bootstrap_script" {
  type        = string
  description = "(Optional) An optional script with semicolon separated commands to run on the initial boot"
  default     = ""
}
variable "gateway_maintenance_mode_password_hash" {
  type        = string
  description = "(Optional) Admin user's maintenance-mode password hash for gateway recovery purposes"
  default     = ""
  sensitive   = true
}
variable "disable_instance_termination" {
  type        = bool
  description = "Prevents an instance from accidental termination"
  default     = false
}

// --- Check Point CloudGuard IaaS Security Management Server Configuration ---

variable "management_deploy" {
  type        = bool
  description = "Select 'false' to use an existing Security Management Server or to deploy one later and to ignore the other parameters of this section"
  default     = true
}
variable "management_instance_type" {
  type        = string
  description = "The EC2 instance type of the Security Management Server"
  default     = "m5.xlarge"
}
variable "management_version" {
  type        = string
  description = "The license to install on the Security Management Server"
  default     = "R81.10-BYOL"
}
variable "management_password_hash" {
  type        = string
  description = "(Optional) Admin user's password hash (use command 'openssl passwd -6 PASSWORD' to get the PASSWORD's hash)"
  default     = ""
  sensitive   = true

  validation {
    condition     = can(regex("^[\\$\\./a-zA-Z0-9]*$", var.management_password_hash))
    error_message = "Variable [management_password_hash] must be a valid password hash."
  }
}
variable "management_maintenance_mode_password_hash" {
  type        = string
  description = "(Optional) Admin user's maintenance-mode password hash for management recovery purposes"
  default     = ""
  sensitive   = true
}
variable "gateways_policy" {
  type        = string
  description = "The name of the Security Policy package to be installed on the gateways in the Security Gateways Auto Scaling group"
  default     = "Standard"
}
variable "gateway_management" {
  type        = string
  description = "Select 'Over the internet' if any of the gateways you wish to manage are not directly accessed via their private IP address."
  default     = "Locally managed"

  validation {
    condition     = contains(["Locally managed", "Over the internet"], var.gateway_management)
    error_message = "Variable [gateway_management] must be one of: 'Locally managed', 'Over the internet'."
  }
}
variable "admin_cidr" {
  type        = string
  description = "Allow web, ssh, and graphical clients only from this network to communicate with the Security Management Server"

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/([0-9]|[1-2][0-9]|3[0-2])$", var.admin_cidr))
    error_message = "Variable [admin_cidr] must be a valid CIDR."
  }
}
variable "gateways_addresses" {
  type        = string
  description = "Allow gateways only from this network to communicate with the Security Management Server"

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/([0-9]|[1-2][0-9]|3[0-2])$", var.gateways_addresses))
    error_message = "Variable [gateways_addresses] must be a valid CIDR."
  }
}
