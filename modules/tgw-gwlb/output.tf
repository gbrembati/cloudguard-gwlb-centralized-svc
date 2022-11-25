output "Deployment" {
  value = "Finalizing instances configuration may take up to 20 minutes after deployment is finished."
}
output "management_public_ip" {
  depends_on = [module.gwlb]
  value = module.gwlb[*].management_public_ip
}
output "gwlb_arn" {
  depends_on = [module.gwlb]
  value = module.gwlb[*].gwlb_arn
}
output "gwlb_service_name" {
  depends_on = [module.gwlb]
  value = module.gwlb[*].gwlb_service_name
}
output "gwlb_name" {
  value = var.gateway_load_balancer_name
}
output "controller_name" {
  value = "gwlb-controller"
}
output "template_name" {
  value = var.configuration_template
}

output "tgw_subnet1_rtb" {
  value = aws_route_table.tgw_attachment_subnet1_rtb.id
}
output "tgw_subnet2_rtb" {
  value = aws_route_table.tgw_attachment_subnet2_rtb.id
}
output "tgw_subnet3_rtb" {
  value = aws_route_table.tgw_attachment_subnet3_rtb[0].id
} 

output "gwlbe_subnet1_rtb" {
  value = aws_route_table.gwlbe_subnet1_rtb.id
}
output "gwlbe_subnet2_rtb" {
  value = aws_route_table.gwlbe_subnet2_rtb.id
}
output "gwlbe_subnet3_rtb" {
  value = aws_route_table.gwlbe_subnet3_rtb[0].id
} 
