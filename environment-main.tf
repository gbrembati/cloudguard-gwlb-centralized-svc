
resource "aws_resourcegroups_group" "resource-group-spoke" {
  count = length(var.spoke-env)
  name  = "rg-${lookup(var.spoke-env,count.index)[0]}"

  resource_query {
    query = <<JSON
    {
      "ResourceTypeFilters": [
        "AWS::AllSupported"
      ],
      "TagFilters": [
        {
          "Key": "Resource Group",
          "Values": ["rg-${lookup(var.spoke-env,count.index)[0]}"]
        }
      ]
    }
    JSON
  }
}

# Create a VPC for our gateway
resource "aws_vpc" "vpc-spoke" {
  count       = length(var.spoke-env)
  cidr_block  = lookup(var.spoke-env,count.index)[1]

  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-${lookup(var.spoke-env,count.index)[0]}"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
  }
}

resource "aws_route_table" "rt-main-vpc-spoke" {
  count   = length(var.spoke-env)
  vpc_id  = aws_vpc.vpc-spoke[count.index].id

  tags = {
    Name = "rt-main-vpc-${lookup(var.spoke-env,count.index)[0]}"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
  }
  depends_on = [aws_vpc.vpc-spoke]
}
resource "aws_main_route_table_association" "rt-to-vpc-spoke" {
  count          = length(var.spoke-env)
  vpc_id         = aws_vpc.vpc-spoke[count.index].id
  route_table_id = aws_route_table.rt-main-vpc-spoke[count.index].id
  depends_on = [aws_route_table.rt-main-vpc-spoke]  
}

resource "aws_security_group" "nsg-allow-all" {
  count       = length(var.spoke-env)
  name        = "nsg-vpc-${lookup(var.spoke-env,count.index)[0]}"
  description = "Allow inbound/outbound traffic"
  vpc_id      = aws_vpc.vpc-spoke[count.index].id

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
    Name = "nsg-vpc-${lookup(var.spoke-env,count.index)[0]}"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
  }
  depends_on = [aws_vpc.vpc-spoke]
}

# Create the Spoke Subnets
resource "aws_subnet" "net-tgw-spoke" {
  count       = length(var.spoke-env)
  vpc_id      = aws_vpc.vpc-spoke[count.index].id
  cidr_block  = lookup(var.spoke-env,count.index)[2]
  availability_zone = "${var.region}a"

  tags = {
    Name = "net-${lookup(var.spoke-env,count.index)[0]}-tgw"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
  }
  depends_on = [aws_vpc.vpc-spoke]
}
resource "aws_subnet" "net-untrust-spoke" {
  count       = length(var.spoke-env)
  vpc_id      = aws_vpc.vpc-spoke[count.index].id
  cidr_block  = lookup(var.spoke-env,count.index)[3]
  availability_zone = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "net-${lookup(var.spoke-env,count.index)[0]}-untrust"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
    x-chkp-gwlb-outbound = "0.0.0.0/0"
    x-chkp-gwlb-inbound = lookup(var.spoke-env,count.index)[3]
  }
  depends_on = [aws_vpc.vpc-spoke]
}
resource "aws_subnet" "net-trust-spoke" {
  count       = length(var.spoke-env)
  vpc_id      = aws_vpc.vpc-spoke[count.index].id
  cidr_block  = lookup(var.spoke-env,count.index)[4]
  availability_zone = "${var.region}a"

  tags = {
    Name = "net-${lookup(var.spoke-env,count.index)[0]}-trust"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
    x-chkp-gwlb-outbound = "0.0.0.0/0"
  }
  depends_on = [aws_vpc.vpc-spoke]
}

# The IGWs for the Spokes VPC and makes all the route-table w/ association
resource "aws_internet_gateway" "vpc-spoke-igw" {
  count   = length(var.spoke-env)
  vpc_id  = aws_vpc.vpc-spoke[count.index].id
  tags = {
    Name = "igw-vpc-${lookup(var.spoke-env,count.index)[0]}"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
  }
  depends_on = [aws_vpc.vpc-spoke]
}
resource "aws_route_table" "rt-spoke-igw" {
  count   = length(var.spoke-env)
  vpc_id  = aws_vpc.vpc-spoke[count.index].id

  tags = {
    Name = "rt-igw-vpc-${lookup(var.spoke-env,count.index)[0]}"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
  }
  depends_on = [aws_vpc.vpc-spoke,aws_internet_gateway.vpc-spoke-igw]
}
resource "aws_route_table_association" "rt-to-igw-spoke" {
  count          = length(var.spoke-env)
  gateway_id     = aws_internet_gateway.vpc-spoke-igw[count.index].id
  route_table_id = aws_route_table.rt-spoke-igw[count.index].id
  depends_on = [aws_internet_gateway.vpc-spoke-igw,aws_route_table.rt-spoke-igw]  
}

resource "aws_route_table" "rt-net-tgw-spoke" {
  count   = length(var.spoke-env)
  vpc_id  = aws_vpc.vpc-spoke[count.index].id

  route {
    cidr_block = "0.0.0.0/0"
    transit_gateway_id = aws_ec2_transit_gateway.tgw-central.id
  }
  tags = {
    Name = "rt-net-${lookup(var.spoke-env,count.index)[0]}-tgw"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
  }
  depends_on = [aws_vpc.vpc-spoke,aws_internet_gateway.vpc-spoke-igw,aws_ec2_transit_gateway_vpc_attachment.tgw-spoke-attachments]
}
resource "aws_route_table_association" "rt-to-tgw-spoke" {
  count          = length(var.spoke-env)
  subnet_id      = aws_subnet.net-tgw-spoke[count.index].id
  route_table_id = aws_route_table.rt-net-tgw-spoke[count.index].id
  depends_on = [aws_subnet.net-tgw-spoke,aws_route_table.rt-net-tgw-spoke]  
}

resource "aws_route_table" "rt-net-untrust-spoke" {
  count   = length(var.spoke-env)
  vpc_id  = aws_vpc.vpc-spoke[count.index].id

  route {
    cidr_block = var.my-pub-ip
    gateway_id = aws_internet_gateway.vpc-spoke-igw[count.index].id
  }
  route {
    cidr_block = "0.0.0.0/0"
    transit_gateway_id = aws_ec2_transit_gateway.tgw-central.id
  }
  tags = {
    Name = "rt-net-${lookup(var.spoke-env,count.index)[0]}-untrust"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
  }
  depends_on = [aws_vpc.vpc-spoke,aws_internet_gateway.vpc-spoke-igw]
}
resource "aws_route_table_association" "rt-to-untrust-spoke" {
  count          = length(var.spoke-env)
  subnet_id      = aws_subnet.net-untrust-spoke[count.index].id
  route_table_id = aws_route_table.rt-net-untrust-spoke[count.index].id
  depends_on = [aws_subnet.net-untrust-spoke,aws_route_table.rt-net-untrust-spoke]  
}

resource "aws_route_table" "rt-net-trust-spoke" {
  count   = length(var.spoke-env)
  vpc_id  = aws_vpc.vpc-spoke[count.index].id

  route {
    cidr_block = var.my-pub-ip
    gateway_id = aws_internet_gateway.vpc-spoke-igw[count.index].id
  }
  route {
    cidr_block = "0.0.0.0/0"
    transit_gateway_id = aws_ec2_transit_gateway.tgw-central.id
  }
  tags = {
    Name = "rt-net-${lookup(var.spoke-env,count.index)[0]}-trust"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
  }
  depends_on = [aws_vpc.vpc-spoke,aws_internet_gateway.vpc-spoke-igw]
}
resource "aws_route_table_association" "rt-to-trust-spoke" {
  count          = length(var.spoke-env)
  subnet_id      = aws_subnet.net-trust-spoke[count.index].id
  route_table_id = aws_route_table.rt-net-trust-spoke[count.index].id
  depends_on = [aws_subnet.net-trust-spoke,aws_route_table.rt-net-trust-spoke]  
}

# Deploy linux test VMs
resource "aws_security_group" "nsg-allow-http" {
  count       = length(var.spoke-env)
  name        = "nsg-allow-http-${lookup(var.spoke-env,count.index)[0]}"
  description = "Allow http inbound traffic"
  vpc_id      = aws_vpc.vpc-spoke[count.index].id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nsg-allow-http-${lookup(var.spoke-env,count.index)[0]}"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
  }
  depends_on = [aws_vpc.vpc-spoke]
}
resource "aws_security_group" "nsg-allow-ssh" {
  count       = length(var.spoke-env)
  name        = "nsg-allow-ssh-${lookup(var.spoke-env,count.index)[0]}"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.vpc-spoke[count.index].id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "nsg-allow-ssh-${lookup(var.spoke-env,count.index)[0]}"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
  }
  depends_on = [aws_vpc.vpc-spoke]
}

resource "aws_network_interface" "nic-vm-spoke-linux" {
  count           = length(var.spoke-env)
  subnet_id       = aws_subnet.net-untrust-spoke[count.index].id
  security_groups = [aws_security_group.nsg-allow-http[count.index].id,aws_security_group.nsg-allow-ssh[count.index].id]

  tags = {
    Name = "nic-vm-linux-${lookup(var.spoke-env,count.index)[0]}"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
  }
  depends_on = [aws_subnet.net-untrust-spoke,aws_security_group.nsg-allow-http,aws_security_group.nsg-allow-ssh]
}

resource "aws_instance" "vm-spoke-linux" {
  count         = length(var.spoke-env)
  ami           = "ami-0d71ea30463e0ff8d"
  instance_type = "t2.micro"
  key_name      = var.linux-keypair

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.nic-vm-spoke-linux[count.index].id
  }

  tags = {
    Name = "vm-linux-${lookup(var.spoke-env,count.index)[0]}"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
  }
  depends_on = [aws_network_interface.nic-vm-spoke-linux]
}

# Creation of the TGW and the attachments
resource "aws_ec2_transit_gateway" "tgw-central" {
  description = var.tgw-name
  tags = {
    Name = var.tgw-name
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw-spoke-attachments" {
  count              = length(var.spoke-env)
  subnet_ids         = [aws_subnet.net-tgw-spoke[count.index].id]
  transit_gateway_id = aws_ec2_transit_gateway.tgw-central.id
  vpc_id             = aws_vpc.vpc-spoke[count.index].id
  transit_gateway_default_route_table_association = false
    
  tags = {
    Name = "tgw-attach-${lookup(var.spoke-env,count.index)[0]}"
    "Resource Group" = "rg-${lookup(var.spoke-env,count.index)[0]}"
  }
  depends_on = [aws_ec2_transit_gateway.tgw-central,aws_subnet.net-tgw-spoke]
}

resource "aws_ec2_transit_gateway_route_table" "tgw-rt-spoke" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw-central.id

  tags = {
    Name = "tgw-rtb-spoke"
  }
  depends_on = [aws_ec2_transit_gateway.tgw-central]  
}

resource "aws_ec2_transit_gateway_route_table_association" "tgw-rt-spoke-assoc" {
  count              = length(var.spoke-env)
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt-spoke.id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-spoke-attachments[count.index].id
  depends_on = [aws_ec2_transit_gateway.tgw-central,aws_ec2_transit_gateway_vpc_attachment.tgw-spoke-attachments]
}

resource "aws_ec2_transit_gateway_route" "rt-to-security-vpc" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw-security-attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt-spoke.id
}

resource "aws_route53_zone_association" "phz-svc-vpc-join" {
  count   = length(var.spoke-env)
  zone_id = aws_route53_zone.private-ireland-zone.zone_id
  vpc_id  = aws_vpc.vpc-spoke[count.index].id
} 