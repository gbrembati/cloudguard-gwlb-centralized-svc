variable env-resource-group {
    description = "Check Point Project Resource Group"
    type = string
    default = "rg-ckp-environment"
}
variable spoke-env {
    default = {
        0 = ["spoke-dev","10.10.0.0/22","10.10.0.0/24","10.10.1.0/24","10.10.2.0/24"]
        1 = ["spoke-prod","10.20.0.0/22","10.20.0.0/24","10.20.1.0/24","10.20.2.0/24"]
      # 2 = ["spoke-name","vpc-net/cidr","net-tgw/cidr","net-untrust/cidr","net-trust/cidr"]
    }
}
variable linux-keypair {
    description = "The EC2 Key-Pair to use"
    type = string
    default = "key-gb-2022-ireland"
}
variable "tgw-name" {
    description = "Name of the TGW"
    type = string
    default = "tgw-central"
}
variable "my-pub-ip" {
    type = string
    sensitive = true
}
