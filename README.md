# CloudGuard GWLB Deployment on AWS
This Terraform project is intended to be used as a template in a demonstration or to build a test environment.  
What it does is creates an infrastructure composed of application VPCs, Shared Services VPC, Transit Gateway, and protect them with an auto-scaling group of CloudGuard gateways by using the newly AWS GWLB service.    
These applications will have then the East-West and Outgoing traffic protected by CloudGuard Instances.    

## Do you want to see more?    
The following diagram is based on the Architecture N°2 design of Check Point GWLB in AWS.    
Learn more at [CHKP/Documentation](https://supportcenter.checkpoint.com/supportcenter/portal?eventSubmit_doGoviewsolutiondetails=&solutionid=sk174447&partition=Basic&product=CloudGuard#Security%20VPC%20+%20TGW) & [CHKP/Admin Guide](https://sc1.checkpoint.com/documents/IaaS/WebAdminGuides/EN/CP_CloudGuard_Network_for_AWS_Gateway_Load_Balancer_Security_VPC_for_Transit_Gateway/Content/Topics-AWS-GWLB-VPC-TGW-DG/Introduction.htm)

## Which are the components created?
The project creates the following resources and combines them:
1. **Spokes VPCs**: Application VPCs with testing EC2s 
2. **Service VPC**: Single VPC dedicated to host VPC Endpoints
3. **Security VPC**: Single VPC dedicated to host the CloudGuard gateways ASG
4. **Transit Gateway**: Transit Gateway to connect the different VPCs
5. **Transit Gateway Config**: Transit gateway attachments, and routing configuration
6. **GWLB Service**: In the security VPC with its endpoint
7. **GWLB Auto-Scaling Group**: Attached to the GWLB service to provide security enforcement
8. **Private Route53 Zone**: Used to share VPC Endpoints hosted in the Service VPC
9. **VPC Endpoints and host registration**: Used to access EC2 / ECR / RDS / CloudFormation services privately

## How to use it
The only thing that you need to do is change **<values>** the __*terraform.tfvars*__ file located in this directory.

```hcl
// --- Provider Settings ---
region      = "<aws-region>" 
access_key  = "<aws-access-key>"
secret_key  = "<aws-secret-key>"

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
gateway_version       = "R81.20-BYOL"                   // "R80.40-BYOL" | "R81.20-BYOL"
gateway_password_hash = "<openssl-created-pwd-hash>"    // openssl passwd -6 "password"
gateway_SICKey        = "<chkp-sic-phrase>"             
enable_cloudwatch     = true
gateways_provision_address_type = "private"

// --- Check Point CloudGuard IaaS Security Management Server Configuration ---
management_deploy         = true
management_instance_type  = "m6i.xlarge"
management_version        = "R81.20-BYOL"                   // "R81.10-BYOL" | "R81.20-BYOL"         
management_password_hash  = "<openssl-created-pwd-hash>"    // openssl passwd -6 "password"
gateways_policy           = "Standard"
gateway_management        = "Locally managed"
admin_cidr                = "0.0.0.0/0"
gateways_addresses        = "0.0.0.0/0"
```
If you want (or need) to further customize other project details, you can change defaults in the different __*name-variables.tf*__ files.   
Here you will also be able to find the descriptions that explain what each variable is used for.

## The infrastructure was created with the following design:
![Architectural Design](/zimages/gwlb-centralized-design.jpg)
