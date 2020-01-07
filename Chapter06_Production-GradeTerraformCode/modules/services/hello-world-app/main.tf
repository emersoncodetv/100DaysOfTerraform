provider "aws" {
  region = "us-east-2"

}

module "asg" {
  source = "../../cluster/asg-rolling-deploy"

  cluster_name  = "hello-world-${var.environment}"
  ami           = var.ami
  user_data     = data.template_file.user_data.rendered
  instance_type = var.instance_type

  min_size           = var.min_size
  max_size           = var.max_size
  enable_autoscaling = var.enable_autoscaling

  subnet_ids        = data.aws_subnet_ids.default.ids
  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  custom_tags = var.custom_tags
}


module "alb" {
  source = "../../networking/alb"

  alb_name   = "hello-world-${var.environment}"
  subnet_ids = data.aws_subnet_ids.default.ids
}
# data "template_file" "user_data" {
#   // este funciona cuand no estoy usando modulos
#   # template = file("user-data.sh")
#   // probando file function con modulos
#   // este es la solucion, hay que averiguar que es path.modules de donde carga y que atributos tiene.
#   // https://github.com/hashicorp/terraform/issues/5213#issuecomment-186213954
#   template = file("${path.module}/user-data.sh")

#   vars = {
#     server_port = var.server_port
#     db_address  = data.terraform_remote_state.db.outputs.address
#     db_port     = data.terraform_remote_state.db.outputs.port
#   }
# }


# data "template_file" "user_data" {
#   count = var.enable_new_user_data ? 0 : 1

#   template = file("${path.module}/user-data.sh")

#   vars = {
#     server_port = var.server_port
#     db_address  = data.terraform_remote_state.db.outputs.address
#     db_port     = data.terraform_remote_state.db.outputs.port
#   }
# }

# data "template_file" "user_data_new" {
data "template_file" "user_data" {
  # count = var.enable_new_user_data ? 1 : 0

  template = file("${path.module}/user-data-new.sh")

  vars = {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
    server_text = var.server_text
  }
}


# terraform {
#   backend "s3" {
#     # Replace this with your bucket name!
#     bucket = "terraform-up-and-running-state-serendipiaco"
#     key    = "stage/services/webserver-cluster/terraform.tfstate"
#     region = "us-east-2"

#     # Replace this with your DynamoDB table name!
#     dynamodb_table = "terraform-up-and-running-locks"
#     encrypt        = true
#   }
# }

/*
Creación de una instancia en AWS.
User Data es usado para enviar un conjunto de comandos que serán ejecutados en el primer boot de la maquina. 
User Data Detalles: https://bloggingnectar.com/aws/automate-your-ec2-instance-setup-with-ec2-user-data-scripts/
*/
# resource "aws_instance" "example" {
#   ami                    = "ami-0c55b159cbfafe1f0"
#   vpc_security_group_ids = [aws_security_group.instance.id]
#   instance_type          = "t2.micro"

#   // El <<-EOF y EOF son Terraform heredoc syntax, permiten ingresar bloques de codigo sin necesidad de usar caracteres para romper e ir a la nueva linea.
#   # user_data = <<-EOF
#   #             #!/bin/bash
#   #             echo "Hello, World" > index.html
#   #             nohup busybox httpd -f -p ${var.server_port} &
#   #             EOF
#   # user_data = <<EOF
#   #       #!/bin/bash
#   #       echo "Hello, World" >> index.html
#   #       echo "${data.terraform_remote_state.db.outputs.address}" >> index.html
#   #       echo "${data.terraform_remote_state.db.outputs.port}" >> index.html
#   #       nohup busybox httpd -f -p ${var.server_port} &
#   #       EOF
#   user_data = data.template_file.user_data.rendered

#   tags = {
#     Name = "terraform-example"
#   }
# }







# resource "aws_security_group" "alb" {
#   name = "${var.cluster_name}-alb"

#   # Allow inbound HTTP requests
#   ingress {
#     from_port   = local.http_port
#     to_port     = local.http_port
#     protocol    = local.tcp_protocol
#     cidr_blocks = local.all_ips
#   }

#   # Allow all outbound requests
#   egress {
#     from_port   = local.any_port
#     to_port     = local.any_port
#     protocol    = local.any_protocol
#     cidr_blocks = local.all_ips
#   }
# }



// Este es el recurso que me hizo doler la cabeza en cloud formation, aqui es mas sencillo de compprender y crear.
resource "aws_lb_target_group" "asg" {
  # name     = "terraform-asg-example"
  name     = "hello-world-${var.environment}"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  # listener_arn = aws_lb_listener.http.arn
  listener_arn = module.alb.alb_http_listener_arn
  priority     = 100

  /*   
    Warning: "condition.0.values": [DEPRECATED] use 'host_header' or 'path_pattern'
   condition {
    field  = "path-pattern"
    values = ["*"]
  } */

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}


