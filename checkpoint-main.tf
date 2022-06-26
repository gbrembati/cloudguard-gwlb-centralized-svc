module "launch_vpc" {
  source = "./modules/vpc"

  vpc_cidr            = var.vpc_cidr
  public_subnets_map  = var.public_subnets_map
  private_subnets_map = {}
  tgw_subnets_map     = var.tgw_subnets_map
  subnets_bit_length  = var.subnets_bit_length
}

resource "aws_ec2_transit_gateway_route_table" "tgw-rt-security" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw-central.id

  tags = {
    Name = "tgw-rtb-security"
  }
  depends_on = [aws_ec2_transit_gateway.tgw-central]  
}

resource "aws_ec2_transit_gateway_route" "rt-security-to-vpcs" {
  count = length(var.spoke-env)
  destination_cidr_block         = lookup(var.spoke-env,count.index)[1]
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-spoke-attachments[count.index].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt-security.id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw-security-attachment" {
  subnet_ids         = [element(module.launch_vpc.tgw_subnets_ids_list, 0),element(module.launch_vpc.tgw_subnets_ids_list, 1),element(module.launch_vpc.tgw_subnets_ids_list, 2)]
  transit_gateway_id = aws_ec2_transit_gateway.tgw-central.id
  vpc_id             = module.launch_vpc.vpc_id

  appliance_mode_support = "enable"  
  transit_gateway_default_route_table_association = false

  tags = {
    Name = "tgw-attach-vpc-security"
  }
  depends_on = [aws_ec2_transit_gateway.tgw-central,module.launch_vpc]
}

resource "aws_ec2_transit_gateway_route_table_association" "tgw-rt-security-assoc" {
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt-security.id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-security-attachment.id
  depends_on = [aws_ec2_transit_gateway.tgw-central,aws_ec2_transit_gateway_vpc_attachment.tgw-security-attachment]
}

module "tgw-gwlb"{
  source = "./modules/tgw-gwlb"
  providers = {
    aws = aws
  }

  vpc_id              = module.launch_vpc.vpc_id
  gateways_subnets    = module.launch_vpc.public_subnets_ids_list
  number_of_AZs       = var.number_of_AZs
  availability_zones  = var.availability_zones
  internet_gateway_id = module.launch_vpc.aws_igw

  transit_gateway_attachment_subnet_1_id =  element(module.launch_vpc.tgw_subnets_ids_list, 0)
  transit_gateway_attachment_subnet_2_id =  element(module.launch_vpc.tgw_subnets_ids_list, 1)
  transit_gateway_attachment_subnet_3_id = var.number_of_AZs >= 3 ? element(module.launch_vpc.tgw_subnets_ids_list, 2) : ""
  transit_gateway_attachment_subnet_4_id = var.number_of_AZs >= 4 ? element(module.launch_vpc.tgw_subnets_ids_list, 3) : ""

  nat_gw_subnet_1_cidr  = var.nat_gw_subnet_1_cidr
  nat_gw_subnet_2_cidr  = var.nat_gw_subnet_2_cidr
  nat_gw_subnet_3_cidr  = var.nat_gw_subnet_3_cidr
  nat_gw_subnet_4_cidr  = var.nat_gw_subnet_4_cidr

  gwlbe_subnet_1_cidr   = var.gwlbe_subnet_1_cidr
  gwlbe_subnet_2_cidr   = var.gwlbe_subnet_2_cidr
  gwlbe_subnet_3_cidr   = var.gwlbe_subnet_3_cidr
  gwlbe_subnet_4_cidr   = var.gwlbe_subnet_4_cidr

  // --- General Settings ---
  key_name                  = var.key_name
  enable_volume_encryption  = var.enable_volume_encryption
  volume_size               = var.volume_size
  enable_instance_connect   = var.enable_instance_connect
  allow_upload_download     = var.allow_upload_download
  management_server         = var.management_server
  configuration_template    = var.configuration_template
  admin_shell               = var.admin_shell

  // --- Gateway Load Balancer Configuration ---
  gateway_load_balancer_name        = var.gateway_load_balancer_name
  target_group_name                 = var.target_group_name
  enable_cross_zone_load_balancing  = var.enable_cross_zone_load_balancing

  // --- Check Point CloudGuard IaaS Security Gateways Auto Scaling Group Configuration ---
  gateway_name          = var.gateway_name
  gateway_instance_type = var.gateway_instance_type
  minimum_group_size    = var.minimum_group_size
  maximum_group_size    = var.maximum_group_size
  gateway_version       = var.gateway_version
  gateway_password_hash = var.gateway_password_hash
  gateway_SICKey        = var.gateway_SICKey
  enable_cloudwatch     = var.enable_cloudwatch
  gateways_provision_address_type = var.gateways_provision_address_type

  // --- Check Point CloudGuard IaaS Security Management Server Configuration ---
  management_deploy         = var.management_deploy
  management_instance_type  = var.management_instance_type
  management_version        = var.management_version
  management_password_hash  = var.management_password_hash
  gateways_policy           = var.gateways_policy
  gateway_management        = var.gateway_management
  admin_cidr                = var.admin_cidr
  gateways_addresses        = var.gateways_addresses

  volume_type = var.volume_type
}

resource "aws_route" "tgw_attachment1_rtb_classA" {
  route_table_id          = module.tgw-gwlb.tgw_subnet1_rtb
  destination_cidr_block  = "10.0.0.0/8"
  transit_gateway_id      = aws_ec2_transit_gateway.tgw-central.id
}
resource "aws_route" "tgw_attachment1_rtb_classB" {
  route_table_id          = module.tgw-gwlb.tgw_subnet1_rtb
  destination_cidr_block  = "172.16.0.0/12"
  transit_gateway_id      = aws_ec2_transit_gateway.tgw-central.id
}
resource "aws_route" "tgw_attachment1_rtb_classC" {
  route_table_id          = module.tgw-gwlb.tgw_subnet1_rtb
  destination_cidr_block  = "192.168.0.0/16"
  transit_gateway_id      = aws_ec2_transit_gateway.tgw-central.id
}

resource "aws_route" "tgw_attachment2_rtb_classA" {
  route_table_id          = module.tgw-gwlb.tgw_subnet2_rtb
  destination_cidr_block  = "10.0.0.0/8"
  transit_gateway_id      = aws_ec2_transit_gateway.tgw-central.id
}
resource "aws_route" "tgw_attachment2_rtb_classB" {
  route_table_id          = module.tgw-gwlb.tgw_subnet2_rtb
  destination_cidr_block  = "172.16.0.0/12"
  transit_gateway_id      = aws_ec2_transit_gateway.tgw-central.id
}
resource "aws_route" "tgw_attachment2_rtb_classC" {
  route_table_id          = module.tgw-gwlb.tgw_subnet2_rtb
  destination_cidr_block  = "192.168.0.0/16"
  transit_gateway_id      = aws_ec2_transit_gateway.tgw-central.id
}

resource "aws_route" "tgw_attachment3_rtb_classA" {
  route_table_id          = module.tgw-gwlb.tgw_subnet3_rtb
  destination_cidr_block  = "10.0.0.0/8"
  transit_gateway_id      = aws_ec2_transit_gateway.tgw-central.id
}
resource "aws_route" "tgw_attachment3_rtb_classB" {
  route_table_id          = module.tgw-gwlb.tgw_subnet3_rtb
  destination_cidr_block  = "172.16.0.0/12"
  transit_gateway_id      = aws_ec2_transit_gateway.tgw-central.id
}
resource "aws_route" "tgw_attachment3_rtb_classC" {
  route_table_id          = module.tgw-gwlb.tgw_subnet3_rtb
  destination_cidr_block  = "192.168.0.0/16"
  transit_gateway_id      = aws_ec2_transit_gateway.tgw-central.id
}
