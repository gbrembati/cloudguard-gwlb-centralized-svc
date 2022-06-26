
resource "aws_resourcegroups_group" "resource-group-svc" {
  name  = "rg-shared-svc"

  resource_query {
    query = <<JSON
    {
      "ResourceTypeFilters": [
        "AWS::AllSupported"
      ],
      "TagFilters": [
        {
          "Key": "Resource Group",
          "Values": ["rg-${var.shared-svc[0]}"]
        }
      ]
    }
    JSON
  }
}

# Create a VPC for our gateway
resource "aws_vpc" "vpc-shared-svc" {
  cidr_block  = var.shared-svc[1]

  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-${var.shared-svc[0]}"
    "Resource Group" = "rg-${var.shared-svc[0]}"
  }
}

resource "aws_route_table" "rt-main-vpc-shared-svc" {
  vpc_id  = aws_vpc.vpc-shared-svc.id

  tags = {
    Name = "rt-main-vpc-${var.shared-svc[0]}"
    "Resource Group" = "rg-${var.shared-svc[0]}"
  }
  depends_on = [aws_vpc.vpc-shared-svc]
}
resource "aws_main_route_table_association" "rt-to-vpc-shared-svc" {
  vpc_id         = aws_vpc.vpc-shared-svc.id
  route_table_id = aws_route_table.rt-main-vpc-shared-svc.id
  depends_on = [aws_route_table.rt-main-vpc-shared-svc]  
}

resource "aws_security_group" "svc-allow-all" {
  name        = "nsg-vpc-${var.shared-svc[0]}"
  description = "Allow inbound/outbound traffic"
  vpc_id      = aws_vpc.vpc-shared-svc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nsg-vpc-${var.shared-svc[0]}"
    "Resource Group" = "rg-${var.shared-svc[0]}"
  }
  depends_on = [aws_vpc.vpc-shared-svc]
}

resource "aws_subnet" "net-tgw-shared-svc-a" {
  vpc_id      = aws_vpc.vpc-shared-svc.id
  cidr_block  = var.shared-svc[2]
  availability_zone = "${var.region}a"

  tags = {
    Name = "net-${var.shared-svc[0]}-tgw-a"
    "Resource Group" = "rg-${var.shared-svc[0]}"
  }
  depends_on = [aws_vpc.vpc-shared-svc]
}
resource "aws_subnet" "net-tgw-shared-svc-b" {
  vpc_id      = aws_vpc.vpc-shared-svc.id
  cidr_block  = var.shared-svc[3]
  availability_zone = "${var.region}b"

  tags = {
    Name = "net-${var.shared-svc[0]}-tgw-b"
    "Resource Group" = "rg-${var.shared-svc[0]}"
  }
  depends_on = [aws_vpc.vpc-shared-svc]
}

resource "aws_subnet" "net-trust-shared-svc-a" {
  vpc_id      = aws_vpc.vpc-shared-svc.id
  cidr_block  = var.shared-svc[4]
  availability_zone = "${var.region}a"

  tags = {
    Name = "net-${var.shared-svc[0]}-trust-a"
    "Resource Group" = "rg-${var.shared-svc[0]}"
    x-chkp-gwlb-outbound = "0.0.0.0/0"
  }
  depends_on = [aws_vpc.vpc-shared-svc]
}
resource "aws_subnet" "net-trust-shared-svc-b" {
  vpc_id      = aws_vpc.vpc-shared-svc.id
  cidr_block  = var.shared-svc[5]
  availability_zone = "${var.region}b"

  tags = {
    Name = "net-${var.shared-svc[0]}-trust-b"
    "Resource Group" = "rg-${var.shared-svc[0]}"
    x-chkp-gwlb-outbound = "0.0.0.0/0"
  }
  depends_on = [aws_vpc.vpc-shared-svc]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "shared-svc-attachments" {
  subnet_ids         = [aws_subnet.net-tgw-shared-svc-a.id,aws_subnet.net-tgw-shared-svc-b.id]
  transit_gateway_id = aws_ec2_transit_gateway.tgw-central.id
  vpc_id             = aws_vpc.vpc-shared-svc.id
  transit_gateway_default_route_table_association = false
    
  tags = {
    Name = "tgw-attach-${var.shared-svc[0]}"
    "Resource Group" = "rg-${var.shared-svc[0]}"
  }
  depends_on = [aws_ec2_transit_gateway.tgw-central,aws_subnet.net-tgw-shared-svc-a,aws_subnet.net-tgw-shared-svc-b]
}

resource "aws_route_table" "rt-net-to-internal-scope" {
  vpc_id  = aws_vpc.vpc-shared-svc.id

  route {
    cidr_block = "0.0.0.0/0"
    transit_gateway_id = aws_ec2_transit_gateway.tgw-central.id
  }
  tags = {
    Name = "rt-net-${var.shared-svc[0]}-tgw"
    "Resource Group" = "rg-${var.shared-svc[0]}"
  }
  depends_on = [aws_vpc.vpc-spoke,aws_ec2_transit_gateway_vpc_attachment.shared-svc-attachments]
}

resource "aws_route_table_association" "rt-for-tgw-shared-svc-a" {
  subnet_id      = aws_subnet.net-tgw-shared-svc-a.id
  route_table_id = aws_route_table.rt-net-to-internal-scope.id
} 
resource "aws_route_table_association" "rt-for-tgw-shared-svc-b" {
  subnet_id      = aws_subnet.net-tgw-shared-svc-b.id
  route_table_id = aws_route_table.rt-net-to-internal-scope.id
} 
resource "aws_route_table_association" "rt-for-trust-shared-svc-a" {
  subnet_id      = aws_subnet.net-trust-shared-svc-a.id
  route_table_id = aws_route_table.rt-net-to-internal-scope.id
} 
resource "aws_route_table_association" "rt-for-trust-shared-svc-b" {
  subnet_id      = aws_subnet.net-trust-shared-svc-b.id
  route_table_id = aws_route_table.rt-net-to-internal-scope.id
} 

resource "aws_vpc_endpoint" "shared-svc-vpce-s3" {
  vpc_id            = aws_vpc.vpc-shared-svc.id
  service_name      = "com.amazonaws.eu-west-1.s3"
  vpc_endpoint_type = "Interface"
  
  private_dns_enabled = false
  security_group_ids = [ aws_security_group.svc-allow-all.id ]
  subnet_ids = [ aws_subnet.net-trust-shared-svc-a.id, aws_subnet.net-trust-shared-svc-b.id]

  tags = {
    Name = "vpce-${var.shared-svc[0]}-s3"
    "Resource Group" = "rg-${var.shared-svc[0]}"
  }
}

resource "aws_vpc_endpoint" "shared-svc-vpce-ec2" {
  vpc_id            = aws_vpc.vpc-shared-svc.id
  service_name      = "com.amazonaws.eu-west-1.ec2"
  vpc_endpoint_type = "Interface"
  
  private_dns_enabled = false
  security_group_ids = [ aws_security_group.svc-allow-all.id ]
  subnet_ids = [ aws_subnet.net-trust-shared-svc-a.id, aws_subnet.net-trust-shared-svc-b.id]

  tags = {
    Name = "vpce-${var.shared-svc[0]}-ec2"
    "Resource Group" = "rg-${var.shared-svc[0]}"
  }
}

resource "aws_vpc_endpoint" "shared-svc-vpce-ecr-api" {
  vpc_id            = aws_vpc.vpc-shared-svc.id
  service_name      = "com.amazonaws.eu-west-1.ecr.api"
  vpc_endpoint_type = "Interface"
  
  private_dns_enabled = false
  security_group_ids = [ aws_security_group.svc-allow-all.id ]
  subnet_ids = [ aws_subnet.net-trust-shared-svc-a.id, aws_subnet.net-trust-shared-svc-b.id]

  tags = {
    Name = "vpce-${var.shared-svc[0]}-ecr"
    "Resource Group" = "rg-${var.shared-svc[0]}"
  }
}

resource "aws_route53_zone" "private-ireland-zone" {
  name = "eu-west-1.vpce.amazonaws.com"
  
  vpc {
    vpc_id = aws_vpc.vpc-shared-svc.id
  }
}

resource "aws_route53_record" "host-s3-endpoint" {
  zone_id = aws_route53_zone.private-ireland-zone.zone_id
  name    = "s3.${aws_route53_zone.private-ireland-zone.name}"
  type    = "A"

  alias {
    name    = aws_vpc_endpoint.shared-svc-vpce-s3.dns_entry[0].dns_name
    zone_id = aws_vpc_endpoint.shared-svc-vpce-s3.dns_entry[0].hosted_zone_id
    evaluate_target_health = true
  }
} 

resource "aws_route53_record" "host-ec2-endpoint" {
  zone_id = aws_route53_zone.private-ireland-zone.zone_id
  name    = "ec2.${aws_route53_zone.private-ireland-zone.name}"
  type    = "A"

  alias {
    name    = aws_vpc_endpoint.shared-svc-vpce-ec2.dns_entry[0].dns_name
    zone_id = aws_vpc_endpoint.shared-svc-vpce-ec2.dns_entry[0].hosted_zone_id
    evaluate_target_health = true
  }
} 

resource "aws_route53_record" "host-ecr-api-endpoint" {
  zone_id = aws_route53_zone.private-ireland-zone.zone_id
  name    = "ecr.${aws_route53_zone.private-ireland-zone.name}"
  type    = "A"

  alias {
    name    = aws_vpc_endpoint.shared-svc-vpce-ecr-api.dns_entry[0].dns_name
    zone_id = aws_vpc_endpoint.shared-svc-vpce-ecr-api.dns_entry[0].hosted_zone_id
    evaluate_target_health = true
  }
} 