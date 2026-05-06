# CloudGuard GWLB Centralized Security VPC on AWS

Terraform project that deploys a **centralized inspection architecture** on AWS using Check Point CloudGuard with Gateway Load Balancer (GWLB) and Transit Gateway (TGW).

All east-west and outbound traffic from spoke VPCs is steered through a security VPC where an auto-scaling group of CloudGuard gateways performs deep packet inspection via the AWS GWLB service.

## Architecture Overview

![Architectural Design](/zimages/gwlb-centralized-design.jpg)

The design follows [Check Point's Architecture N°2 — Security VPC + TGW](https://supportcenter.checkpoint.com/supportcenter/portal?eventSubmit_doGoviewsolutiondetails=&solutionid=sk174447&partition=Basic&product=CloudGuard#Security%20VPC%20+%20TGW) pattern.

### Traffic Flows

| Flow | Path |
|------|------|
| **Outbound** | Spoke VM → TGW → Security VPC (TGW Attachment Subnet → GWLBe → GWLB/CloudGuard → NAT GW) → Internet |
| **East-West** | Spoke A VM → TGW → Security VPC (GWLBe → GWLB/CloudGuard → GWLBe) → TGW → Spoke B VM |
| **Shared Services** | Spoke VM → TGW → Shared Services VPC → VPC Endpoint (private) |

## Components Deployed

### Security VPC (`checkpoint-main.tf`)
- VPC with public, TGW attachment, NAT gateway, and GWLBe subnets (up to 4 AZs)
- **Gateway Load Balancer** with target group and cross-zone load balancing
- **CloudGuard Auto Scaling Group** attached to the GWLB
- **CloudGuard Security Management Server** (optional, controlled by `management_deploy`)
- TGW attachment with appliance mode enabled
- TGW route table with routes to spoke VPC CIDRs
- RFC 1918 routes on TGW attachment, GWLBe, and NAT subnet route tables

### Spoke VPCs (`environment-main.tf`)
- Configurable number of spoke VPCs via `spoke-env` map (default: `spoke-dev` and `spoke-prod`)
- Each spoke has TGW, untrust, and trust subnets with Internet Gateway
- Linux test EC2 instances (latest Amazon Linux 2023 AMI via data source lookup)
- Security groups: RFC 1918-only inbound, SSH restricted to `my-pub-ip`
- TGW attachments with dedicated spoke route table (default route → Security VPC)

### Shared Services VPC (`shared-svc-main.tf`)
- VPC with TGW and trust subnets across 2 AZs
- TGW attachment for connectivity to spoke and security VPCs
- **VPC Interface Endpoints**: RDS, RDS Data, EC2, CloudFormation, ECR API
- **Private Route53 zone** (`<region>.vpce.amazonaws.com`) with alias records for each endpoint

### Transit Gateway (`environment-main.tf`)
- Central TGW connecting all VPCs
- Separate route tables for spoke and security VPC attachments
- Spoke route table: default route → Security VPC attachment
- Security route table: spoke CIDRs → respective spoke attachments

## Prerequisites

- Terraform >= 1.1.9
- AWS Provider >= 5.36
- An EC2 Key Pair in the target region
- Check Point CloudGuard BYOL subscription (AMI access)

## Public Modules Used

| Module | Version | Purpose |
|--------|---------|---------|
| [`CheckPointSW/cloudguard-network-security/aws//modules/vpc`](https://registry.terraform.io/modules/CheckPointSW/cloudguard-network-security/aws/latest/submodules/vpc) | 1.0.10 | Security VPC |
| [`CheckPointSW/cloudguard-network-security/aws//modules/tgw_gwlb`](https://registry.terraform.io/modules/CheckPointSW/cloudguard-network-security/aws/latest/submodules/tgw_gwlb) | 1.0.10 | GWLB + ASG + Management |

## Quick Start

1. Clone this repository
2. Copy and edit `terraform.tfvars` — replace all `<placeholder>` values:

```hcl
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
availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
number_of_AZs      = 3

// --- Check Point Settings ---
key_name               = "<ec2-keypair-name>"
management_server      = "<chkp-management-name>"
configuration_template = "<chkp-cme-template-name>"
gateway_password_hash  = "<openssl-created-pwd-hash>"  // openssl passwd -6 "password"
gateway_SICKey         = "<chkp-sic-phrase>"
management_password_hash = "<openssl-created-pwd-hash>"
```

3. Initialize and apply:

```bash
terraform init
terraform plan
terraform apply
```

> **Tip:** When using Terraform Cloud, credentials (`aws-access-key`, `aws-secret-key`) can be managed as workspace variables instead of in `terraform.tfvars`.

## Project Structure

```
├── checkpoint-main.tf           # Security VPC, GWLB module, TGW attachment, route lookups
├── checkpoint-variables.tf      # All Check Point / Security VPC variables with validations
├── environment-main.tf          # Spoke VPCs, subnets, SGs, test VMs, TGW, Route53 associations
├── environment-variables.tf     # Spoke environment variables (spoke-env map, TGW name, etc.)
├── shared-svc-main.tf           # Shared Services VPC, VPC endpoints, Route53 private zone
├── shared-svc-variables.tf      # Shared services variables
├── providers.tf                 # Provider configuration (AWS >= 5.36)
├── terraform.tfvars             # User-provided values (edit before applying)
└── zimages/                     # Architecture diagrams
```

## Customization

- **Add/remove spoke VPCs**: Edit the `spoke-env` map in `environment-variables.tf`
- **Add/remove VPC endpoints**: Edit `shared-svc-main.tf` and add corresponding Route53 records
- **Scale AZs (2–4)**: Adjust `number_of_AZs`, `availability_zones`, subnet maps, and NAT/GWLBe CIDRs
- **Bring your own management**: Set `management_deploy = false` and configure `management_server` to point to your existing SMS

## References

- [Check Point GWLB for TGW — Documentation (sk174447)](https://supportcenter.checkpoint.com/supportcenter/portal?eventSubmit_doGoviewsolutiondetails=&solutionid=sk174447&partition=Basic&product=CloudGuard#Security%20VPC%20+%20TGW)
- [Check Point GWLB Admin Guide](https://sc1.checkpoint.com/documents/IaaS/WebAdminGuides/EN/CP_CloudGuard_Network_for_AWS_Gateway_Load_Balancer_Security_VPC_for_Transit_Gateway/Content/Topics-AWS-GWLB-VPC-TGW-DG/Introduction.htm)
- [Terraform Registry — CheckPointSW/cloudguard-network-security](https://registry.terraform.io/modules/CheckPointSW/cloudguard-network-security/aws/latest)
