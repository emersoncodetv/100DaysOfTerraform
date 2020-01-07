variable "cluster_name" {
  description = "The name to use for all the cluster resources"
  type        = string
}

variable "ami" {
  description = "The AMI to run in the cluster"
  default     = "ami-0c55b159cbfafe1f0"
  type        = string
}

variable "instance_type" {
  description = "The type of EC2 Instances to run (e.g. t2.micro)"
  type        = string
}

variable "min_size" {
  description = "The minimum number of EC2 Instances in the ASG"
  type        = number
}

variable "max_size" {
  description = "The maximum number of EC2 Instances in the ASG"
  type        = number
}

variable "enable_autoscaling" {
  description = "If set to true, enable auto scaling"
  type        = bool
}

# PARA SER USADO EN EL FOR EACH
variable "custom_tags" {
  description = "Custom tags to set on the Instances in the ASG"
  type        = map(string)
  default     = {}
}

variable "server_port" {
  description = "Puerto para la lista de seguridad y el purto por el cual va a estar escuchando el servidor web."
  type        = number
  default     = 8080
}

################################################################

#   vpc_zone_identifier  = data.aws_subnet_ids.default.ids
// Se usa de esta forma dado que la salida de las subnets son 6, las 3 adicionales son de andres cuando esta trabajando con functions de AWS. 
variable "subnet_ids" {
  description = "The subnet IDs to deploy to"
  type        = list(string)
  default = ["subnet-21d30b48",
    "subnet-6b050921",
  "subnet-804da3fb", ]
}

variable "target_group_arns" {
  description = "The ARNs of ELB target groups in which to register Instances"
  type        = list(string)
  default     = []
}

variable "health_check_type" {
  description = "The type of health check to perform. Must be one of: EC2, ELB."
  type        = string
  default     = "EC2"
}

variable "user_data" {
  description = "The User Data script to run in each Instance at boot"
  type        = string
  default     = null
}

# The first variable, subnet_ids, directs the asg-rolling-deploy module to the subnets to deploy into. Whereas the webserver-cluster module was hardcoded to deploy into the Default VPC and subnets, by exposing the subnet_ids variable, you allow this module to be used with any VPC or subnets. The next two variables, target_group_arns and health_check_type, configure how the ASG integrates with load balancers. Whereas the webserver-cluster module had a built-in ALB, the asg-rolling-deploy module is meant to be a generic module, so exposing the load-balancer settings as input variables allows you to use the ASG with a wide variety of use cases; e.g., no load balancer, one ALB, multiple NLBs, and so on.

################################################################

locals {
  http_port    = 80
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}
