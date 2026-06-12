NATRT1=$(aws ec2 describe-route-tables \
  --filters "Name=tag:Name,Values=NAT Subnet 1 Route Table" \
  --query 'RouteTables[0].RouteTableId' \
  --output text)
TGWRT1=$(aws ec2 describe-route-tables \
  --filters "Name=tag:Name,Values=TGW Attachment Subnet 1 Route Table" \
  --query 'RouteTables[0].RouteTableId' \
  --output text)
EP1=$(aws ec2 describe-vpc-endpoints \
  --filters "Name=tag:Name,Values=cfwaas-gwlbe-1" \
  --query 'VpcEndpoints[0].VpcEndpointId' \
  --output text)

aws ec2 replace-route --route-table-id "$NATRT1" --destination-cidr-block 10.0.0.0/8 --vpc-endpoint-id "$EP1"
aws ec2 replace-route --route-table-id "$NATRT1" --destination-cidr-block 172.16.0.0/12 --vpc-endpoint-id "$EP1"
aws ec2 replace-route --route-table-id "$NATRT1" --destination-cidr-block 192.168.0.0/16 --vpc-endpoint-id "$EP1"
aws ec2 replace-route --route-table-id "$TGWRT1" --destination-cidr-block 0.0.0.0/0 --vpc-endpoint-id "$EP1"

NATRT2=$(aws ec2 describe-route-tables \
  --filters "Name=tag:Name,Values=NAT Subnet 2 Route Table" \
  --query 'RouteTables[0].RouteTableId' \
  --output text)
TGWRT2=$(aws ec2 describe-route-tables \
  --filters "Name=tag:Name,Values=TGW Attachment Subnet 2 Route Table" \
  --query 'RouteTables[0].RouteTableId' \
  --output text)
EP2=$(aws ec2 describe-vpc-endpoints \
  --filters "Name=tag:Name,Values=cfwaas-gwlbe-2" \
  --query 'VpcEndpoints[0].VpcEndpointId' \
  --output text)

aws ec2 replace-route --route-table-id "$NATRT2" --destination-cidr-block 10.0.0.0/8 --vpc-endpoint-id "$EP2"
aws ec2 replace-route --route-table-id "$NATRT2" --destination-cidr-block 172.16.0.0/12 --vpc-endpoint-id "$EP2"
aws ec2 replace-route --route-table-id "$NATRT2" --destination-cidr-block 192.168.0.0/16 --vpc-endpoint-id "$EP2"
aws ec2 replace-route --route-table-id "$TGWRT2" --destination-cidr-block 0.0.0.0/0 --vpc-endpoint-id "$EP2"

NATRT3=$(aws ec2 describe-route-tables \
  --filters "Name=tag:Name,Values=NAT Subnet 3 Route Table" \
  --query 'RouteTables[0].RouteTableId' \
  --output text)
TGWRT3=$(aws ec2 describe-route-tables \
  --filters "Name=tag:Name,Values=TGW Attachment Subnet 3 Route Table" \
  --query 'RouteTables[0].RouteTableId' \
  --output text)
EP3=$(aws ec2 describe-vpc-endpoints \
  --filters "Name=tag:Name,Values=cfwaas-gwlbe-3" \
  --query 'VpcEndpoints[0].VpcEndpointId' \
  --output text)

aws ec2 replace-route --route-table-id "$NATRT3" --destination-cidr-block 10.0.0.0/8 --vpc-endpoint-id "$EP3"
aws ec2 replace-route --route-table-id "$NATRT3" --destination-cidr-block 172.16.0.0/12 --vpc-endpoint-id "$EP3"
aws ec2 replace-route --route-table-id "$NATRT3" --destination-cidr-block 192.168.0.0/16 --vpc-endpoint-id "$EP3"
aws ec2 replace-route --route-table-id "$TGWRT3" --destination-cidr-block 0.0.0.0/0 --vpc-endpoint-id "$EP3"
