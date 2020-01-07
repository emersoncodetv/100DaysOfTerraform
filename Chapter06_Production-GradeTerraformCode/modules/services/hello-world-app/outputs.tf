# output "alb_dns_name" {
#   value       = aws_lb.example.dns_name
#   description = "The domain name of the load balancer"
# }

# output "public_ip" {
#   value       = aws_instance.example.public_ip
#   description = "The public IP address of the web server"
# }

output "subnets" {
  value       = data.aws_subnet_ids.default.ids
  description = "subnets"
}

# output "asg_name" {
#   value       = aws_autoscaling_group.example.name
#   description = "The name of the Auto Scaling Group"
# }

# output "alb_dns_name" {
#   value       = aws_lb.example.dns_name
#   description = "The domain name of the load balancer"
# }

output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "The ID of the Security Group attached to the load balancer"
}

output "alb_dns_name" {
  value       = module.alb.alb_dns_name
  description = "The domain name of the load balancer"
}

output "asg_name" {
  value       = module.asg.asg_name
  description = "The name of the Auto Scaling Group"
}

output "instance_security_group_id" {
  value       = module.asg.instance_security_group_id
  description = "The ID of the EC2 Instance Security Group"
}
