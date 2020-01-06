locals {
  http_port    = 80
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}

variable "server_port" {
  description = "Puerto para la lista de seguridad y el purto por el cual va a estar escuchando el servidor web."
  type        = number
  default     = 8080
}

// Para encontrar el ID de la VPC que esta por default.
data "aws_vpc" "default" {
  default = true
}

// Una ves que encontramos el ID de la VPC podemos buscar los id de las subnet de dicha VPC.
data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

variable "cluster_name" {
  description = "The name to use for all the cluster resources"
  type        = string
}

variable "db_remote_state_bucket" {
  description = "The name of the S3 bucket for the database's remote state"
  type        = string
}

variable "db_remote_state_key" {
  description = "The path for the database's remote state in S3"
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
