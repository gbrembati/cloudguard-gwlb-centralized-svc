variable "vpc-shared-name" {
  type = string
  default = "shared-svc"
}

variable shared-svc {
    description = "[VPC name,VPC Cidr,TGW Subnet 1,TGW Subnet 2,Trusted Subnet 1,Trusted Subnet 2]"
    default = ["shared-svc","10.10.0.0/22","10.10.0.0/24","10.10.1.0/24","10.10.2.0/24","10.10.3.0/24"]
}