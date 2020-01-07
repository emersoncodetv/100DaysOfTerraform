############################################################

variable "environment" {
  description = "The name of the environment we're deploying to"
  type        = string
}

// Para encontrar el ID de la VPC que esta por default.
data "aws_vpc" "default" {
  default = true
}

// Una ves que encontramos el ID de la VPC podemos buscar los id de las subnet de dicha VPC.
data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    # bucket = "terraform-up-and-running-state-serendipiaco"
    # key    = "stage/data-stores/mysql/terraform.tfstate"
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = "us-east-2"
  }
}

############################################################




# locals {
#   http_port    = 80
#   any_port     = 0
#   any_protocol = "-1"
#   tcp_protocol = "tcp"
#   all_ips      = ["0.0.0.0/0"]
# }


variable "server_text" {
  description = "The text the web server should return"
  default     = "Hello, World"
  type        = string
}

variable "enable_new_user_data" {
  description = "If set to true, use the new User Data script"
  type        = bool
}


variable "db_remote_state_bucket" {
  description = "The name of the S3 bucket for the database's remote state"
  type        = string
}

variable "db_remote_state_key" {
  description = "The path for the database's remote state in S3"
  type        = string
}




